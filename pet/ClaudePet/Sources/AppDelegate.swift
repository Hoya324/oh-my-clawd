import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem: NSStatusItem = {
        NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()

    // Animation state
    private var frameTimer: Timer?
    private var stateTimer: Timer?
    private var wakeUpTimer: Timer?
    private var motionTimer: Timer?
    private var randomMotionTimer: Timer?
    private var currentState: PetState = .idle
    private var currentActivity: ActivityLevel = .normal
    private var selection: AccessorySelection = .none
    private var isWakingUp = false
    private var frameIndex = 0
    private var currentFrames: [NSImage] = []
    private var motionFrames: [NSImage] = []
    private var motionFrameIndex = 0
    private var isPlayingMotion = false

    // Services
    private let stateReader = PetStateReader()
    private let progressTracker = ProgressTracker()
    private let selectionStore = SelectionStore()
    private let usageService = UsageService()
    private let chatMonitor = ChatActivityMonitor()
    private let runtimeInstaller = RuntimeInstaller()
    private var menuController: StatusMenuController!
    private let notificationManager = NotificationManager()
    private let clawdMemory = ClawdMemoryStore.shared
    private var lastPetData: PetStateData?
    private lazy var reminderScheduler = ReminderScheduler(
        memory: clawdMemory,
        notifications: notificationManager,
        isUserActive: { [weak self] in
            guard let self = self else { return false }
            return (self.lastPetData?.activeSessions ?? 0) > 0 || self.chatMonitor.isChatting
        }
    )

    // Change detection for reactions
    private var knownUnlocks: Set<String>?
    private var lastFiveHour: Double?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Paths.ensurePetDir()
        notificationManager.requestPermission()
        selection = selectionStore.read()

        menuController = StatusMenuController()
        _ = menuController.setupPopover()
        let vm = menuController.viewModel
        vm.notificationManager = notificationManager
        vm.onUsageDisplayModeChange = { [weak self] _ in self?.updateStatusTitle() }
        vm.onRefreshUsage = { [weak self] in self?.usageService.refresh(force: true) }
        notificationManager.onAuthStateChange = { [weak self] state in
            self?.menuController.viewModel.notifAuthState = state
        }
        notificationManager.refreshAuthState()

        setupStatusItem()

        usageService.onUpdate = { [weak self] snapshot, status in
            self?.handleUsage(snapshot, status: status)
        }
        usageService.start()

        chatMonitor.onChange = { [weak self] in self?.pollState() }
        chatMonitor.start()

        runtimeInstaller.ensureInstalled { [weak self] status in
            self?.menuController.viewModel.aggregatorStatus = status
        }

        startStatePolling()
        reminderScheduler.start()
        reloadFramesAndAnimate()
        scheduleRandomMotion()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.menuController.viewModel.checkForUpdates()
        }

        ClawdChat.warmUpConnection { [weak self] conn in
            guard let vm = self?.menuController.viewModel else { return }
            switch conn {
            case .cli(let path):
                vm.connectionLabel = "Claude Code 연결됨"
                vm.claudeCliPath = path
                vm.isConnected = true
            case .none:
                vm.connectionLabel = "Claude Code 없음"
                vm.isConnected = false
            }
        }

        NotificationCenter.default.addObserver(
            self, selector: #selector(onAccessoryChanged),
            name: .accessoryChanged, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleep),
            name: NSWorkspace.willSleepNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    // MARK: - Status item

    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        button.action = #selector(togglePopover)
        button.target = self
        button.imagePosition = .imageLeft
        statusItem.menu = nil
        updateStatusTitle()
    }

    private func updateStatusTitle() {
        guard let button = statusItem.button else { return }
        let mode = menuController?.viewModel.usageDisplayMode ?? UsageDisplayMode.load()
        if let title = StatusBarUsage.title(usageService.snapshot, mode: mode,
                                            stale: usageService.status == .stale) {
            button.attributedTitle = title
        } else {
            button.attributedTitle = NSAttributedString(string: "")
        }
        button.toolTip = StatusBarUsage.tooltip(usageService.snapshot, status: usageService.status)
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        playClickReaction()
        menuController.togglePopover(relativeTo: button)
    }

    // MARK: - Usage

    private func handleUsage(_ snapshot: UsageSnapshot?, status: UsageStatus) {
        menuController.viewModel.applyUsage(snapshot, status: status)
        chatMonitor.observe(usage: snapshot)
        if let snapshot = snapshot {
            notificationManager.checkAndNotify(rateLimit: snapshot.rateLimit)
            reactToUsage(snapshot)
        }
        updateStatusTitle()
        pollState()
    }

    /// Small reactions to usage changes: alarm when crossing 80%, a happy
    /// dance when a fresh 5-hour window starts after heavy use.
    private func reactToUsage(_ snapshot: UsageSnapshot) {
        guard let now = snapshot.fiveHourPercent else { return }
        defer { lastFiveHour = now }
        guard let prev = lastFiveHour else { return }
        if prev < 80 && now >= 80 {
            playMotion(.surprised)
        } else if prev >= 50 && now < 10 {
            playMotion(.celebrate)
        }
    }

    // MARK: - State polling

    private func startStatePolling() {
        stateTimer?.invalidate()
        stateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.pollState()
        }
    }

    private func pollState() {
        let data = stateReader.read()
        lastPetData = data
        let chatting = chatMonitor.isChatting

        let newState = PetState.resolve(data: data, usage: usageService.snapshot, chatting: chatting)
        let newActivity = PetState.resolveActivityLevel(from: data)
        let newSelection = selectionStore.read()

        checkForNewUnlocks()

        let oldState = currentState
        let needsReload = newActivity != currentActivity || newSelection != selection
        currentActivity = newActivity
        selection = newSelection

        if !isWakingUp && oldState == .idle && newState != .idle {
            // idle → active: play the wake-up animation first
            isWakingUp = true
            currentState = .wakeUp
            frameIndex = 0
            reloadFramesAndAnimate()

            wakeUpTimer?.invalidate()
            wakeUpTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.isWakingUp = false
                self.currentState = PetState.resolve(
                    data: self.stateReader.read(),
                    usage: self.usageService.snapshot,
                    chatting: self.chatMonitor.isChatting
                )
                self.frameIndex = 0
                self.reloadFramesAndAnimate()
            }
        } else if !isWakingUp {
            currentState = newState
            if newState != oldState || needsReload {
                frameIndex = 0
                reloadFramesAndAnimate()
            }
        }

        let vm = menuController.viewModel
        vm.chatSource = chatMonitor.source()
        vm.refresh(stateData: data, petState: isWakingUp ? newState : currentState)
    }

    private func checkForNewUnlocks() {
        guard let unlocked = progressTracker.read()?.unlockedAccessories else { return }
        let now = Set(unlocked)
        defer { knownUnlocks = now }
        guard let known = knownUnlocks else { return }   // first read: no fanfare
        let fresh = now.subtracting(known).compactMap(AccessoryType.init(rawValue:))
        guard let first = fresh.first else { return }
        playMotion(.celebrate)
        notificationManager.sendClawdMessage(
            key: "unlock:\(first.rawValue)",
            title: "새 액세서리를 얻었어요!",
            body: "\(first.displayNameKO)을(를) 입어볼 수 있어요 🎉"
        )
    }

    @objc private func onAccessoryChanged() {
        selection = selectionStore.read()
        if !isPlayingMotion { reloadFramesAndAnimate() }
    }

    // MARK: - Base animation

    private func overlays(state: PetState, frameIndex: Int) -> [[[UInt32?]]?] {
        // Glasses under pants under hat
        [selection.glasses, selection.pants, selection.hat].compactMap { $0 }.map {
            AccessorySprites.overlay(accessory: $0, state: state, frameIndex: frameIndex)
        }
    }

    private func reloadFramesAndAnimate() {
        guard !isPlayingMotion else { return }
        let count = PixelArtRenderer.frameCount(state: currentState)
        currentFrames = (0..<count).map { i in
            PixelArtRenderer.renderFrame(
                state: currentState,
                activity: currentActivity,
                hat: selection.hat,
                glasses: selection.glasses,
                pants: selection.pants,
                frameIndex: i
            )
        }
        if let first = currentFrames.first {
            statusItem.button?.image = first
        }

        frameTimer?.invalidate()
        let timer = Timer(timeInterval: currentState.frameInterval, target: self,
                          selector: #selector(nextFrame), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        frameTimer = timer
    }

    @objc private func nextFrame() {
        guard !currentFrames.isEmpty else { return }
        frameIndex = (frameIndex + 1) % currentFrames.count
        statusItem.button?.image = currentFrames[frameIndex]
    }

    // MARK: - Motions (click reactions, random idle motions, celebrations)

    private func playClickReaction() {
        // Half the time the classic hand-drawn reaction, otherwise a random
        // procedural one, so clicking Clawd stays surprising.
        if Bool.random() {
            playInteractionSprites()
        } else if let motion = IdleMotionType.clickReactions.randomElement() {
            playMotion(motion)
        }
    }

    private func playInteractionSprites() {
        let frames = InteractionSprites.frames().map { MotionFrame(body: $0) }
        startMotion(frames: frames, interval: InteractionSprites.frameInterval, overlayState: .normal)
    }

    func playMotion(_ motion: IdleMotionType) {
        guard !isWakingUp else { return }
        let base = ClaudeSprites.frames(state: currentState).first ?? ClaudeSprites.frames(state: .normal)[0]
        let frames = IdleMotionSprites.motionFrames(motion: motion, base: base)
        startMotion(frames: frames, interval: motion.frameInterval,
                    overlayState: motion.isHandDrawn ? .normal : currentState)
    }

    private func startMotion(frames: [MotionFrame], interval: TimeInterval, overlayState: PetState) {
        guard !frames.isEmpty else { return }
        let accessoryOverlays = overlays(state: overlayState, frameIndex: 0)
        let effect = ClaudeEffects.effectOverlay(activity: currentActivity, frameIndex: 0)
        motionFrames = frames.map {
            PixelArtRenderer.renderMotionFrame($0, overlays: accessoryOverlays, effect: effect)
        }
        motionFrameIndex = 0
        isPlayingMotion = true
        frameTimer?.invalidate()
        statusItem.button?.image = motionFrames[0]

        motionTimer?.invalidate()
        let timer = Timer(timeInterval: interval, target: self,
                          selector: #selector(nextMotionFrame), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        motionTimer = timer
    }

    @objc private func nextMotionFrame() {
        motionFrameIndex += 1
        guard motionFrameIndex < motionFrames.count else {
            motionTimer?.invalidate()
            motionTimer = nil
            isPlayingMotion = false
            reloadFramesAndAnimate()
            scheduleRandomMotion()
            return
        }
        statusItem.button?.image = motionFrames[motionFrameIndex]
    }

    private func scheduleRandomMotion() {
        randomMotionTimer?.invalidate()
        // Livelier while something is happening, calmer while asleep.
        let range: ClosedRange<TimeInterval> = currentState == .idle ? 90...240 : 35...110
        randomMotionTimer = Timer.scheduledTimer(withTimeInterval: .random(in: range), repeats: false) { [weak self] _ in
            self?.triggerRandomMotion()
        }
    }

    private func triggerRandomMotion() {
        guard !isPlayingMotion && !isWakingUp else {
            scheduleRandomMotion()
            return
        }
        let pool = IdleMotionType.allCases
            .filter { $0.allowedStates.contains(currentState) }
            .flatMap { Array(repeating: $0, count: $0.weight) }
        guard let motion = pool.randomElement() else {
            scheduleRandomMotion()
            return
        }
        playMotion(motion)
    }

    // MARK: - Sleep / Wake

    @objc private func onSleep() {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
        wakeUpTimer?.invalidate()
        motionTimer?.invalidate()
        randomMotionTimer?.invalidate()
        isPlayingMotion = false
        isWakingUp = false
        usageService.stop()
    }

    @objc private func onWake() {
        startStatePolling()
        usageService.start()
        reloadFramesAndAnimate()
        scheduleRandomMotion()
    }
}

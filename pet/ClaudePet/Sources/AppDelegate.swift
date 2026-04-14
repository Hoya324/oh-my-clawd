import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem: NSStatusItem = {
        NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()

    private var frameTimer: Timer?
    private var stateTimer: Timer?
    private var wakeUpTimer: Timer?
    private var currentState: PetState = .idle
    private var currentActivity: ActivityLevel = .normal
    private var currentHat: AccessoryType? = nil
    private var currentGlasses: AccessoryType? = nil
    private var currentPants: AccessoryType? = nil
    private var isWakingUp: Bool = false
    private var frameIndex = 0
    private var currentFrames: [NSImage] = []
    private var activeSessions: Int = 0
    private var stateReader = PetStateReader()
    private var progressTracker = ProgressTracker()
    private var menuController: StatusMenuController!
    private var notificationManager = NotificationManager()
    private let clawdMemory = ClawdMemoryStore()
    private lazy var reminderScheduler = ReminderScheduler(
        memory: clawdMemory,
        stateReader: stateReader,
        notifications: notificationManager
    )

    // Interaction animation state
    private var isPlayingInteraction: Bool = false
    private var interactionTimer: Timer?
    private var interactionFrameIndex: Int = 0
    private var interactionFrames: [NSImage] = []

    // Idle motion state
    private var isPlayingIdleMotion: Bool = false
    private var idleMotionTimer: Timer?
    private var idleMotionFrameIndex: Int = 0
    private var idleMotionFrames: [NSImage] = []
    private var idleMotionFrameInterval: TimeInterval = 0.2
    private var randomIdleTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        notificationManager.requestPermission()

        // Load selected hat and glasses from progress
        currentHat = progressTracker.selectedHat()
        currentGlasses = progressTracker.selectedGlasses()
        currentPants = progressTracker.selectedPants()

        menuController = StatusMenuController()
        let _ = menuController.setupPopover()
        menuController.viewModel.notificationManager = notificationManager
        notificationManager.onAuthStateChange = { [weak self] state in
            self?.menuController.viewModel.notifAuthState = state
        }
        notificationManager.refreshAuthState()

        setupStatusItem()
        startStatePolling()
        reminderScheduler.start()
        reloadFramesAndAnimate()
        scheduleRandomIdleMotion()

        // Warm up Clawd's connection (API token first, CLI fallback) so the
        // first user message is instant and the UI shows live state.
        // Check for updates shortly after launch so the popover opens with
        // a concrete state (최신 / 설치 버튼) instead of the Check button.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.menuController.viewModel.checkForUpdates()
        }

        ClawdChat.warmUpConnection { [weak self] conn in
            guard let vm = self?.menuController.viewModel else { return }
            switch conn {
            case .api:
                vm.connectionLabel = "API 연결됨"
                vm.isConnected = true
            case .cli(let path):
                vm.connectionLabel = "CLI 연결됨"
                vm.claudeCliPath = path
                vm.isConnected = true
            case .none:
                vm.connectionLabel = "연결 없음"
                vm.isConnected = false
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onSleep),
            name: NSWorkspace.willSleepNotification, object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self, selector: #selector(onWake),
            name: NSWorkspace.didWakeNotification, object: nil
        )
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            // Remove menu so click triggers action instead
            statusItem.menu = nil
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        playInteraction()
        menuController.togglePopover(relativeTo: button)
    }

    private func startStatePolling() {
        stateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.pollState()
        }
    }

    private func pollState() {
        let data = stateReader.read()

        let newState: PetState
        let newActivity: ActivityLevel
        if let data = data {
            newState = PetState.resolve(from: data)
            newActivity = PetState.resolveActivityLevel(from: data)
            notificationManager.checkAndNotify(rateLimit: data.rateLimit)
        } else {
            newState = .idle
            newActivity = .normal
        }

        let newSessions = data?.activeSessions ?? 0

        // Load current hat, glasses, and pants selections
        let newHat = progressTracker.selectedHat()
        let newGlasses = progressTracker.selectedGlasses()
        let newPants = progressTracker.selectedPants()

        // Capture old values for change detection before updating
        let oldState = currentState
        let oldActivity = currentActivity
        let oldHat = currentHat
        let oldGlasses = currentGlasses
        let oldPants = currentPants

        currentActivity = newActivity
        currentHat = newHat
        currentGlasses = newGlasses
        currentPants = newPants
        activeSessions = newSessions

        if !isWakingUp && oldState == .idle && newState != .idle {
            // Transition from idle to active: play wakeUp animation first
            isWakingUp = true
            currentState = .wakeUp
            frameIndex = 0
            reloadFramesAndAnimate()

            wakeUpTimer?.invalidate()
            wakeUpTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.isWakingUp = false
                // Re-resolve the actual state now (not the stale captured value)
                let freshData = self.stateReader.read()
                let freshState = freshData.map { PetState.resolve(from: $0) } ?? .idle
                self.currentState = freshState
                self.frameIndex = 0
                self.reloadFramesAndAnimate()
            }
        } else if !isWakingUp {
            // Normal state update — reload only if something changed
            let needsReload = newState != oldState
                           || newActivity != oldActivity
                           || newHat?.rawValue != oldHat?.rawValue
                           || newGlasses?.rawValue != oldGlasses?.rawValue
                           || newPants?.rawValue != oldPants?.rawValue
            currentState = newState
            if needsReload {
                frameIndex = 0
                reloadFramesAndAnimate()
            }
        }
        // While isWakingUp, ignore state changes — the wakeUpTimer will apply them

        menuController.updateState(data)
    }

    private func reloadFramesAndAnimate() {
        let count = PixelArtRenderer.frameCount(state: currentState)
        currentFrames = (0..<count).map { i in
            PixelArtRenderer.renderFrame(
                state: currentState,
                activity: currentActivity,
                hat: currentHat,
                glasses: currentGlasses,
                pants: currentPants,
                frameIndex: i
            )
        }

        if let first = currentFrames.first {
            statusItem.button?.image = first
        }

        frameTimer?.invalidate()
        frameTimer = Timer.scheduledTimer(
            timeInterval: currentState.frameInterval,
            target: self,
            selector: #selector(nextFrame),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(frameTimer!, forMode: .common)
    }

    @objc private func nextFrame() {
        guard !currentFrames.isEmpty else { return }
        frameIndex = (frameIndex + 1) % currentFrames.count
        statusItem.button?.image = currentFrames[frameIndex]
    }

    // MARK: - Click Interaction Animation

    private func playInteraction() {
        stopIdleMotion()
        isPlayingInteraction = true
        interactionFrameIndex = 0

        let sprites = InteractionSprites.frames()
        interactionFrames = sprites.map { baseFrame in
            var overlays: [[[UInt32?]]?] = []
            if let glasses = currentGlasses {
                overlays.append(AccessorySprites.overlay(
                    accessory: glasses, state: .normal, frameIndex: 0))
            }
            if let pants = currentPants {
                overlays.append(AccessorySprites.overlay(
                    accessory: pants, state: .normal, frameIndex: 0))
            }
            if let hat = currentHat {
                overlays.append(AccessorySprites.overlay(
                    accessory: hat, state: .normal, frameIndex: 0))
            }
            let effect = ClaudeEffects.effectOverlay(activity: currentActivity, frameIndex: 0)
            return PixelArtRenderer.renderComposited(base: baseFrame, overlays: overlays, effect: effect)
        }

        frameTimer?.invalidate()
        if let first = interactionFrames.first {
            statusItem.button?.image = first
        }

        interactionTimer?.invalidate()
        interactionTimer = Timer.scheduledTimer(
            timeInterval: InteractionSprites.frameInterval,
            target: self, selector: #selector(nextInteractionFrame),
            userInfo: nil, repeats: true)
        RunLoop.current.add(interactionTimer!, forMode: .common)
    }

    @objc private func nextInteractionFrame() {
        interactionFrameIndex += 1
        if interactionFrameIndex >= interactionFrames.count {
            interactionTimer?.invalidate()
            interactionTimer = nil
            isPlayingInteraction = false
            reloadFramesAndAnimate()
            scheduleRandomIdleMotion()
            return
        }
        statusItem.button?.image = interactionFrames[interactionFrameIndex]
    }

    // MARK: - Random Idle Motions

    private func scheduleRandomIdleMotion() {
        randomIdleTimer?.invalidate()
        let delay = TimeInterval.random(in: 60...180)
        randomIdleTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.triggerRandomIdleMotion()
        }
    }

    private func triggerRandomIdleMotion() {
        guard !isPlayingInteraction && !isPlayingIdleMotion && !isWakingUp else {
            scheduleRandomIdleMotion()
            return
        }
        let allowed = IdleMotionType.allCases.filter { $0.allowedStates.contains(currentState) }
        // Weighted selection: wave 3x, blink 1x, others 2x
        let weighted: [IdleMotionType] = allowed.flatMap { motion -> [IdleMotionType] in
            switch motion {
            case .wave:    return [motion, motion, motion]
            case .blink:   return [motion]
            default:       return [motion, motion]
            }
        }
        guard let motion = weighted.randomElement() else {
            scheduleRandomIdleMotion()
            return
        }
        playIdleMotion(motion)
    }

    private func playIdleMotion(_ motion: IdleMotionType) {
        isPlayingIdleMotion = true
        idleMotionFrameIndex = 0
        idleMotionFrameInterval = motion.frameInterval

        let sprites = IdleMotionSprites.frames(motion: motion)
        idleMotionFrames = sprites.map { baseFrame in
            var overlays: [[[UInt32?]]?] = []
            if let glasses = currentGlasses {
                overlays.append(AccessorySprites.overlay(
                    accessory: glasses, state: currentState, frameIndex: 0))
            }
            if let pants = currentPants {
                overlays.append(AccessorySprites.overlay(
                    accessory: pants, state: currentState, frameIndex: 0))
            }
            if let hat = currentHat {
                overlays.append(AccessorySprites.overlay(
                    accessory: hat, state: currentState, frameIndex: 0))
            }
            let effect = ClaudeEffects.effectOverlay(activity: currentActivity, frameIndex: 0)
            return PixelArtRenderer.renderComposited(base: baseFrame, overlays: overlays, effect: effect)
        }

        frameTimer?.invalidate()
        if let first = idleMotionFrames.first {
            statusItem.button?.image = first
        }

        idleMotionTimer?.invalidate()
        idleMotionTimer = Timer.scheduledTimer(
            timeInterval: idleMotionFrameInterval,
            target: self, selector: #selector(nextIdleMotionFrame),
            userInfo: nil, repeats: true)
        RunLoop.current.add(idleMotionTimer!, forMode: .common)
    }

    @objc private func nextIdleMotionFrame() {
        idleMotionFrameIndex += 1
        if idleMotionFrameIndex >= idleMotionFrames.count {
            stopIdleMotion()
            reloadFramesAndAnimate()
            scheduleRandomIdleMotion()
            return
        }
        statusItem.button?.image = idleMotionFrames[idleMotionFrameIndex]
    }

    private func stopIdleMotion() {
        idleMotionTimer?.invalidate()
        idleMotionTimer = nil
        isPlayingIdleMotion = false
    }

    // MARK: - Sleep/Wake

    @objc private func onSleep() {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
        wakeUpTimer?.invalidate()
        interactionTimer?.invalidate()
        idleMotionTimer?.invalidate()
        randomIdleTimer?.invalidate()
    }

    @objc private func onWake() {
        startStatePolling()
        reloadFramesAndAnimate()
        scheduleRandomIdleMotion()
    }
}

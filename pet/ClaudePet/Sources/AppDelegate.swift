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
    private var isWakingUp: Bool = false
    private var frameIndex = 0
    private var currentFrames: [NSImage] = []
    private var activeSessions: Int = 0
    private var stateReader = PetStateReader()
    private var progressTracker = ProgressTracker()
    private var menuController: StatusMenuController!
    private var notificationManager = NotificationManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notificationManager.requestPermission()

        // Load selected hat and glasses from progress
        currentHat = progressTracker.selectedHat()
        currentGlasses = progressTracker.selectedGlasses()

        menuController = StatusMenuController()
        let _ = menuController.setupPopover()

        setupStatusItem()
        startStatePolling()
        reloadFramesAndAnimate()

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

        // Load current hat and glasses selections
        let newHat = progressTracker.selectedHat()
        let newGlasses = progressTracker.selectedGlasses()

        // Capture old values for change detection before updating
        let oldState = currentState
        let oldActivity = currentActivity
        let oldHat = currentHat
        let oldGlasses = currentGlasses

        currentActivity = newActivity
        currentHat = newHat
        currentGlasses = newGlasses
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

    @objc private func onSleep() {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
        wakeUpTimer?.invalidate()
    }

    @objc private func onWake() {
        startStatePolling()
        reloadFramesAndAnimate()
    }
}

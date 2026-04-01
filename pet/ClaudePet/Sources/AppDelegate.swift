import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem: NSStatusItem = {
        NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()

    private var frameTimer: Timer?
    private var stateTimer: Timer?
    private var currentState: PetState = .idle
    private var frameIndex = 0
    private var frames: [PetState: [NSImage]] = [:]
    private var stateReader = PetStateReader()
    private var lastStateData: PetStateData?
    private var menuController: StatusMenuController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        frames = PixelArtRenderer.allFrames()
        menuController = StatusMenuController()

        setupStatusItem()
        startStatePolling()
        startAnimation(for: .idle)

        // Handle sleep/wake
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
        if let stateFrames = frames[.idle], let first = stateFrames.first {
            statusItem.button?.image = first
        }
        statusItem.menu = menuController.buildMenu(state: nil)
    }

    private func startStatePolling() {
        stateTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.pollState()
        }
    }

    private func pollState() {
        let data = stateReader.read()
        lastStateData = data

        let newState: PetState
        if let data = data {
            newState = PetState.resolve(from: data)
        } else {
            newState = .idle
        }

        if newState != currentState {
            currentState = newState
            frameIndex = 0
            startAnimation(for: newState)
        }

        statusItem.menu = menuController.buildMenu(state: data)
    }

    private func startAnimation(for state: PetState) {
        frameTimer?.invalidate()
        frameTimer = Timer.scheduledTimer(
            timeInterval: state.frameInterval,
            target: self,
            selector: #selector(nextFrame),
            userInfo: nil,
            repeats: true
        )
        RunLoop.current.add(frameTimer!, forMode: .common)
    }

    @objc private func nextFrame() {
        guard let stateFrames = frames[currentState], !stateFrames.isEmpty else { return }
        frameIndex = (frameIndex + 1) % stateFrames.count
        statusItem.button?.image = stateFrames[frameIndex]
    }

    @objc private func onSleep() {
        frameTimer?.invalidate()
        stateTimer?.invalidate()
    }

    @objc private func onWake() {
        startStatePolling()
        startAnimation(for: currentState)
    }
}

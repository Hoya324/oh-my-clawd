import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var statusItem: NSStatusItem = {
        NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    }()

    private var frameTimer: Timer?
    private var stateTimer: Timer?
    private var currentState: PetState = .idle
    private var currentMuscle: MuscleStage = .normal
    private var currentPet: PetType = .cat
    private var friendPets: [PetType] = []
    private var frameIndex = 0
    private var currentFrames: [NSImage] = []
    private var activeSessions: Int = 0
    private var stateReader = PetStateReader()
    private var progressTracker = ProgressTracker()
    private var menuController: StatusMenuController!
    private var notificationManager = NotificationManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        notificationManager.requestPermission()

        // Load selected pet from progress
        currentPet = progressTracker.selectedPet()

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
        let newMuscle: MuscleStage
        if let data = data {
            newState = PetState.resolve(from: data)
            newMuscle = PetState.resolveMuscle(from: data)
            notificationManager.checkAndNotify(rateLimit: data.rateLimit)
        } else {
            newState = .idle
            newMuscle = .normal
        }

        // Check if selected pet changed
        let newPet = progressTracker.selectedPet()
        let newSessions = data?.activeSessions ?? 0

        // Determine friend pets based on session count
        var newFriends: [PetType] = []
        if newSessions >= 2, let progress = progressTracker.read() {
            let unlocked = PetType.allCases.filter {
                $0 != newPet && progress.unlocked.contains($0.rawValue)
            }
            // Pick most recently unlocked friends
            let sorted = unlocked.sorted { a, b in
                let aDate = progress.unlockedAt[a.rawValue] ?? ""
                let bDate = progress.unlockedAt[b.rawValue] ?? ""
                return aDate > bDate
            }
            let friendCount = min(newSessions - 1, 2)
            newFriends = Array(sorted.prefix(friendCount))
        }

        let needsReload = (newState != currentState)
                       || (newMuscle != currentMuscle)
                       || (newPet != currentPet)
                       || (newFriends != friendPets)

        currentState = newState
        currentMuscle = newMuscle
        currentPet = newPet
        friendPets = newFriends
        activeSessions = newSessions

        if needsReload {
            frameIndex = 0
            reloadFramesAndAnimate()
        }

        menuController.updateState(data)
    }

    private func reloadFramesAndAnimate() {
        if friendPets.isEmpty {
            currentFrames = PixelArtRenderer.renderedFrames(
                pet: currentPet,
                muscle: currentMuscle,
                state: currentState
            )
        } else {
            // Pre-render combined frames (main + friends)
            let provider = PixelArtRenderer.spriteProvider(for: currentPet)
            let mainFrames = provider.frames(state: currentState, muscle: currentMuscle)
            currentFrames = (0..<mainFrames.count).map { i in
                PixelArtRenderer.renderMenuBarImage(
                    mainPet: currentPet, muscle: currentMuscle,
                    state: currentState, frameIndex: i,
                    friendPets: friendPets
                )
            }
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
    }

    @objc private func onWake() {
        startStatePolling()
        reloadFramesAndAnimate()
    }
}

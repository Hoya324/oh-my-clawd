import SwiftUI

extension Notification.Name {
    static let accessoryChanged = Notification.Name("accessoryChanged")
}

// MARK: - Data bridge from AppKit to SwiftUI
class ClawdViewModel: ObservableObject {
    @Published var currentState: PetState = .idle
    @Published var activityLevel: ActivityLevel = .normal
    @Published var activeSessions: Int = 0
    @Published var activeAgents: Int = 0
    @Published var activeProjectNames: [String] = []
    @Published var unlockedAccessories: [AccessoryType] = []
    @Published var selectedHat: AccessoryType? = nil
    @Published var selectedGlasses: AccessoryType? = nil
    @Published var selectedPants: AccessoryType? = nil
    @Published var nextUnlockAccessory: AccessoryType? = nil
    @Published var nextUnlockCurrent: Int = 0
    @Published var nextUnlockTarget: Int = 1
    @Published var fiveHourPercent: Double?
    @Published var weeklyPercent: Double?
    @Published var fiveHourResetsAt: String?
    @Published var weeklyResetsAt: String?
    @Published var isHudEnabled: Bool = false
    @Published var updateStatus: UpdateStatus = .idle

    // Companion
    @Published var reminders: ClawdReminders = .default
    @Published var openMemos: [ClawdMemo] = []
    @Published var lastReply: String = ""
    @Published var chatInProgress: Bool = false
    @Published var chatError: String? = nil
    @Published var lastFailedInput: String? = nil
    @Published var claudeCliPath: String? = nil
    @Published var connectionLabel: String = "연결 확인 중…"
    @Published var isConnected: Bool = false
    @Published var aiEnabled: Bool = true

    private let progressTracker = ProgressTracker()
    private let clawdMemory = ClawdMemoryStore()
    private lazy var actionRunner = ClawdActionRunner(memory: clawdMemory)
    private lazy var chat = ClawdChat(memory: clawdMemory)
    private static let hudSettingsPath = NSHomeDirectory() + "/.claude/settings.json"

    func refresh(stateData: PetStateData?) {
        if let data = stateData {
            currentState = PetState.resolve(from: data)
            activityLevel = PetState.resolveActivityLevel(from: data)
            activeSessions = data.activeSessions
            activeAgents = data.aggregate.totalRunningAgents
            activeProjectNames = data.sessions.map { $0.project }
            fiveHourPercent = data.rateLimit.fiveHourPercent
            weeklyPercent = data.rateLimit.weeklyPercent
            fiveHourResetsAt = data.rateLimit.fiveHourResetsAt
            weeklyResetsAt = data.rateLimit.weeklyResetsAt
        } else {
            currentState = .idle
            activityLevel = .normal
            activeSessions = 0
            activeAgents = 0
            activeProjectNames = []
            fiveHourPercent = nil
            weeklyPercent = nil
            fiveHourResetsAt = nil
            weeklyResetsAt = nil
        }

        if let progress = progressTracker.read() {
            unlockedAccessories = AccessoryType.allCases.filter {
                progress.unlockedAccessories.contains($0.rawValue)
            }
        } else {
            unlockedAccessories = []
        }

        selectedHat = progressTracker.selectedHat()
        selectedGlasses = progressTracker.selectedGlasses()
        selectedPants = progressTracker.selectedPants()

        if let next = progressTracker.nextUnlock(),
           let (current, target) = progressTracker.unlockProgress(for: next) {
            nextUnlockAccessory = next
            nextUnlockCurrent = current
            nextUnlockTarget = target
        } else {
            nextUnlockAccessory = nil
        }

        isHudEnabled = Self.readHudEnabled()
        loadCompanionState()
    }

    // MARK: - Companion

    func loadCompanionState() {
        let file = clawdMemory.read()
        reminders = file.reminders
        openMemos = file.memos.filter { !$0.done }
        lastReply = file.chatLog.last(where: { $0.role == .clawd })?.text ?? ""
        aiEnabled = file.aiEnabled ?? true
    }

    func toggleAI() {
        clawdMemory.update { $0.aiEnabled = !($0.aiEnabled ?? true) }
        loadCompanionState()
    }

    func sendChat(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !chatInProgress else { return }
        chatError = nil
        lastFailedInput = nil

        // AI disabled: save the raw text as a memo with no dueAt. Instant,
        // no network, no token usage.
        if !aiEnabled {
            let response = ClawdResponse(
                actions: [ClawdAction(
                    type: ClawdActionType.addMemo.rawValue,
                    text: trimmed, dueAt: nil, tags: [], id: nil,
                    kind: nil, enabled: nil, intervalMin: nil, timeOfDay: nil
                )],
                reply: "메모로 저장했어요."
            )
            actionRunner.apply(userText: trimmed, response: response)
            loadCompanionState()
            return
        }

        chatInProgress = true
        chat.send(userText: trimmed) { [weak self] result in
            guard let self = self else { return }
            self.chatInProgress = false
            switch result {
            case .success(let response):
                self.actionRunner.apply(userText: trimmed, response: response)
                self.loadCompanionState()
            case .failure(let err):
                self.handleChatFailure(userText: trimmed, error: err)
            }
        }
    }

    private func handleChatFailure(userText: String, error: ClawdChatError) {
        chatError = Self.errorMessage(for: error)
        lastFailedInput = userText
    }

    private static func errorMessage(for error: ClawdChatError) -> String {
        switch error {
        case .cliNotFound:
            return "Claude 연결이 없어요. Claude Code에 로그인되어 있는지 확인해주세요."
        case .timeout:
            return "응답이 오지 않았어요. 다시 한번 보내볼까요?"
        case .processFailed(let msg):
            return "오류가 났어요: \(msg)"
        case .parseFailed:
            return "응답을 이해하지 못했어요. 다시 시도해주세요."
        }
    }

    func toggleReminder(kind: String) {
        let current: ReminderConfig
        switch kind {
        case "water":   current = reminders.water
        case "stretch": current = reminders.stretch
        case "diary":   current = reminders.diary
        default: return
        }
        actionRunner.setReminderDirect(kind: kind, enabled: !current.enabled)
        loadCompanionState()
    }

    func setReminderInterval(kind: String, minutes: Int) {
        actionRunner.setReminderDirect(kind: kind, intervalMin: minutes)
        loadCompanionState()
    }

    func setDiaryTime(_ time: String) {
        actionRunner.setReminderDirect(kind: "diary", timeOfDay: time)
        loadCompanionState()
    }

    func completeMemo(_ id: String) {
        actionRunner.completeMemo(id: id)
        loadCompanionState()
    }

    func deleteMemo(_ id: String) {
        actionRunner.deleteMemo(id: id)
        loadCompanionState()
    }

    // MARK: - HUD Toggle

    static func readHudEnabled() -> Bool {
        guard let data = FileManager.default.contents(atPath: hudSettingsPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let statusLine = json["statusLine"] as? [String: Any],
              let command = statusLine["command"] as? String else {
            return false
        }
        return command.contains("hud.mjs")
    }

    func toggleHud() {
        isHudEnabled.toggle()
        let url = URL(fileURLWithPath: Self.hudSettingsPath)

        var json: [String: Any]
        if let data = try? Data(contentsOf: url),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            json = parsed
        } else {
            json = [:]
        }

        if isHudEnabled {
            json["statusLine"] = [
                "type": "command",
                "command": "bash -c 'node \"$HOME/.claude-hud/hud.mjs\"'"
            ]
        } else {
            json.removeValue(forKey: "statusLine")
        }

        if let newData = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]) {
            try? newData.write(to: url)
        }
    }

    func checkForUpdates() {
        updateStatus = .checking
        UpdateChecker.check { [weak self] status in
            self?.updateStatus = status
        }
    }

    /// Download and install the latest release, then relaunch.
    func installUpdate() {
        guard case .available(let version, let dmgURL) = updateStatus,
              !dmgURL.isEmpty else { return }
        updateStatus = .installing(0)
        UpdateInstaller.installAndRelaunch(
            dmgURL: dmgURL,
            version: version,
            progress: { [weak self] p in
                self?.updateStatus = .installing(p)
            },
            completion: { [weak self] result in
                switch result {
                case .success(let v):
                    self?.updateStatus = .installed(v)
                case .failure(let e):
                    self?.updateStatus = .failed(e.localizedDescription)
                }
            }
        )
    }

    func openReleasePage() {
        if let url = URL(string: UpdateChecker.releasePageURL) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Accessory selection

    func selectHat(_ hat: AccessoryType?) {
        // Tapping the currently selected hat deselects it
        let newHat: AccessoryType? = (hat == selectedHat) ? nil : hat
        selectedHat = newHat
        progressTracker.selectHat(newHat)
        NotificationCenter.default.post(name: .accessoryChanged, object: nil)
    }

    func selectGlasses(_ glasses: AccessoryType?) {
        // Tapping the currently selected glasses deselects them
        let newGlasses: AccessoryType? = (glasses == selectedGlasses) ? nil : glasses
        selectedGlasses = newGlasses
        progressTracker.selectGlasses(newGlasses)
        NotificationCenter.default.post(name: .accessoryChanged, object: nil)
    }

    func selectPants(_ pants: AccessoryType?) {
        let newPants: AccessoryType? = (pants == selectedPants) ? nil : pants
        selectedPants = newPants
        progressTracker.selectPants(newPants)
        NotificationCenter.default.post(name: .accessoryChanged, object: nil)
    }
}

// MARK: - Main Popover View
struct CollectionPopoverView: View {
    @ObservedObject var viewModel: ClawdViewModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection
                    Divider()
                    hatGridSection
                    Divider()
                    glassesGridSection
                    Divider()
                    pantsGridSection
                    if viewModel.nextUnlockAccessory != nil {
                        Divider()
                        progressSection
                    }
                    Divider()
                    ClawdSection(viewModel: viewModel)
                }
            }
            Divider()
            footerSection
        }
        .frame(width: 280, height: 640)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Clawd")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(viewModel.activityLevel.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(viewModel.activityLevel == .supercharged ? .yellow : .secondary)
            }
            HStack {
                Text("Sessions: \(viewModel.activeSessions)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Agents: \(viewModel.activeAgents)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            if !viewModel.activeProjectNames.isEmpty {
                HStack {
                    Text(projectNamesSummary(viewModel.activeProjectNames))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.75))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
            }
            if viewModel.fiveHourPercent != nil || viewModel.weeklyPercent != nil {
                rateLimitSection
            }
        }
        .padding(12)
    }

    // MARK: - Rate Limit
    private var rateLimitSection: some View {
        HStack(spacing: 0) {
            if let pct5h = viewModel.fiveHourPercent {
                let intPct = Int(pct5h.rounded())
                Text("5h:")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("\(intPct)%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(rateLimitColor(intPct))
                if let reset = formatResetTime(viewModel.fiveHourResetsAt) {
                    Text("(\(reset))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            if viewModel.fiveHourPercent != nil && viewModel.weeklyPercent != nil {
                Text(" | ")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            if let pctWk = viewModel.weeklyPercent {
                let intPct = Int(pctWk.rounded())
                Text("wk:")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("\(intPct)%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(rateLimitColor(intPct))
                if let reset = formatResetTime(viewModel.weeklyResetsAt) {
                    Text("(\(reset))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    private func rateLimitColor(_ percent: Int) -> Color {
        if percent >= 90 { return .red }
        if percent >= 70 { return .yellow }
        return .green
    }

    private func projectNamesSummary(_ names: [String]) -> String {
        let shown = names.prefix(3)
        let extra = names.count - shown.count
        let head = shown.joined(separator: ", ")
        return extra > 0 ? "\(head) +\(extra) more" : head
    }

    private func formatResetTime(_ isoString: String?) -> String? {
        guard let isoString = isoString, !isoString.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString) else { return nil }
        let diffSeconds = date.timeIntervalSinceNow
        guard diffSeconds > 0 else { return nil }
        let diffMinutes = Int(diffSeconds / 60)
        let diffHours = diffMinutes / 60
        let diffDays = diffHours / 24
        if diffDays > 0 {
            return "\(diffDays)d\(diffHours % 24)h"
        }
        return "\(diffHours)h\(diffMinutes % 60)m"
    }

    // MARK: - Hat Grid
    private var hatGridSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hats")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            let columns = Array(repeating: GridItem(.fixed(44), spacing: 6), count: 5)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(AccessoryType.hats, id: \.self) { hat in
                    AccessoryGridCell(
                        accessory: hat,
                        isUnlocked: viewModel.unlockedAccessories.contains(hat),
                        isSelected: viewModel.selectedHat == hat,
                        onSelect: { viewModel.selectHat(hat) }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Glasses Grid
    private var glassesGridSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Glasses")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            let columns = Array(repeating: GridItem(.fixed(44), spacing: 6), count: 5)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(AccessoryType.glasses, id: \.self) { glasses in
                    AccessoryGridCell(
                        accessory: glasses,
                        isUnlocked: viewModel.unlockedAccessories.contains(glasses),
                        isSelected: viewModel.selectedGlasses == glasses,
                        onSelect: { viewModel.selectGlasses(glasses) }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Pants Grid
    private var pantsGridSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pants")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 10)

            let columns = Array(repeating: GridItem(.fixed(44), spacing: 6), count: 5)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(AccessoryType.pants, id: \.self) { pants in
                    AccessoryGridCell(
                        accessory: pants,
                        isUnlocked: viewModel.unlockedAccessories.contains(pants),
                        isSelected: viewModel.selectedPants == pants,
                        onSelect: { viewModel.selectPants(pants) }
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    // MARK: - Progress
    private var progressSection: some View {
        VStack(spacing: 4) {
            if let accessory = viewModel.nextUnlockAccessory {
                HStack {
                    Text(accessory.displayName)
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text("\(viewModel.nextUnlockCurrent)/\(viewModel.nextUnlockTarget)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                ProgressView(
                    value: Double(viewModel.nextUnlockCurrent),
                    total: Double(max(1, viewModel.nextUnlockTarget))
                )
                .tint(.cyan)
                Text(accessory.unlockDescription)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
    }

    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: 6) {
            HStack {
                Text("HUD")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Button(action: { viewModel.toggleHud() }) {
                    Text(viewModel.isHudEnabled ? "ON" : "OFF")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(viewModel.isHudEnabled ? .green : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(viewModel.isHudEnabled ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
            updateButton
            Button("Quit oh-my-clawd") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var updateButton: some View {
        let current = UpdateChecker.currentVersion
        HStack(spacing: 4) {
            Text("v\(current)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
            Spacer()
            updateStatusTrailing(current: current)
        }
    }

    @ViewBuilder
    private func updateStatusTrailing(current: String) -> some View {
        switch viewModel.updateStatus {
        case .idle:
            Button(action: { viewModel.checkForUpdates() }) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9))
                    Text("업데이트 확인")
                        .font(.system(size: 10))
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        case .checking:
            HStack(spacing: 3) {
                ProgressView().controlSize(.small)
                Text("확인 중…")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        case .upToDate:
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
                Text("최신")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        case .available(let version, _):
            Button(action: { viewModel.installUpdate() }) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 9))
                    Text("→ v\(version) 설치")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4)
                    .fill(Color.cyan.opacity(0.15)))
            }
            .buttonStyle(.plain)
        case .installing(let p):
            HStack(spacing: 4) {
                ProgressView(value: p)
                    .frame(width: 60)
                Text("\(Int(p * 100))%")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        case .installed(let v):
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
                Text("v\(v) 설치됨. 재시작 중…")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        case .failed(let msg):
            HStack(spacing: 3) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.yellow)
                Text(msg.isEmpty ? "업데이트 실패" : msg)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .help(msg)
        }
    }
}

// MARK: - Accessory Grid Cell
struct AccessoryGridCell: View {
    let accessory: AccessoryType
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: { if isUnlocked { onSelect() } }) {
            VStack(spacing: 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.cyan.opacity(0.2) : Color.clear)
                        .frame(width: 40, height: 40)

                    if isUnlocked {
                        ClawdPreviewView(hat: accessory.category == .hat ? accessory : nil,
                                         glasses: accessory.category == .glasses ? accessory : nil,
                                         pants: accessory.category == .pants ? accessory : nil)
                            .frame(width: 32, height: 32)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
                )

                Text(isUnlocked ? accessory.displayName : "???")
                    .font(.system(size: 8))
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .help(isUnlocked ? accessory.displayName : accessory.unlockDescription)
    }
}

// MARK: - Clawd Preview (NSImage bridge)
struct ClawdPreviewView: NSViewRepresentable {
    let hat: AccessoryType?
    let glasses: AccessoryType?
    var pants: AccessoryType? = nil

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = rendered()
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        nsView.image = rendered()
    }

    private func rendered() -> NSImage {
        PixelArtRenderer.renderFrame(
            state: .normal, activity: .normal,
            hat: hat, glasses: glasses, pants: pants,
            frameIndex: 0
        )
    }
}

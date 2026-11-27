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
    @Published var activeProjects: [ProjectGroup] = []
    @Published var unlockedAccessories: [AccessoryType] = []
    @Published var selectedHat: AccessoryType? = nil
    @Published var selectedGlasses: AccessoryType? = nil
    @Published var selectedPants: AccessoryType? = nil
    @Published var nextUnlockAccessory: AccessoryType? = nil
    @Published var nextUnlockCurrent: Int = 0
    @Published var nextUnlockTarget: Int = 1
    @Published var unlockProgress: [String: UnlockProgress] = [:]

    // Usage (UsageService: works for every Claude surface)
    @Published var usage: UsageSnapshot?
    @Published var usageStatus: UsageStatus = .loading
    @Published var plan: String?
    @Published var usageDisplayMode: UsageDisplayMode = UsageDisplayMode.load()
    @Published var chatSource: ChatActivityMonitor.Source = .none
    @Published var aggregatorStatus: RuntimeInstaller.AggregatorStatus = .unknown

    @Published var isHudEnabled: Bool = false
    @Published var hudError: String? = nil
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
    @Published var notifAuthState: NotificationAuthState = .unknown
    @Published var testNotifStatus: String? = nil
    // UI state for ClawdSection (see the note there about @State)
    @Published var chatInput: String = ""
    @Published var remindersExpanded: Bool = false

    private let progressTracker = ProgressTracker()
    private let selectionStore = SelectionStore()
    private let clawdMemory = ClawdMemoryStore.shared
    /// Set by AppDelegate: re-render the status item after a mode change.
    var onUsageDisplayModeChange: ((UsageDisplayMode) -> Void)?
    /// Set by AppDelegate: refresh usage immediately (popover button).
    var onRefreshUsage: (() -> Void)?
    private lazy var actionRunner = ClawdActionRunner(memory: clawdMemory)
    private lazy var chat = ClawdChat(memory: clawdMemory)
    weak var notificationManager: NotificationManager?

    func refresh(stateData: PetStateData?, petState: PetState) {
        currentState = petState
        activityLevel = PetState.resolveActivityLevel(from: stateData)
        activeSessions = stateData?.activeSessions ?? 0
        activeAgents = stateData?.aggregate.totalRunningAgents ?? 0
        activeProjects = stateData?.projects ?? []

        let progress = progressTracker.read()
        unlockedAccessories = AccessoryType.allCases.filter {
            progress?.unlockedAccessories.contains($0.rawValue) ?? false
        }
        unlockProgress = progress?.unlockProgress ?? [:]

        let selection = selectionStore.read()
        selectedHat = selection.hat
        selectedGlasses = selection.glasses
        selectedPants = selection.pants

        if let (next, p) = progressTracker.nextUnlock(in: progress) {
            nextUnlockAccessory = next
            nextUnlockCurrent = p.current
            nextUnlockTarget = p.target
        } else {
            nextUnlockAccessory = nil
        }

        isHudEnabled = HudSettings.isEnabled()
        loadCompanionState()
    }

    func applyUsage(_ snapshot: UsageSnapshot?, status: UsageStatus) {
        usage = snapshot
        usageStatus = status
    }

    func setUsageDisplayMode(_ mode: UsageDisplayMode) {
        usageDisplayMode = mode
        mode.save()
        onUsageDisplayModeChange?(mode)
    }

    func refreshUsage() {
        onRefreshUsage?()
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

    func sendTestNotification() {
        testNotifStatus = "전송 중…"
        guard let nm = notificationManager else {
            testNotifStatus = "알림 매니저를 찾지 못했어요."
            return
        }
        nm.sendTestNotification { [weak self] success, message in
            self?.testNotifStatus = message
            self?.notifAuthState = nm.authState
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self?.testNotifStatus = nil
            }
        }
    }

    func openNotificationSettings() {
        NotificationManager.openSystemNotificationSettings()
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

    func toggleHud() {
        let target = !isHudEnabled
        do {
            try HudSettings.setEnabled(target)
            hudError = nil
        } catch HudSettings.ToggleError.unreadableSettings {
            hudError = "settings.json을 읽을 수 없어서 건드리지 않았어요"
        } catch {
            hudError = "settings.json 저장 실패"
        }
        isHudEnabled = HudSettings.isEnabled()
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
        selectionStore.select(newHat, category: .hat)
        NotificationCenter.default.post(name: .accessoryChanged, object: nil)
    }

    func selectGlasses(_ glasses: AccessoryType?) {
        // Tapping the currently selected glasses deselects them
        let newGlasses: AccessoryType? = (glasses == selectedGlasses) ? nil : glasses
        selectedGlasses = newGlasses
        selectionStore.select(newGlasses, category: .glasses)
        NotificationCenter.default.post(name: .accessoryChanged, object: nil)
    }

    func selectPants(_ pants: AccessoryType?) {
        let newPants: AccessoryType? = (pants == selectedPants) ? nil : pants
        selectedPants = newPants
        selectionStore.select(newPants, category: .pants)
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
        VStack(spacing: 6) {
            HStack {
                Text("Clawd")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(viewModel.currentState.displayNameKO)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(viewModel.activityLevel == .supercharged ? .yellow : .secondary)
            }
            usageCard
            HStack {
                Text("세션 \(viewModel.activeSessions)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Spacer()
                Text("에이전트 \(viewModel.activeAgents)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            if !viewModel.activeProjects.isEmpty {
                HStack {
                    Text(projectSummary(viewModel.activeProjects))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.75))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }
            }
            if let line = activityLine {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 9))
                    Text(line)
                        .font(.system(size: 10))
                    Spacer()
                }
                .foregroundColor(.secondary)
            }
            if let warning = aggregatorWarning {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 9))
                    Text(warning)
                        .font(.system(size: 10))
                        .lineLimit(2)
                    Spacer()
                }
                .foregroundColor(.orange)
            }
        }
        .padding(12)
    }

    private var activityLine: String? {
        switch viewModel.chatSource {
        case .claudeApp:   return "Claude 앱에서 대화 중"
        case .usageRising: return viewModel.activeSessions == 0 ? "다른 곳에서 Claude 사용 중" : nil
        case .none:        return nil
        }
    }

    private var aggregatorWarning: String? {
        switch viewModel.aggregatorStatus {
        case .nodeMissing:
            return "Node.js가 없어 Claude Code 세션 추적이 꺼져 있어요"
        case .failed(let msg):
            return msg
        default:
            return nil
        }
    }

    // MARK: - Usage
    @ViewBuilder
    private var usageCard: some View {
        VStack(spacing: 5) {
            switch (viewModel.usage, viewModel.usageStatus) {
            case (.some(let u), _):
                usageHeader(u)
                usageRow(label: "현재 세션", percent: u.fiveHourPercent, resetsAt: u.fiveHourResetsAt)
                usageRow(label: "이번 주", percent: u.weeklyPercent, resetsAt: u.weeklyResetsAt)
                ForEach(u.modelLimits, id: \.model) { m in
                    usageRow(label: "이번 주 (\(m.label))", percent: m.percent, resetsAt: m.resetsAt)
                }
                HStack {
                    Text(usageFootnote(u))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.8))
                    Spacer()
                    Button(action: { viewModel.refreshUsage() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("사용량 새로고침")
                }
            case (.none, .loading):
                usagePlaceholder("사용량 불러오는 중…")
            case (.none, .noCredentials):
                usagePlaceholder("이 Mac에서 Claude Code에 로그인하면 사용량이 보여요")
            case (.none, .tokenExpired):
                usagePlaceholder("로그인 갱신을 기다리는 중이에요. Claude Code를 쓰면 바로 갱신돼요")
            case (.none, _):
                usagePlaceholder("사용량을 불러오지 못했어요")
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.08)))
    }

    private func usageHeader(_ u: UsageSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text("사용량")
                    .font(.system(size: 11, weight: .semibold))
                if let plan = viewModel.plan {
                    Text(plan)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            if let pace = UsagePace.summary(u) {
                Text(pace)
                    .font(.system(size: 10))
                    .foregroundColor(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func usageRow(label: String, percent: Double?, resetsAt: Date?) -> some View {
        let pct = percent.map { Int($0.rounded()) }
        return VStack(spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                Spacer()
                if let reset = UsagePace.resetLabel(resetsAt) {
                    Text(reset)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .help(formatReset(resetsAt).map { "\($0) 남음" } ?? "")
                }
                Text(pct.map { "\($0)%" } ?? "–")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(pct.map(rateLimitColor) ?? .secondary)
            }
            ProgressView(value: min(100, max(0, percent ?? 0)), total: 100)
                .tint(pct.map(rateLimitColor) ?? .secondary)
                .scaleEffect(x: 1, y: 0.7, anchor: .center)
        }
    }

    private func usagePlaceholder(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private func usageFootnote(_ u: UsageSnapshot) -> String {
        let age = Int(Date().timeIntervalSince(u.fetchedAt))
        let when = age < 60 ? "방금" : "\(age / 60)분 전"
        let stale = viewModel.usageStatus == .tokenExpired ? " (로그인 만료, 마지막 값)" : ""
        return "\(when) 갱신\(stale)"
    }

    private func rateLimitColor(_ percent: Int) -> Color {
        if percent >= 90 { return .red }
        if percent >= 70 { return .orange }
        return .green
    }

    /// "navi-api ×2, web" — duplicates are grouped instead of repeated.
    private func projectSummary(_ groups: [ProjectGroup]) -> String {
        let label = { (g: ProjectGroup) in g.count > 1 ? "\(g.name) ×\(g.count)" : g.name }
        let shown = groups.prefix(3).map(label)
        let extra = groups.count - shown.count
        let head = shown.joined(separator: ", ")
        return extra > 0 ? "\(head) 외 \(extra)개" : head
    }

    private func formatReset(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        let diff = date.timeIntervalSinceNow
        guard diff > 0 else { return nil }
        let minutes = Int(diff / 60)
        let hours = minutes / 60
        let days = hours / 24
        if days > 0 { return "\(days)일 \(hours % 24)시간" }
        if hours > 0 { return "\(hours)시간 \(minutes % 60)분" }
        return "\(minutes)분"
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
                        unlockHint: hat.unlockDescriptionKO(progress: viewModel.unlockProgress[hat.rawValue]),
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
                        unlockHint: glasses.unlockDescriptionKO(progress: viewModel.unlockProgress[glasses.rawValue]),
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
                        unlockHint: pants.unlockDescriptionKO(progress: viewModel.unlockProgress[pants.rawValue]),
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
                Text(accessory.unlockDescriptionKO(progress: viewModel.unlockProgress[accessory.rawValue]))
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
            if let err = viewModel.hudError {
                HStack {
                    Text(err)
                        .font(.system(size: 9))
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
            HStack {
                Text("메뉴바 사용량")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.usageDisplayMode },
                    set: { viewModel.setUsageDisplayMode($0) }
                )) {
                    ForEach(UsageDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 140)
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
            Button(action: { viewModel.checkForUpdates() }) {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.green)
                    Text("최신")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .help("클릭하면 업데이트를 다시 확인해요")
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
    var unlockHint: String? = nil
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
        .help(isUnlocked ? accessory.displayName : (unlockHint ?? accessory.unlockDescriptionKO))
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

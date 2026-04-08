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
    @Published var unlockedAccessories: [AccessoryType] = []
    @Published var selectedHat: AccessoryType? = nil
    @Published var selectedGlasses: AccessoryType? = nil
    @Published var nextUnlockAccessory: AccessoryType? = nil
    @Published var nextUnlockCurrent: Int = 0
    @Published var nextUnlockTarget: Int = 1
    @Published var fiveHourPercent: Double?
    @Published var weeklyPercent: Double?
    @Published var fiveHourResetsAt: String?
    @Published var weeklyResetsAt: String?
    @Published var isHudEnabled: Bool = false
    @Published var updateStatus: UpdateStatus = .idle

    private let progressTracker = ProgressTracker()
    private static let hudSettingsPath = NSHomeDirectory() + "/.claude/settings.json"

    func refresh(stateData: PetStateData?) {
        if let data = stateData {
            currentState = PetState.resolve(from: data)
            activityLevel = PetState.resolveActivityLevel(from: data)
            activeSessions = data.activeSessions
            activeAgents = data.aggregate.totalRunningAgents
            fiveHourPercent = data.rateLimit.fiveHourPercent
            weeklyPercent = data.rateLimit.weeklyPercent
            fiveHourResetsAt = data.rateLimit.fiveHourResetsAt
            weeklyResetsAt = data.rateLimit.weeklyResetsAt
        } else {
            currentState = .idle
            activityLevel = .normal
            activeSessions = 0
            activeAgents = 0
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

        if let next = progressTracker.nextUnlock(),
           let (current, target) = progressTracker.unlockProgress(for: next) {
            nextUnlockAccessory = next
            nextUnlockCurrent = current
            nextUnlockTarget = target
        } else {
            nextUnlockAccessory = nil
        }

        isHudEnabled = Self.readHudEnabled()
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
            if case .upToDate = status {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.updateStatus = .idle
                }
            }
        }
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
}

// MARK: - Main Popover View
struct CollectionPopoverView: View {
    @ObservedObject var viewModel: ClawdViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            hatGridSection
            Divider()
            glassesGridSection
            if viewModel.nextUnlockAccessory != nil {
                Divider()
                progressSection
            }
            Divider()
            footerSection
            Spacer(minLength: 0)
        }
        .frame(width: 280)
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
        switch viewModel.updateStatus {
        case .idle:
            Button(action: { viewModel.checkForUpdates() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 10))
                    Text("Check for Updates")
                        .font(.system(size: 11))
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        case .checking:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                Text("Checking...")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        case .upToDate(let version):
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
                Text("Up to date (v\(version))")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        case .available(let version):
            Button(action: { viewModel.openReleasePage() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text("Update Available: \(version)")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                }
            }
            .buttonStyle(.plain)
        case .failed:
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)
                Text("Check failed")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
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
                                         glasses: accessory.category == .glasses ? accessory : nil)
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
            state: .normal,
            activity: .normal,
            hat: hat,
            glasses: glasses,
            frameIndex: 0
        )
    }
}

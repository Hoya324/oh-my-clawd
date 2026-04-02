import SwiftUI

extension Notification.Name {
    static let petSelectionChanged = Notification.Name("petSelectionChanged")
}

// MARK: - Data bridge from AppKit to SwiftUI
class PetViewModel: ObservableObject {
    @Published var currentState: PetState = .idle
    @Published var muscleStage: MuscleStage = .normal
    @Published var activeSessions: Int = 0
    @Published var activeAgents: Int = 0
    @Published var unlockedPets: [PetType] = [.cat]
    @Published var selectedPet: PetType = .cat
    @Published var nextUnlockPet: PetType?
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
    private static let hudEnabledKey = "claudePet.hudEnabled"

    func refresh(stateData: PetStateData?) {
        if let data = stateData {
            currentState = PetState.resolve(from: data)
            muscleStage = PetState.resolveMuscle(from: data)
            activeSessions = data.activeSessions
            activeAgents = data.aggregate.totalRunningAgents
            fiveHourPercent = data.rateLimit.fiveHourPercent
            weeklyPercent = data.rateLimit.weeklyPercent
            fiveHourResetsAt = data.rateLimit.fiveHourResetsAt
            weeklyResetsAt = data.rateLimit.weeklyResetsAt
        } else {
            currentState = .idle
            muscleStage = .normal
            activeSessions = 0
            activeAgents = 0
            fiveHourPercent = nil
            weeklyPercent = nil
            fiveHourResetsAt = nil
            weeklyResetsAt = nil
        }

        if let progress = progressTracker.read() {
            unlockedPets = PetType.allCases.filter { progress.unlocked.contains($0.rawValue) }
        }
        selectedPet = progressTracker.selectedPet()

        if let next = progressTracker.nextUnlock(),
           let (current, target) = progressTracker.unlockProgress(for: next) {
            nextUnlockPet = next
            nextUnlockCurrent = current
            nextUnlockTarget = target
        } else {
            nextUnlockPet = nil
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

    func selectPet(_ pet: PetType) {
        guard unlockedPets.contains(pet) else { return }
        selectedPet = pet
        progressTracker.selectPet(pet)
        NotificationCenter.default.post(name: .petSelectionChanged, object: pet)
    }
}

// MARK: - Main Popover View
struct CollectionPopoverView: View {
    @ObservedObject var viewModel: PetViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            petGridSection
            if viewModel.nextUnlockPet != nil {
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
                Text(viewModel.selectedPet.displayName)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Text(viewModel.muscleStage.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(viewModel.muscleStage == .macho ? .yellow : .secondary)
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

    // MARK: - Pet Grid
    private var petGridSection: some View {
        let columns = Array(repeating: GridItem(.fixed(56), spacing: 8), count: 4)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(PetType.allCases, id: \.self) { pet in
                PetGridCell(
                    pet: pet,
                    isUnlocked: viewModel.unlockedPets.contains(pet),
                    isSelected: viewModel.selectedPet == pet,
                    onSelect: { viewModel.selectPet(pet) }
                )
            }
        }
        .padding(12)
    }

    // MARK: - Progress
    private var progressSection: some View {
        VStack(spacing: 4) {
            if let pet = viewModel.nextUnlockPet {
                HStack {
                    Text("\(pet.displayName)")
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
                Text(pet.unlockDescription)
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
            Button("Quit Claude Pet") {
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

// MARK: - Pet Grid Cell
struct PetGridCell: View {
    let pet: PetType
    let isUnlocked: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: { if isUnlocked { onSelect() } }) {
            VStack(spacing: 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isSelected ? Color.cyan.opacity(0.2) : Color.clear)
                        .frame(width: 48, height: 48)

                    if isUnlocked {
                        PetPixelView(pet: pet, muscle: .normal)
                            .frame(width: 36, height: 36)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
                )

                Text(isUnlocked ? pet.displayName : "???")
                    .font(.system(size: 9))
                    .foregroundColor(isUnlocked ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
        .help(isUnlocked ? pet.displayName : pet.unlockDescription)
    }
}

// MARK: - NSImage to SwiftUI bridge
struct PetPixelView: NSViewRepresentable {
    let pet: PetType
    let muscle: MuscleStage

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        let frames = PixelArtRenderer.renderedFrames(pet: pet, muscle: muscle, state: .normal)
        imageView.image = frames.first
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        let frames = PixelArtRenderer.renderedFrames(pet: pet, muscle: muscle, state: .normal)
        nsView.image = frames.first
    }
}

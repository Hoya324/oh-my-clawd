import SwiftUI

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

    private let progressTracker = ProgressTracker()

    func refresh(stateData: PetStateData?) {
        if let data = stateData {
            currentState = PetState.resolve(from: data)
            muscleStage = PetState.resolveMuscle(from: data)
            activeSessions = data.activeSessions
            activeAgents = data.aggregate.totalRunningAgents
        } else {
            currentState = .idle
            muscleStage = .normal
            activeSessions = 0
            activeAgents = 0
        }

        if let progress = progressTracker.read() {
            unlockedPets = PetType.allCases.filter { progress.unlocked.contains($0.rawValue) }
            selectedPet = PetType(rawValue: progress.selectedPet) ?? .cat
        }

        if let next = progressTracker.nextUnlock(),
           let (current, target) = progressTracker.unlockProgress(for: next) {
            nextUnlockPet = next
            nextUnlockCurrent = current
            nextUnlockTarget = target
        } else {
            nextUnlockPet = nil
        }
    }

    func selectPet(_ pet: PetType) {
        guard unlockedPets.contains(pet) else { return }
        selectedPet = pet
        progressTracker.selectPet(pet)
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
            quitSection
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
        }
        .padding(12)
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

    // MARK: - Quit
    private var quitSection: some View {
        HStack {
            Spacer()
            Button("Quit Claude Pet") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
            Spacer()
        }
        .padding(8)
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

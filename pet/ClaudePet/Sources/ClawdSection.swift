import SwiftUI

struct ClawdSection: View {
    @ObservedObject var viewModel: ClawdViewModel
    @State private var input: String = ""
    @State private var remindersExpanded: Bool = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text("Clawd")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                Text(viewModel.connectionLabel)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.8))
                    .help(viewModel.claudeCliPath ?? "Claude Code OAuth / CLI")
                Spacer()
            }

            HStack(spacing: 6) {
                TextField("Clawd에게 말하기…", text: $input, onCommit: submit)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .focused($inputFocused)
                    .disabled(viewModel.chatInProgress)
                if viewModel.chatInProgress {
                    ProgressView().controlSize(.small)
                } else {
                    Button(action: submit) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if !viewModel.lastReply.isEmpty || viewModel.chatError != nil {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: viewModel.chatError != nil
                              ? "exclamationmark.circle"
                              : "bubble.left.fill")
                            .font(.system(size: 10))
                            .foregroundColor(viewModel.chatError != nil ? .orange : .secondary)
                        Text(viewModel.chatError ?? viewModel.lastReply)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if viewModel.chatError != nil,
                       let failed = viewModel.lastFailedInput {
                        Button(action: retryLastFailed) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 9))
                                Text("다시 보내기: \(failed)")
                                    .font(.system(size: 10))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                            .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 14)
                    }
                }
            }

            DisclosureGroup(isExpanded: $remindersExpanded) {
                VStack(spacing: 6) {
                    reminderRow(
                        emoji: "💧", label: "물",
                        kind: "water",
                        config: viewModel.reminders.water,
                        intervals: [30, 60, 90, 120]
                    )
                    reminderRow(
                        emoji: "🧘", label: "스트레칭",
                        kind: "stretch",
                        config: viewModel.reminders.stretch,
                        intervals: [60, 90, 120, 180]
                    )
                    diaryRow(config: viewModel.reminders.diary)
                }
                .padding(.top, 4)
            } label: {
                Text("리마인더")
                    .font(.system(size: 11, weight: .medium))
            }

            if !viewModel.openMemos.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("📌 기억 중 (\(viewModel.openMemos.count))")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.top, 2)
                    ForEach(viewModel.openMemos) { memo in
                        memoRow(memo)
                    }
                }
            } else if viewModel.lastReply.isEmpty && viewModel.chatError == nil {
                Text("아직 기억할 게 없어요. 위에 말해보세요.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(12)
    }

    private func submit() {
        let text = input
        input = ""
        viewModel.sendChat(text)
    }

    private func retryLastFailed() {
        if let text = viewModel.lastFailedInput {
            viewModel.sendChat(text)
        }
    }

    private func reminderRow(emoji: String,
                             label: String,
                             kind: String,
                             config: ReminderConfig,
                             intervals: [Int]) -> some View {
        HStack(spacing: 6) {
            Text(emoji)
            Text(label)
                .font(.system(size: 11))
                .frame(width: 56, alignment: .leading)
            Toggle("", isOn: Binding(
                get: { config.enabled },
                set: { _ in viewModel.toggleReminder(kind: kind) }
            ))
            .labelsHidden()
            .controlSize(.mini)
            Spacer()
            Picker("", selection: Binding(
                get: { config.intervalMin ?? intervals[1] },
                set: { viewModel.setReminderInterval(kind: kind, minutes: $0) }
            )) {
                ForEach(intervals, id: \.self) { m in
                    Text("\(m)분").tag(m)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 80)
            .disabled(!config.enabled)
        }
    }

    private func diaryRow(config: ReminderConfig) -> some View {
        HStack(spacing: 6) {
            Text("📝")
            Text("일기")
                .font(.system(size: 11))
                .frame(width: 56, alignment: .leading)
            Toggle("", isOn: Binding(
                get: { config.enabled },
                set: { _ in viewModel.toggleReminder(kind: "diary") }
            ))
            .labelsHidden()
            .controlSize(.mini)
            Spacer()
            Picker("", selection: Binding(
                get: { config.timeOfDay ?? "22:00" },
                set: { viewModel.setDiaryTime($0) }
            )) {
                ForEach(["20:00", "21:00", "22:00", "23:00"], id: \.self) { t in
                    Text(t).tag(t)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 80)
            .disabled(!config.enabled)
        }
    }

    private func memoRow(_ memo: ClawdMemo) -> some View {
        HStack(spacing: 6) {
            Button(action: { viewModel.completeMemo(memo.id) }) {
                Image(systemName: "circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)

            Text(memo.text)
                .font(.system(size: 11))
                .lineLimit(2)

            Spacer()

            if let dueIso = memo.dueAt,
               let due = ClawdMemoryStore.parseIso(dueIso) {
                Text(formatDue(due))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            Menu {
                Button("완료") { viewModel.completeMemo(memo.id) }
                Button("삭제", role: .destructive) { viewModel.deleteMemo(memo.id) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }

    private func formatDue(_ due: Date) -> String {
        let cal = Calendar.current
        let fmt = DateFormatter()
        if cal.isDateInToday(due) {
            fmt.dateFormat = "오늘 HH:mm"
        } else if cal.isDateInTomorrow(due) {
            fmt.dateFormat = "내일 HH:mm"
        } else {
            fmt.dateFormat = "M/d HH:mm"
        }
        return fmt.string(from: due)
    }
}

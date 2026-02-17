import SwiftUI
import SwiftData

struct SessionSummaryView: View {
    let viewModel: SessionViewModel
    let onClose: () -> Void
    let onRestart: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var saved = false

    private var endedAt: Date { Date() }

    private var duration: TimeInterval {
        endedAt.timeIntervalSince(viewModel.startedAt)
    }

    private var imagesCompleted: Int {
        viewModel.completedAllImages
            ? viewModel.images.count
            : viewModel.currentIndex + 1
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: viewModel.completedAllImages
                          ? "checkmark.circle.fill" : "stop.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(viewModel.completedAllImages ? .green : .orange)

                    Text("Session Complete")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                }

                // Stats card
                VStack(spacing: 0) {
                    statRow("Board", value: viewModel.boardName)
                    Divider().padding(.horizontal)
                    statRow("Date", value: viewModel.startedAt.formatted(
                        date: .abbreviated, time: .shortened))
                    Divider().padding(.horizontal)
                    statRow("Duration", value: formatDuration(duration))
                    Divider().padding(.horizontal)
                    statRow("Images", value: "\(imagesCompleted) of \(viewModel.images.count)")
                    Divider().padding(.horizontal)
                    statRow("Timer", value: formatInterval(viewModel.timerInterval))
                    Divider().padding(.horizontal)
                    statRow("Order", value: viewModel.playbackOrder == .shuffle
                            ? "Shuffle" : "Sequential")
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: 400)

                // Actions
                HStack(spacing: 16) {
                    Button("Restart") {
                        saveIfNeeded()
                        onRestart()
                    }
                    .buttonStyle(.bordered)

                    Button("Done") {
                        saveIfNeeded()
                        onClose()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(40)
        }
        .onAppear { saveIfNeeded() }
    }

    // MARK: - Components

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Persistence

    private func saveIfNeeded() {
        guard !saved else { return }
        saved = true

        let record = SessionRecord(
            boardId: viewModel.boardId,
            boardName: viewModel.boardName,
            startedAt: viewModel.startedAt,
            endedAt: endedAt,
            duration: duration,
            imageCount: imagesCompleted,
            timerInterval: viewModel.timerInterval,
            playbackOrder: viewModel.playbackOrder,
            completedAllImages: viewModel.completedAllImages
        )
        modelContext.insert(record)
    }
}

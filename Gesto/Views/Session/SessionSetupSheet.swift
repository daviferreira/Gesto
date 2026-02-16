import SwiftUI

struct SessionSetupSheet: View {
    let board: Board
    let onStart: (SessionConfiguration) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var timerInterval: TimeInterval = 60
    @State private var customSeconds: String = ""
    @State private var isCustomTimer = false
    @State private var playbackOrder: PlaybackOrder = .shuffle
    @State private var useAllImages = true
    @State private var imageCount: Int = 20
    @AppStorage("lastTimerInterval") private var lastTimerInterval: Double = 60
    @AppStorage("lastPlaybackOrder") private var lastPlaybackOrder: String = "shuffle"

    private let presets: [(String, TimeInterval)] = [
        ("30s", 30), ("1m", 60), ("2m", 120), ("5m", 300), ("10m", 600)
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Session Setup")
                .font(.title2.bold())

            timerSection
            orderSection
            imageCountSection

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Start", action: startSession)
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            timerInterval = lastTimerInterval
            playbackOrder = PlaybackOrder(rawValue: lastPlaybackOrder) ?? .shuffle
            imageCount = min(20, board.images.count)
        }
    }

    // MARK: - Sections

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timer per image")
                .font(.headline)
            HStack(spacing: 8) {
                ForEach(presets, id: \.1) { label, seconds in
                    Button(label) {
                        timerInterval = seconds
                        isCustomTimer = false
                        customSeconds = ""
                    }
                    .buttonStyle(.bordered)
                    .tint(timerInterval == seconds && !isCustomTimer ? .orange : nil)
                }

                HStack(spacing: 4) {
                    TextField("sec", text: $customSeconds)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 56)
                        .onChange(of: customSeconds) {
                            if let secs = TimeInterval(customSeconds), secs > 0 {
                                timerInterval = secs
                                isCustomTimer = true
                            }
                        }
                    Text("s")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var orderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Playback order")
                .font(.headline)
            Picker("Order", selection: $playbackOrder) {
                Text("Shuffle").tag(PlaybackOrder.shuffle)
                Text("Sequential").tag(PlaybackOrder.sequential)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var imageCountSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Number of images")
                .font(.headline)
            Toggle("Use all images (\(board.images.count))", isOn: $useAllImages)
            if !useAllImages {
                Stepper(
                    "\(imageCount) image\(imageCount == 1 ? "" : "s")",
                    value: $imageCount,
                    in: 1...board.images.count
                )
            }
        }
    }

    // MARK: - Actions

    private func startSession() {
        lastTimerInterval = timerInterval
        lastPlaybackOrder = playbackOrder.rawValue

        let count = useAllImages ? board.images.count : min(imageCount, board.images.count)
        let sortedImages = board.images.sorted { $0.sortOrder < $1.sortOrder }
        let selectedImages = Array(sortedImages.prefix(count))

        let config = SessionConfiguration(
            boardId: board.id,
            boardName: board.name,
            images: selectedImages.map { .init(id: $0.id, filename: $0.filename) },
            timerInterval: timerInterval,
            playbackOrder: playbackOrder
        )

        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onStart(config)
        }
    }
}

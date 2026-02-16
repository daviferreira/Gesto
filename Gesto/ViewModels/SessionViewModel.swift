import Foundation

@MainActor
@Observable
class SessionViewModel {
    // Configuration
    let boardId: UUID
    let boardName: String
    let timerInterval: TimeInterval
    let playbackOrder: PlaybackOrder

    // State
    private(set) var images: [SessionConfiguration.ImageReference]
    private(set) var currentIndex: Int = 0
    private(set) var timeRemaining: TimeInterval
    private(set) var isPaused: Bool = false
    private(set) var isFinished: Bool = false

    // Session tracking
    let startedAt = Date()
    nonisolated(unsafe) private var timerTask: Task<Void, Never>?

    var currentImage: SessionConfiguration.ImageReference? {
        guard currentIndex < images.count else { return nil }
        return images[currentIndex]
    }

    var progress: Double {
        guard timerInterval > 0 else { return 0 }
        return 1.0 - (timeRemaining / timerInterval)
    }

    var completedAllImages: Bool {
        currentIndex >= images.count - 1 && timeRemaining <= 0
    }

    init(configuration: SessionConfiguration) {
        self.boardId = configuration.boardId
        self.boardName = configuration.boardName
        self.timerInterval = configuration.timerInterval
        self.playbackOrder = configuration.playbackOrder
        self.timeRemaining = configuration.timerInterval

        if configuration.playbackOrder == .shuffle {
            self.images = configuration.images.shuffled()
        } else {
            self.images = configuration.images
        }
    }

    func start() {
        startTimer()
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            timerTask?.cancel()
        } else {
            startTimer()
        }
    }

    func nextImage() {
        guard currentIndex < images.count - 1 else {
            finish()
            return
        }
        currentIndex += 1
        timeRemaining = timerInterval
        if !isPaused { startTimer() }
    }

    func previousImage() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        timeRemaining = timerInterval
        if !isPaused { startTimer() }
    }

    func finish() {
        timerTask?.cancel()
        isFinished = true
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask?.cancel()
        let startTime = Date()
        let startRemaining = timeRemaining

        timerTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(33))
                guard !Task.isCancelled, let self else { break }

                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = startRemaining - elapsed

                if remaining <= 0 {
                    self.timeRemaining = 0
                    self.nextImage()
                    break
                }
                self.timeRemaining = remaining
            }
        }
    }

    deinit {
        timerTask?.cancel()
    }
}

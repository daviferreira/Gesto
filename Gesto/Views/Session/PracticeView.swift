import SwiftUI

struct PracticeView: View {
    @State private var viewModel: SessionViewModel
    let onEnd: (SessionViewModel) -> Void

    @FocusState private var isFocused: Bool
    @State private var showingEndConfirmation = false

    init(configuration: SessionConfiguration, onEnd: @escaping (SessionViewModel) -> Void) {
        self.onEnd = onEnd
        _viewModel = State(initialValue: SessionViewModel(configuration: configuration))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Reference image
            if let current = viewModel.currentImage {
                FullImage(filename: current.filename, boardId: viewModel.boardId)
                    .id(current.id)
                    .transition(.opacity)
            }

            // UI overlay
            VStack {
                imageCounter
                Spacer()
                timerOverlay
            }
        }
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
        .onKeyPress(.space) {
            viewModel.togglePause()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            viewModel.nextImage()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            viewModel.previousImage()
            return .handled
        }
        .onKeyPress("d") {
            viewModel.nextImage()
            return .handled
        }
        .onKeyPress("a") {
            viewModel.previousImage()
            return .handled
        }
        .onKeyPress(.escape) {
            if viewModel.isFinished { return .ignored }
            showingEndConfirmation = true
            if !viewModel.isPaused { viewModel.togglePause() }
            return .handled
        }
        .onAppear {
            isFocused = true
            viewModel.start()
            enterFullScreen()
        }
        .onChange(of: viewModel.isFinished) {
            if viewModel.isFinished {
                exitFullScreen()
                onEnd(viewModel)
            }
        }
        .alert("End Session?", isPresented: $showingEndConfirmation) {
            Button("Continue") {
                viewModel.togglePause()
            }
            Button("End Session", role: .destructive) {
                viewModel.finish()
            }
        } message: {
            Text("Your session progress will be saved.")
        }
    }

    // MARK: - Overlay Components

    private var imageCounter: some View {
        HStack {
            Spacer()
            Text("\(viewModel.currentIndex + 1) / \(viewModel.images.count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        }
        .padding()
    }

    private var timerOverlay: some View {
        VStack(spacing: 4) {
            if viewModel.isPaused {
                Text("PAUSED")
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
            }

            Text(formatTime(viewModel.timeRemaining))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))

            TimerBar(progress: viewModel.progress)
                .frame(height: 3)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(ceil(seconds)))
        let mins = total / 60
        let secs = total % 60
        return mins > 0 ? String(format: "%d:%02d", mins, secs) : "\(secs)s"
    }

    private func enterFullScreen() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApp.keyWindow, !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }

    private func exitFullScreen() {
        if let window = NSApp.keyWindow, window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
    }
}

// MARK: - Full Resolution Image

private struct FullImage: View {
    let filename: String
    let boardId: UUID
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: filename) {
            let url = ImageStorageService.shared.imageURL(for: filename, boardId: boardId)
            image = NSImage(contentsOf: url)
        }
    }
}

import SwiftUI

struct PracticeView: View {
    @State private var viewModel: SessionViewModel
    let onEnd: (SessionViewModel) -> Void

    @FocusState private var isFocused: Bool
    @State private var showingEndConfirmation = false
    @State private var showingHelp = true

    init(configuration: SessionConfiguration, onEnd: @escaping (SessionViewModel) -> Void) {
        self.onEnd = onEnd
        _viewModel = State(initialValue: SessionViewModel(configuration: configuration))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Reference image with transforms
            if let current = viewModel.currentImage {
                FullImage(filename: current.filename, boardId: viewModel.boardId)
                    .grayscale(viewModel.isGrayscale ? 1.0 : 0)
                    .scaleEffect(
                        x: (viewModel.isFlippedHorizontal ? -1 : 1) * viewModel.zoomLevel,
                        y: (viewModel.isFlippedVertical ? -1 : 1) * viewModel.zoomLevel
                    )
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isGrayscale)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isFlippedHorizontal)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.isFlippedVertical)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.zoomLevel)
                    .id(current.id)
                    .transition(.opacity)
            }

            // UI overlay
            VStack {
                HStack {
                    transformIndicators
                    Spacer()
                    imageCounter
                }
                .padding()

                Spacer()
                timerOverlay
            }

            // Help overlay
            if showingHelp {
                controlsHelp
            }
        }
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentIndex)
        // Playback controls
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
        // Transform controls
        .onKeyPress("g") {
            viewModel.toggleGrayscale()
            return .handled
        }
        .onKeyPress("f") {
            viewModel.toggleFlipHorizontal()
            return .handled
        }
        .onKeyPress("v") {
            viewModel.toggleFlipVertical()
            return .handled
        }
        .onKeyPress("r") {
            viewModel.resetTransforms()
            return .handled
        }
        .onKeyPress("=") {
            viewModel.zoomIn()
            return .handled
        }
        .onKeyPress("+") {
            viewModel.zoomIn()
            return .handled
        }
        .onKeyPress("-") {
            viewModel.zoomOut()
            return .handled
        }
        .onKeyPress("?") {
            withAnimation { showingHelp.toggle() }
            return .handled
        }
        .onKeyPress("/") {
            withAnimation { showingHelp.toggle() }
            return .handled
        }
        // Session controls
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
            // Auto-dismiss help after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { showingHelp = false }
            }
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

    // MARK: - Controls Help

    private var controlsHelp: some View {
        VStack(spacing: 12) {
            Text("Keyboard Controls")
                .font(.headline)
                .foregroundStyle(.white)

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                shortcutRow("Space", "Pause / Resume")
                shortcutRow("\u{2190} \u{2192}  A D", "Previous / Next image")
                shortcutRow("G", "Toggle grayscale")
                shortcutRow("F", "Flip horizontal")
                shortcutRow("V", "Flip vertical")
                shortcutRow("+ / \u{2212}", "Zoom in / out")
                shortcutRow("R", "Reset transforms")
                shortcutRow("Esc", "End session")
                shortcutRow("?", "Toggle this help")
            }
        }
        .padding(24)
        .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 16))
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    private func shortcutRow(_ key: String, _ action: String) -> some View {
        GridRow {
            Text(key)
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundStyle(.orange)
                .frame(minWidth: 80, alignment: .trailing)
            Text(action)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Overlay Components

    private var transformIndicators: some View {
        HStack(spacing: 6) {
            if viewModel.isGrayscale {
                transformBadge("circle.lefthalf.striped.horizontal")
            }
            if viewModel.isFlippedHorizontal {
                transformBadge("arrow.left.and.right.righttriangle.left.righttriangle.right")
            }
            if viewModel.isFlippedVertical {
                transformBadge("arrow.up.and.down.righttriangle.up.righttriangle.down")
            }
            if viewModel.zoomLevel != 1.0 {
                Text("\(Int(viewModel.zoomLevel * 100))%")
                    .font(.caption2.monospacedDigit().bold())
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: viewModel.hasActiveTransforms)
    }

    private func transformBadge(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.caption2)
            .foregroundStyle(.orange.opacity(0.8))
            .padding(4)
            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 4))
    }

    private var imageCounter: some View {
        Text("\(viewModel.currentIndex + 1) / \(viewModel.images.count)")
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.6))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
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
            guard let window = NSApp.keyWindow else { return }
            window.toolbar?.isVisible = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            if !window.styleMask.contains(.fullScreen) {
                window.toggleFullScreen(nil)
            }
        }
    }

    private func exitFullScreen() {
        guard let window = NSApp.keyWindow else { return }
        if window.styleMask.contains(.fullScreen) {
            window.toggleFullScreen(nil)
        }
        window.toolbar?.isVisible = true
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.styleMask.remove(.fullSizeContentView)
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

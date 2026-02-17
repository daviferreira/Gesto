import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BoardDetailView: View {
    let boardId: UUID
    @Environment(\.modelContext) private var modelContext
    @Environment(\.startSession) private var startSession
    @Query private var boards: [Board]
    @State private var viewModel: BoardDetailViewModel?
    @State private var showingFilePicker = false
    @State private var showingSessionSetup = false
    @State private var selectedImages: Set<UUID> = []
    @State private var isDropTargeted = false
    @State private var draggingImageId: UUID?

    private var board: Board? { boards.first }

    private var sortedImages: [ReferenceImage] {
        board?.images.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 12)
    ]

    init(boardId: UUID) {
        self.boardId = boardId
        let id = boardId
        _boards = Query(filter: #Predicate<Board> { $0.id == id })
    }

    var body: some View {
        Group {
            if let board {
                boardContent(board)
                    .onAppear {
                        if viewModel == nil {
                            viewModel = BoardDetailViewModel(board: board, modelContext: modelContext)
                        }
                    }
            } else {
                ContentUnavailableView("Board Not Found", systemImage: "exclamationmark.triangle")
            }
        }
    }

    // MARK: - Board Content

    @ViewBuilder
    private func boardContent(_ board: Board) -> some View {
        ZStack {
            if board.images.isEmpty && viewModel?.isImporting != true {
                emptyState
            } else {
                imageGrid
            }
        }
        .navigationTitle(board.name)
        .toolbar { toolbarContent(board) }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            if let urls = try? result.get() {
                Task { await viewModel?.importImages(from: urls) }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers)
            return true
        }
        .overlay {
            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.orange, lineWidth: 3)
                    .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .padding(4)
                    .allowsHitTesting(false)
            }
        }
        .overlay {
            if viewModel?.isImporting == true {
                ProgressView("Importing images\u{2026}")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .sheet(isPresented: $showingSessionSetup) {
            if let b = self.board {
                SessionSetupSheet(board: b) { config in
                    startSession(config)
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "photo.badge.plus",
            title: "No images yet",
            message: "Add reference images or drop them here",
            buttonTitle: "Add Images"
        ) {
            showingFilePicker = true
        }
    }

    private var imageGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(sortedImages) { image in
                    ImageThumbnail(
                        image: image,
                        boardId: boardId,
                        isSelected: selectedImages.contains(image.id)
                    )
                    .opacity(draggingImageId == image.id ? 0.4 : 1.0)
                    .onTapGesture {
                        toggleSelection(image.id)
                    }
                    .contextMenu {
                        Button("Remove from Board", role: .destructive) {
                            Task { await viewModel?.deleteImages([image.id]) }
                        }
                    }
                    .draggable(image.id.uuidString) {
                        ImageThumbnail(
                            image: image,
                            boardId: boardId,
                            isSelected: false
                        )
                        .frame(width: 100, height: 100)
                        .onAppear { draggingImageId = image.id }
                    }
                    .dropDestination(for: String.self) { items, _ in
                        guard let droppedIdString = items.first,
                              let droppedId = UUID(uuidString: droppedIdString),
                              droppedId != image.id else { return false }
                        reorderImage(droppedId, before: image.id)
                        return true
                    } isTargeted: { targeted in
                        // Visual feedback handled by opacity
                    }
                }
            }
            .padding()
        }
        .onChange(of: draggingImageId) {
            // Reset after drag ends (small delay for drop to process)
            if draggingImageId != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    draggingImageId = nil
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbarContent(_ board: Board) -> some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if !selectedImages.isEmpty {
                Button(role: .destructive) {
                    let ids = selectedImages
                    selectedImages.removeAll()
                    Task { await viewModel?.deleteImages(ids) }
                } label: {
                    Label("Delete \(selectedImages.count)", systemImage: "trash")
                }
            }

            Button {
                showingFilePicker = true
            } label: {
                Label("Add Images", systemImage: "plus")
            }
            .keyboardShortcut("i", modifiers: .command)

            Button {
                showingSessionSetup = true
            } label: {
                Label("Start Session", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(board.images.isEmpty)
        }
    }

    // MARK: - Actions

    private func reorderImage(_ sourceId: UUID, before targetId: UUID) {
        var images = sortedImages
        guard let sourceIndex = images.firstIndex(where: { $0.id == sourceId }),
              let targetIndex = images.firstIndex(where: { $0.id == targetId }) else { return }

        let moved = images.remove(at: sourceIndex)
        images.insert(moved, at: targetIndex)

        for (index, image) in images.enumerated() {
            image.sortOrder = index
        }
        board?.updatedAt = Date()
        draggingImageId = nil
    }

    private func toggleSelection(_ id: UUID) {
        if selectedImages.contains(id) {
            selectedImages.remove(id)
        } else {
            selectedImages.insert(id)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) {
        Task {
            var urls: [URL] = []
            for provider in providers {
                if let url = await loadFileURL(from: provider) {
                    urls.append(url)
                }
            }
            guard !urls.isEmpty else { return }
            await viewModel?.importImages(from: urls)
        }
    }

    private func loadFileURL(from provider: NSItemProvider) async -> URL? {
        guard provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) else { return nil }
        return await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                if let data = item as? Data {
                    continuation.resume(returning: URL(dataRepresentation: data, relativeTo: nil))
                } else if let url = item as? URL {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

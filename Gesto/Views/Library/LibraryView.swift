import SwiftUI
import SwiftData

struct LibraryView: View {
    @Binding var navigationPath: NavigationPath
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Board.updatedAt, order: .reverse) private var boards: [Board]
    @State private var searchText = ""
    @State private var showingNewBoard = false
    @State private var boardToRename: Board?
    @State private var renameText = ""
    @State private var newBoardName = ""
    @State private var boardToDelete: Board?
    @FocusState private var isNewBoardFocused: Bool

    private var filteredBoards: [Board] {
        if searchText.isEmpty { return boards }
        return boards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 250), spacing: 16)
    ]

    var body: some View {
        Group {
            if boards.isEmpty && !showingNewBoard {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "Create your first board to get started",
                    message: "Organize your reference images into themed boards",
                    buttonTitle: "New Board"
                ) {
                    showNewBoardForm()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        // New board card
                        newBoardCard

                        ForEach(filteredBoards) { board in
                            NavigationLink(value: board.id) {
                                BoardCard(board: board)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Rename") {
                                    renameText = board.name
                                    boardToRename = board
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    boardToDelete = board
                                }
                            }
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText, prompt: "Filter boards")
            }
        }
        .navigationTitle("Library")
        .alert("Rename Board", isPresented: Binding(
            get: { boardToRename != nil },
            set: { if !$0 { boardToRename = nil } }
        )) {
            TextField("Board name", text: $renameText)
            Button("Cancel", role: .cancel) { boardToRename = nil }
            Button("Rename") { renameBoard() }
        }
        .alert("Delete Board?", isPresented: Binding(
            get: { boardToDelete != nil },
            set: { if !$0 { boardToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { boardToDelete = nil }
            Button("Delete", role: .destructive) { deleteBoard() }
        } message: {
            if let board = boardToDelete {
                Text("This will permanently delete \"\(board.name)\" and all its images.")
            }
        }
    }

    // MARK: - New Board Card

    private var newBoardCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    if showingNewBoard {
                        newBoardForm
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.title2.bold())
                                .foregroundStyle(.orange)
                            Text("New Board")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

            // Invisible spacer to match BoardCard height
            VStack(alignment: .leading, spacing: 2) {
                Text(" ").font(.headline)
                Text(" ").font(.caption)
            }
            .padding(.horizontal, 4)
            .opacity(0)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    showingNewBoard ? .orange : .secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: showingNewBoard ? 2 : 1.5, dash: showingNewBoard ? [] : [8, 4])
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !showingNewBoard {
                showNewBoardForm()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingNewBoard)
    }

    private var newBoardForm: some View {
        VStack(spacing: 12) {
            TextField("Board name...", text: $newBoardName)
                .textFieldStyle(.plain)
                .font(.body)
                .padding(8)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                .focused($isNewBoardFocused)
                .onSubmit(createBoard)
                .onExitCommand { cancelNewBoard() }

            HStack(spacing: 8) {
                Button("Cancel") { cancelNewBoard() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.caption)

                Button("Create") { createBoard() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    .font(.caption)
                    .disabled(newBoardName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Actions

    private func showNewBoardForm() {
        newBoardName = ""
        showingNewBoard = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNewBoardFocused = true
        }
    }

    private func cancelNewBoard() {
        showingNewBoard = false
        newBoardName = ""
    }

    private func createBoard() {
        let name = newBoardName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let board = Board(name: name)
        modelContext.insert(board)
        try? modelContext.save()
        showingNewBoard = false
        newBoardName = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            navigationPath.append(board.id)
        }
    }

    private func deleteBoard() {
        guard let board = boardToDelete else { return }
        modelContext.delete(board)
        boardToDelete = nil
    }

    private func renameBoard() {
        guard let board = boardToRename else { return }
        let name = renameText.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        board.name = name
        board.updatedAt = Date()
        boardToRename = nil
    }
}

#Preview("With boards") {
    NavigationStack {
        LibraryView(navigationPath: .constant(NavigationPath()))
    }
    .frame(width: 700, height: 500)
    .modelContainer(PreviewContainer().container)
}

#Preview("Empty") {
    NavigationStack {
        LibraryView(navigationPath: .constant(NavigationPath()))
    }
    .frame(width: 700, height: 500)
    .modelContainer(for: [Board.self, SessionRecord.self], inMemory: true)
}


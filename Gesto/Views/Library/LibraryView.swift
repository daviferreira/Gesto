import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Board.updatedAt, order: .reverse) private var boards: [Board]
    @State private var searchText = ""
    @State private var showingNewBoard = false
    @State private var boardToRename: Board?
    @State private var renameText = ""

    private var filteredBoards: [Board] {
        if searchText.isEmpty { return boards }
        return boards.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 180, maximum: 250), spacing: 16)
    ]

    var body: some View {
        Group {
            if boards.isEmpty {
                EmptyStateView(
                    icon: "photo.on.rectangle.angled",
                    title: "Create your first board to get started",
                    message: "Organize your reference images into themed boards",
                    buttonTitle: "New Board"
                ) {
                    showingNewBoard = true
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
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
                                    deleteBoard(board)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewBoard = true
                } label: {
                    Label("New Board", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingNewBoard) {
            NewBoardSheet()
        }
        .alert("Rename Board", isPresented: Binding(
            get: { boardToRename != nil },
            set: { if !$0 { boardToRename = nil } }
        )) {
            TextField("Board name", text: $renameText)
            Button("Cancel", role: .cancel) { boardToRename = nil }
            Button("Rename") { renameBoard() }
        }
    }

    private func deleteBoard(_ board: Board) {
        modelContext.delete(board)
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

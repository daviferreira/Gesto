import SwiftUI
import SwiftData

struct BoardDetailView: View {
    let boardId: UUID
    @Query private var allBoards: [Board]

    private var board: Board? {
        allBoards.first { $0.id == boardId }
    }

    var body: some View {
        if let board {
            Text("\(board.images.count) images")
                .font(.title3)
                .foregroundStyle(.secondary)
                .navigationTitle(board.name)
        } else {
            ContentUnavailableView("Board Not Found", systemImage: "exclamationmark.triangle")
        }
    }
}

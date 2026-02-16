import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Board.updatedAt, order: .reverse) private var boards: [Board]

    var body: some View {
        NavigationSplitView {
            List {
                Label("Library", systemImage: "square.grid.2x2")
                Label("History", systemImage: "clock")
            }
            .navigationTitle("Gesto")
        } detail: {
            if boards.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Create your first board to get started")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Select a board")
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.orange)
    }
}

import SwiftUI

enum SidebarItem: String, CaseIterable {
    case library = "Library"
    case history = "History"

    var icon: String {
        switch self {
        case .library: "square.grid.2x2"
        case .history: "clock"
        }
    }
}

struct ContentView: View {
    @State private var selectedSidebar: SidebarItem? = .library

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, id: \.self, selection: $selectedSidebar) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .navigationTitle("Gesto")
        } detail: {
            NavigationStack {
                Group {
                    switch selectedSidebar {
                    case .library, nil:
                        LibraryView()
                    case .history:
                        HistoryView()
                    }
                }
                .navigationDestination(for: UUID.self) { boardId in
                    BoardDetailView(boardId: boardId)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .tint(.orange)
    }
}

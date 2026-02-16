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
    @State private var activeSession: SessionConfiguration?

    var body: some View {
        ZStack {
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

            if let config = activeSession {
                PracticeView(configuration: config) { vm in
                    withAnimation {
                        activeSession = nil
                    }
                }
                .transition(.opacity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .tint(.orange)
        .environment(\.startSession) { config in
            withAnimation {
                activeSession = config
            }
        }
    }
}

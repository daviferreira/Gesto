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

enum SessionPhase {
    case idle
    case practicing(SessionConfiguration)
    case summary(config: SessionConfiguration, viewModel: SessionViewModel)
}

struct ContentView: View {
    @State private var selectedSidebar: SidebarItem? = .library
    @State private var sessionPhase: SessionPhase = .idle

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

            switch sessionPhase {
            case .idle:
                EmptyView()

            case .practicing(let config):
                PracticeView(configuration: config) { vm in
                    withAnimation {
                        sessionPhase = .summary(config: config, viewModel: vm)
                    }
                }
                .transition(.opacity)

            case .summary(let config, let vm):
                SessionSummaryView(
                    viewModel: vm,
                    onClose: {
                        withAnimation { sessionPhase = .idle }
                    },
                    onRestart: {
                        withAnimation { sessionPhase = .practicing(config) }
                    }
                )
                .transition(.opacity)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .tint(.orange)
        .environment(\.startSession) { config in
            withAnimation {
                sessionPhase = .practicing(config)
            }
        }
    }
}

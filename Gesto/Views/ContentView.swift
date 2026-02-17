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
    @State private var navigationPath = NavigationPath()

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // Fixed sidebar
                VStack(alignment: .leading, spacing: 0) {
                    Text("Gesto")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    ForEach(SidebarItem.allCases, id: \.self) { item in
                        Button {
                            selectedSidebar = item
                        } label: {
                            Label(item.rawValue, systemImage: item.icon)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    selectedSidebar == item
                                        ? .orange.opacity(0.15)
                                        : .clear,
                                    in: RoundedRectangle(cornerRadius: 6)
                                )
                                .foregroundStyle(selectedSidebar == item ? .orange : .primary)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 8)
                    }

                    Spacer()
                }
                .frame(width: 180)
                .background(.ultraThinMaterial)

                Divider()

                // Detail content
                NavigationStack(path: $navigationPath) {
                    Group {
                        switch selectedSidebar {
                        case .library, nil:
                            LibraryView(navigationPath: $navigationPath)
                        case .history:
                            HistoryView()
                        }
                    }
                    .navigationDestination(for: UUID.self) { boardId in
                        BoardDetailView(boardId: boardId)
                    }
                }
                .frame(maxWidth: .infinity)
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

#Preview {
    ContentView()
        .modelContainer(PreviewContainer().container)
        .preferredColorScheme(.dark)
}

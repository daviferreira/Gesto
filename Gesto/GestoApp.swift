import SwiftUI
import SwiftData

@main
struct GestoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear { configureWindow() }
        }
        .windowToolbarStyle(.unifiedCompact)
        .modelContainer(for: [Board.self, SessionRecord.self])
    }

    private func configureWindow() {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.titlebarAppearsTransparent = true
                window.titlebarSeparatorStyle = .none
            }
        }
    }
}

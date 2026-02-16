import SwiftUI
import SwiftData

@main
struct GestoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [Board.self, SessionRecord.self])
    }
}

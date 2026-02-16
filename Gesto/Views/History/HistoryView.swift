import SwiftUI

struct HistoryView: View {
    var body: some View {
        EmptyStateView(
            icon: "clock",
            title: "No sessions yet",
            message: "Complete a drawing session to see your history here"
        )
        .navigationTitle("History")
    }
}

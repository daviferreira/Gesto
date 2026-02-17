import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    var message: String? = nil
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.title)
                .foregroundStyle(.secondary)
            if let message {
                Text(message)
                    .font(.title3)
                    .foregroundStyle(.tertiary)
            }
            if let buttonTitle, let action {
                Button(action: action) {
                    Label(buttonTitle, systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("With button") {
    EmptyStateView(
        icon: "photo.on.rectangle.angled",
        title: "Create your first board",
        message: "Organize your reference images into themed boards",
        buttonTitle: "New Board"
    ) {}
    .frame(width: 500, height: 400)
}

#Preview("Without button") {
    EmptyStateView(
        icon: "clock",
        title: "No sessions yet",
        message: "Complete a drawing session to see your history here"
    )
    .frame(width: 500, height: 400)
}

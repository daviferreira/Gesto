import SwiftUI

struct NewBoardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var boardName = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 28))
                    .foregroundStyle(.orange)

                Text("New Board")
                    .font(.title3.bold())
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            // Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("e.g. Figure Drawing, Landscapes...", text: $boardName)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(10)
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    .focused($isNameFocused)
                    .onSubmit(createBoard)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                Button(action: createBoard) {
                    Text("Create Board")
                        .frame(maxWidth: .infinity)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(boardName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(width: 340)
        .onAppear { isNameFocused = true }
    }

    private func createBoard() {
        let name = boardName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let board = Board(name: name)
        modelContext.insert(board)
        dismiss()
    }
}

#Preview {
    NewBoardSheet()
        .modelContainer(for: Board.self, inMemory: true)
}

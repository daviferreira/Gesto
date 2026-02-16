import SwiftUI

struct NewBoardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var boardName = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("New Board")
                .font(.title2.bold())

            TextField("Board name", text: $boardName)
                .textFieldStyle(.roundedBorder)
                .focused($isNameFocused)
                .onSubmit(createBoard)

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Create", action: createBoard)
                    .keyboardShortcut(.defaultAction)
                    .disabled(boardName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 320)
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

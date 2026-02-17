import SwiftData
import SwiftUI

@MainActor
struct PreviewContainer {
    let container: ModelContainer

    init(withSampleData: Bool = true) {
        let schema = Schema([Board.self, SessionRecord.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: config)

        if withSampleData {
            addSampleData()
        }
    }

    private func addSampleData() {
        let context = container.mainContext

        let board1 = Board(name: "Figure Drawing")
        let board2 = Board(name: "Landscapes")
        let board3 = Board(name: "Hands & Feet")
        context.insert(board1)
        context.insert(board2)
        context.insert(board3)

        let img1 = ReferenceImage(filename: "sample1.jpg", fileHash: "abc123", width: 800, height: 1200, sortOrder: 0, focalY: 0.3)
        let img2 = ReferenceImage(filename: "sample2.jpg", fileHash: "def456", width: 1200, height: 800, sortOrder: 1, focalY: 0.5)
        let img3 = ReferenceImage(filename: "sample3.jpg", fileHash: "ghi789", width: 600, height: 900, sortOrder: 2, focalY: 0.4)
        img1.board = board1
        img2.board = board1
        img3.board = board1
        context.insert(img1)
        context.insert(img2)
        context.insert(img3)

        let record1 = SessionRecord(
            boardId: board1.id, boardName: "Figure Drawing",
            startedAt: Date().addingTimeInterval(-3600), endedAt: Date().addingTimeInterval(-1800),
            duration: 1800, imageCount: 12, timerInterval: 60,
            playbackOrder: .shuffle, completedAllImages: true
        )
        let record2 = SessionRecord(
            boardId: board2.id, boardName: "Landscapes",
            startedAt: Date().addingTimeInterval(-86400), endedAt: Date().addingTimeInterval(-85200),
            duration: 1200, imageCount: 8, timerInterval: 120,
            playbackOrder: .sequential, completedAllImages: false
        )
        context.insert(record1)
        context.insert(record2)
    }
}

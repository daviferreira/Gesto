import Foundation
import SwiftData

enum PlaybackOrder: String, Codable {
    case shuffle
    case sequential
}

@Model
final class SessionRecord {
    @Attribute(.unique) var id: UUID
    var boardId: UUID
    var boardName: String
    var startedAt: Date
    var endedAt: Date
    var duration: TimeInterval
    var imageCount: Int
    var timerInterval: TimeInterval
    var playbackOrder: PlaybackOrder
    var completedAllImages: Bool

    init(
        boardId: UUID,
        boardName: String,
        startedAt: Date,
        endedAt: Date,
        duration: TimeInterval,
        imageCount: Int,
        timerInterval: TimeInterval,
        playbackOrder: PlaybackOrder,
        completedAllImages: Bool
    ) {
        self.id = UUID()
        self.boardId = boardId
        self.boardName = boardName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.duration = duration
        self.imageCount = imageCount
        self.timerInterval = timerInterval
        self.playbackOrder = playbackOrder
        self.completedAllImages = completedAllImages
    }
}

import Foundation
import SwiftData

@Model
final class ReferenceImage {
    @Attribute(.unique) var id: UUID
    var filename: String
    var fileHash: String
    var width: Int
    var height: Int
    var addedAt: Date
    var sortOrder: Int
    var focalY: Double = 0.5

    var board: Board?

    init(filename: String, fileHash: String, width: Int, height: Int, sortOrder: Int = 0, focalY: Double = 0.5) {
        self.id = UUID()
        self.filename = filename
        self.fileHash = fileHash
        self.width = width
        self.height = height
        self.addedAt = Date()
        self.sortOrder = sortOrder
        self.focalY = focalY
    }
}

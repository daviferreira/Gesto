import Foundation
import SwiftData

@Model
final class Board {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ReferenceImage.board)
    var images: [ReferenceImage] = []

    init(name: String, color: String? = nil) {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

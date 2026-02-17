import Foundation
import SwiftData

@MainActor
@Observable
class BoardDetailViewModel {
    let board: Board
    private let modelContext: ModelContext
    private let storageService = ImageStorageService.shared

    var isImporting = false
    var importMessage: String?

    init(board: Board, modelContext: ModelContext) {
        self.board = board
        self.modelContext = modelContext
    }

    func importImages(from urls: [URL]) async {
        isImporting = true
        importMessage = nil

        let imageURLs = await storageService.collectImageURLs(from: urls)

        var imported = 0
        var duplicates = 0
        let existingHashes = Set(board.images.map(\.fileHash))

        for url in imageURLs {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            do {
                let result = try await storageService.importImage(from: url, boardId: board.id)

                if existingHashes.contains(result.fileHash) {
                    duplicates += 1
                    continue
                }

                let refImage = ReferenceImage(
                    filename: result.filename,
                    fileHash: result.fileHash,
                    width: result.width,
                    height: result.height,
                    sortOrder: board.images.count,
                    focalY: result.focalY
                )
                refImage.board = board
                modelContext.insert(refImage)
                board.updatedAt = Date()
                imported += 1
            } catch {
                print("Failed to import \(url.lastPathComponent): \(error)")
            }
        }

        isImporting = false
        if duplicates > 0 {
            importMessage = "\(imported) imported, \(duplicates) duplicate\(duplicates == 1 ? "" : "s") skipped"
        }
    }

    func deleteImages(_ imageIds: Set<UUID>) async {
        let imagesToDelete = board.images.filter { imageIds.contains($0.id) }
        for image in imagesToDelete {
            await storageService.deleteImage(filename: image.filename, boardId: board.id)
            modelContext.delete(image)
        }
        board.updatedAt = Date()
    }
}

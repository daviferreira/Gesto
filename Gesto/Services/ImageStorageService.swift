import Foundation
import CryptoKit
import UniformTypeIdentifiers
import ImageIO

actor ImageStorageService {
    static let shared = ImageStorageService()

    private let fileManager = FileManager.default
    private let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "webp", "tiff", "tif", "gif", "bmp"
    ]

    // MARK: - Directory Management

    private var baseDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Gesto/Images", isDirectory: true)
    }

    private var thumbnailBaseDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Gesto/Thumbnails", isDirectory: true)
    }

    private func boardDirectory(for boardId: UUID) -> URL {
        baseDirectory.appendingPathComponent(boardId.uuidString, isDirectory: true)
    }

    private func thumbnailDirectory(for boardId: UUID) -> URL {
        thumbnailBaseDirectory.appendingPathComponent(boardId.uuidString, isDirectory: true)
    }

    // MARK: - URL Helpers (nonisolated for synchronous access in views)

    nonisolated func imageURL(for filename: String, boardId: UUID) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("Gesto/Images", isDirectory: true)
            .appendingPathComponent(boardId.uuidString, isDirectory: true)
            .appendingPathComponent(filename)
    }

    nonisolated func thumbnailURL(for filename: String, boardId: UUID) -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let name = (filename as NSString).deletingPathExtension
        return appSupport
            .appendingPathComponent("Gesto/Thumbnails", isDirectory: true)
            .appendingPathComponent(boardId.uuidString, isDirectory: true)
            .appendingPathComponent("\(name)_thumb.jpg")
    }

    // MARK: - Import

    func importImage(from sourceURL: URL, boardId: UUID) throws -> ImportedImage {
        let boardDir = boardDirectory(for: boardId)
        try fileManager.createDirectory(at: boardDir, withIntermediateDirectories: true)

        let data = try Data(contentsOf: sourceURL)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()

        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any],
              let width = properties[kCGImagePropertyPixelWidth as String] as? Int,
              let height = properties[kCGImagePropertyPixelHeight as String] as? Int else {
            throw ImageStorageError.invalidImage
        }

        let ext = sourceURL.pathExtension.lowercased()
        let filename = "\(hash).\(ext.isEmpty ? "jpg" : ext)"
        let destinationURL = boardDir.appendingPathComponent(filename)

        if !fileManager.fileExists(atPath: destinationURL.path) {
            try data.write(to: destinationURL)
        }

        try generateThumbnail(from: imageSource, filename: filename, boardId: boardId)

        return ImportedImage(filename: filename, fileHash: hash, width: width, height: height)
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnail(from imageSource: CGImageSource, filename: String, boardId: UUID) throws {
        let thumbDir = thumbnailDirectory(for: boardId)
        try fileManager.createDirectory(at: thumbDir, withIntermediateDirectories: true)

        let thumbURL = thumbnailURL(for: filename, boardId: boardId)
        guard !fileManager.fileExists(atPath: thumbURL.path) else { return }

        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: 300,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]

        guard let cgThumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else { return }

        guard let destination = CGImageDestinationCreateWithURL(
            thumbURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return }

        CGImageDestinationAddImage(destination, cgThumbnail, [
            kCGImageDestinationLossyCompressionQuality: 0.8
        ] as CFDictionary)
        CGImageDestinationFinalize(destination)
    }

    // MARK: - Delete

    func deleteImage(filename: String, boardId: UUID) {
        let imgURL = imageURL(for: filename, boardId: boardId)
        let thumbURL = thumbnailURL(for: filename, boardId: boardId)
        try? fileManager.removeItem(at: imgURL)
        try? fileManager.removeItem(at: thumbURL)
    }

    func deleteBoardFiles(boardId: UUID) {
        let boardDir = boardDirectory(for: boardId)
        let thumbDir = thumbnailDirectory(for: boardId)
        try? fileManager.removeItem(at: boardDir)
        try? fileManager.removeItem(at: thumbDir)
    }

    // MARK: - Collect URLs (handles folders recursively)

    func collectImageURLs(from urls: [URL]) -> [URL] {
        var result: [URL] = []

        for url in urls {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue {
                if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
                    for case let fileURL as URL in enumerator {
                        if supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                            result.append(fileURL)
                        }
                    }
                }
            } else if supportedExtensions.contains(url.pathExtension.lowercased()) {
                result.append(url)
            }
        }

        return result
    }
}

// MARK: - Supporting Types

enum ImageStorageError: LocalizedError {
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidImage: "The file is not a valid image"
        }
    }
}

struct ImportedImage: Sendable {
    let filename: String
    let fileHash: String
    let width: Int
    let height: Int
}

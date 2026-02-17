import SwiftUI

struct ImageThumbnail: View {
    let image: ReferenceImage
    let boardId: UUID
    let isSelected: Bool

    @State private var thumbnail: NSImage?

    var body: some View {
        FocalImage(nsImage: thumbnail, focalY: image.focalY)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.orange, lineWidth: 3)
                }
            }
            .overlay {
                if thumbnail == nil {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .overlay { ProgressView().controlSize(.small) }
                }
            }
            .contentShape(Rectangle())
            .task(id: image.id) {
                await loadThumbnail()
            }
    }

    private func loadThumbnail() async {
        let service = ImageStorageService.shared
        let thumbURL = service.thumbnailURL(for: image.filename, boardId: boardId)

        if let loaded = NSImage(contentsOf: thumbURL) {
            thumbnail = loaded
            return
        }

        let fullURL = service.imageURL(for: image.filename, boardId: boardId)
        thumbnail = NSImage(contentsOf: fullURL)
    }
}

/// Displays an image using `.fill` mode with a vertical offset based on focalY so faces stay in frame.
struct FocalImage: View {
    let nsImage: NSImage?
    let focalY: Double

    var body: some View {
        GeometryReader { geo in
            if let nsImage {
                let imageSize = nsImage.size
                let scaleX = geo.size.width / imageSize.width
                let scaleY = geo.size.height / imageSize.height
                let scale = max(scaleX, scaleY)
                let scaledH = imageSize.height * scale
                let overflow = scaledH - geo.size.height

                if overflow > 1 {
                    // Image is taller than frame — shift vertically to keep focal point visible
                    let focalPixel = focalY * scaledH
                    let desiredOffset = (geo.size.height / 2) - focalPixel
                    let clamped = min(0, max(-overflow, desiredOffset))

                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .offset(y: clamped)
                } else {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .clipped()
    }
}

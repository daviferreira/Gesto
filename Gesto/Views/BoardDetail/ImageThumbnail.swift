import SwiftUI

struct ImageThumbnail: View {
    let image: ReferenceImage
    let boardId: UUID
    let isSelected: Bool

    @State private var thumbnail: NSImage?

    var body: some View {
        ZStack {
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .overlay { ProgressView().controlSize(.small) }
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.orange, lineWidth: 3)
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

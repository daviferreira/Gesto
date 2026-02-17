import SwiftUI

struct BoardCard: View {
    let board: Board

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    if let firstImage = board.images.sorted(by: { $0.sortOrder < $1.sortOrder }).first {
                        CardThumbnail(image: firstImage, boardId: board.id)
                    } else {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(board.name)
                    .font(.title3)
                    .lineLimit(1)
                Text("\(board.images.count) image\(board.images.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    @Previewable @State var board = Board(name: "Figure Drawing")
    BoardCard(board: board)
        .frame(width: 220)
        .modelContainer(for: Board.self, inMemory: true)
}

private struct CardThumbnail: View {
    let image: ReferenceImage
    let boardId: UUID
    @State private var nsImage: NSImage?

    var body: some View {
        FocalImage(nsImage: nsImage, focalY: image.focalY)
            .task {
                let thumbURL = ImageStorageService.shared.thumbnailURL(for: image.filename, boardId: boardId)
                nsImage = NSImage(contentsOf: thumbURL)
            }
    }
}

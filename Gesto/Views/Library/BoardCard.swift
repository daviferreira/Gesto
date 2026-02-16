import SwiftUI

struct BoardCard: View {
    let board: Board

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.quaternary)
                .aspectRatio(4 / 3, contentMode: .fit)
                .overlay {
                    if board.images.isEmpty {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    } else {
                        thumbnailMosaic
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(board.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(board.images.count) image\(board.images.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var thumbnailMosaic: some View {
        let imageCount = min(board.images.count, 4)
        if imageCount == 1 {
            Image(systemName: "photo.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        } else {
            Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                GridRow {
                    imagePlaceholder
                    if imageCount > 1 { imagePlaceholder }
                }
                if imageCount > 2 {
                    GridRow {
                        imagePlaceholder
                        if imageCount > 3 { imagePlaceholder }
                    }
                }
            }
        }
    }

    private var imagePlaceholder: some View {
        Rectangle()
            .fill(.tertiary)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
    }
}

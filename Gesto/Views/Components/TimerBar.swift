import SwiftUI

struct TimerBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(.white.opacity(0.15))
                Rectangle()
                    .fill(.orange)
                    .frame(width: geo.size.width * min(max(progress, 0), 1))
                    .animation(.linear(duration: 0.05), value: progress)
            }
        }
        .clipShape(Capsule())
    }
}

import SwiftUI

struct SessionConfiguration {
    let boardId: UUID
    let boardName: String
    let images: [ImageReference]
    let timerInterval: TimeInterval
    let playbackOrder: PlaybackOrder

    struct ImageReference {
        let id: UUID
        let filename: String
    }
}

// MARK: - Environment Key

private struct StartSessionKey: EnvironmentKey {
    static let defaultValue: (SessionConfiguration) -> Void = { _ in }
}

extension EnvironmentValues {
    var startSession: (SessionConfiguration) -> Void {
        get { self[StartSessionKey.self] }
        set { self[StartSessionKey.self] = newValue }
    }
}

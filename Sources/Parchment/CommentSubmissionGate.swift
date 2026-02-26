import Foundation

@MainActor
final class CommentSubmissionGate {
    private var isLocked = false

    func run(_ action: () -> Void) {
        guard !isLocked else { return }
        isLocked = true
        action()
        DispatchQueue.main.async { [weak self] in
            self?.isLocked = false
        }
    }
}

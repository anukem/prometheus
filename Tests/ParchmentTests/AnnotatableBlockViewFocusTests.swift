import XCTest
@testable import Parchment

@MainActor
final class AnnotatableBlockViewFocusTests: XCTestCase {
    func testOpeningCommentComposerRequestsInputFocus() {
        var state = AnnotatableBlockView.CommentComposerState()

        state.openComposer()

        XCTAssertTrue(state.shouldFocusInput)
    }

    func testSubmittingCommentClearsRequestedInputFocus() {
        var state = AnnotatableBlockView.CommentComposerState()
        state.openComposer()

        state.finishComposerSession()

        XCTAssertFalse(state.shouldFocusInput)
    }
}

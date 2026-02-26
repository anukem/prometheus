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

    func testEscapeKeyClosesCommentComposerSession() {
        var state = AnnotatableBlockView.CommentComposerState()
        state.openComposer()

        let shouldClose = state.handleKeyPress(.escape)

        XCTAssertTrue(shouldClose)
        XCTAssertFalse(state.shouldFocusInput)
    }

    func testNonEscapeKeyDoesNotCloseCommentComposerSession() {
        var state = AnnotatableBlockView.CommentComposerState()
        state.openComposer()

        let shouldClose = state.handleKeyPress(.enter)

        XCTAssertFalse(shouldClose)
        XCTAssertTrue(state.shouldFocusInput)
    }
}

import XCTest
@testable import Parchment

final class AnnotatableBlockViewTests: XCTestCase {
    func testCommentKeyboardActionRequestsInputFocus() {
        XCTAssertTrue(commentKeyboardActionShouldFocusInput())
    }

    func testShouldHandleBlockActionRequestReturnsTrueForMatchingNewToken() {
        let request = BlockKeyboardActionRequest(token: 10, blockIndex: 3, action: .comment)
        XCTAssertTrue(
            shouldHandleBlockActionRequest(
                request: request,
                blockIndex: 3,
                lastHandledToken: 9
            )
        )
    }

    func testShouldHandleBlockActionRequestRejectsDuplicateToken() {
        let request = BlockKeyboardActionRequest(token: 10, blockIndex: 3, action: .comment)
        XCTAssertFalse(
            shouldHandleBlockActionRequest(
                request: request,
                blockIndex: 3,
                lastHandledToken: 10
            )
        )
    }

    func testShouldHandleBlockActionRequestRejectsDifferentBlock() {
        let request = BlockKeyboardActionRequest(token: 10, blockIndex: 4, action: .delete)
        XCTAssertFalse(
            shouldHandleBlockActionRequest(
                request: request,
                blockIndex: 3,
                lastHandledToken: nil
            )
        )
    }

    func testShouldHandleBlockActionRequestRejectsNilRequest() {
        XCTAssertFalse(
            shouldHandleBlockActionRequest(
                request: nil,
                blockIndex: 1,
                lastHandledToken: nil
            )
        )
    }
}

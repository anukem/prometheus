import XCTest
@testable import Parchment

final class ReaderScrollBehaviorTests: XCTestCase {
    func testKeyboardNavigationDoesNotScrollWhenTargetBlockIsAlreadyVisible() {
        let currentOffset: CGFloat = 300
        let viewportHeight: CGFloat = 400
        let contentHeight: CGFloat = 2_000
        let visibleBlockMinY: CGFloat = 450

        let targetOffset = targetOffsetForKeyboardBlockNavigation(
            blockMinY: visibleBlockMinY,
            currentOffset: currentOffset,
            viewportHeight: viewportHeight,
            contentHeight: contentHeight
        )

        XCTAssertEqual(
            targetOffset,
            currentOffset,
            "Expected no scroll when navigating to a block already visible in the viewport."
        )
    }
}

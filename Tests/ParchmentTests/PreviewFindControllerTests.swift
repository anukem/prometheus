import XCTest
@testable import Parchment

final class PreviewFindControllerTests: XCTestCase {

    func testShowMakesVisible() {
        let controller = PreviewFindController()
        XCTAssertFalse(controller.isVisible)

        controller.show()

        XCTAssertTrue(controller.isVisible)
    }

    func testDismissHidesAndResetsState() {
        let controller = PreviewFindController()
        controller.show()
        controller.query = "hello"
        controller.updateSearch(source: "hello world")
        XCTAssertTrue(controller.isVisible)
        XCTAssertEqual(controller.engine.matchCount, 1)

        controller.dismiss()

        XCTAssertFalse(controller.isVisible)
        XCTAssertEqual(controller.query, "")
        XCTAssertEqual(controller.engine.matchCount, 0)
    }

    func testUpdateSearchPopulatesEngine() {
        let controller = PreviewFindController()
        controller.query = "text"
        controller.updateSearch(source: "# Heading\n\nSome text here\n\nMore text")

        XCTAssertEqual(controller.engine.matchCount, 2)
        XCTAssertEqual(controller.engine.currentMatch, PreviewFindMatch(blockIndex: 1))
    }

    func testNextAndPreviousNavigateMatches() {
        let controller = PreviewFindController()
        controller.query = "a"
        controller.updateSearch(source: "a cat\n\na bat")

        XCTAssertEqual(controller.engine.currentIndex, 0)

        controller.nextMatch()
        XCTAssertEqual(controller.engine.currentIndex, 1)

        controller.nextMatch()
        XCTAssertEqual(controller.engine.currentIndex, 2)

        controller.previousMatch()
        XCTAssertEqual(controller.engine.currentIndex, 1)
    }

    func testNavigationChangesCurrentIndexEvenWithinSameBlock() {
        let controller = PreviewFindController()
        controller.query = "a"
        controller.updateSearch(source: "a banana")
        // 4 matches all in block 0
        XCTAssertEqual(controller.engine.matchCount, 4)
        let initialIndex = controller.engine.currentIndex

        controller.nextMatch()
        XCTAssertNotEqual(controller.engine.currentIndex, initialIndex,
            "currentIndex must change so scroll deduplication sees a new value")
        XCTAssertEqual(controller.engine.currentMatch?.blockIndex, 0,
            "Block should stay the same for same-block matches")
    }

    func testShowCalledTwiceRemainsVisible() {
        let controller = PreviewFindController()
        controller.show()
        controller.query = "test"
        controller.show()

        XCTAssertTrue(controller.isVisible)
        XCTAssertEqual(controller.query, "test", "Second show should not reset query")
    }

    func testPerformFindSetsControllerVisible() {
        let controller = PreviewFindController()
        let recorder = ActionRecorder()

        FindCommandRouting.performFind(previewFindController: controller, sendAction: recorder.send)

        XCTAssertTrue(controller.isVisible)
        XCTAssertTrue(recorder.invocations.isEmpty)
    }

    func testPerformFindWithNilControllerUsesResponderChain() {
        let recorder = ActionRecorder(resultBySelector: [
            FindCommandRouting.showFindInterfaceSelectorString: true
        ])

        FindCommandRouting.performFind(previewFindController: nil, sendAction: recorder.send)

        XCTAssertFalse(recorder.invocations.isEmpty)
    }
}

private final class ActionRecorder {
    private let resultBySelector: [String: Bool]
    private(set) var invocations: [String] = []

    init(resultBySelector: [String: Bool] = [:]) {
        self.resultBySelector = resultBySelector
    }

    func send(_ selector: Selector) -> Bool {
        let selectorName = NSStringFromSelector(selector)
        invocations.append(selectorName)
        return resultBySelector[selectorName] ?? false
    }
}

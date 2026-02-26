import XCTest
@testable import Parchment

@MainActor
final class CommentSubmissionGateTests: XCTestCase {
    func testRunBlocksImmediateDuplicateSubmission() {
        let gate = CommentSubmissionGate()
        var executionCount = 0

        gate.run { executionCount += 1 }
        gate.run { executionCount += 1 }

        XCTAssertEqual(executionCount, 1)
    }

    func testRunAllowsSubmissionAfterNextRunLoopTick() async {
        let gate = CommentSubmissionGate()
        var executionCount = 0

        gate.run { executionCount += 1 }
        gate.run { executionCount += 1 }
        XCTAssertEqual(executionCount, 1)

        let unlocked = expectation(description: "gate unlocks on next main queue turn")
        DispatchQueue.main.async {
            unlocked.fulfill()
        }
        await fulfillment(of: [unlocked], timeout: 1.0)

        gate.run { executionCount += 1 }
        XCTAssertEqual(executionCount, 2)
    }
}

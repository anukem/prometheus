import XCTest
@testable import Parchment

final class PreviewFindEngineTests: XCTestCase {

    // MARK: - Search basics

    func testEmptyQueryProducesNoMatches() {
        var engine = PreviewFindEngine()
        engine.search(query: "", in: ["Hello world"])
        XCTAssertEqual(engine.matchCount, 0)
        XCTAssertNil(engine.currentMatch)
    }

    func testNoMatchesWhenQueryAbsent() {
        var engine = PreviewFindEngine()
        engine.search(query: "xyz", in: ["Hello world", "Another block"])
        XCTAssertEqual(engine.matchCount, 0)
        XCTAssertNil(engine.currentMatch)
    }

    func testSingleMatchInOneBlock() {
        var engine = PreviewFindEngine()
        engine.search(query: "world", in: ["Hello world"])
        XCTAssertEqual(engine.matchCount, 1)
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 0))
    }

    func testMultipleMatchesAcrossBlocks() {
        var engine = PreviewFindEngine()
        engine.search(query: "text", in: ["Some text here", "No match", "More text and text"])
        XCTAssertEqual(engine.matchCount, 3)
        XCTAssertEqual(engine.matches, [
            PreviewFindMatch(blockIndex: 0),
            PreviewFindMatch(blockIndex: 2),
            PreviewFindMatch(blockIndex: 2),
        ])
    }

    func testSearchIsCaseInsensitive() {
        var engine = PreviewFindEngine()
        engine.search(query: "hello", in: ["Hello HELLO hElLo"])
        XCTAssertEqual(engine.matchCount, 3)
    }

    // MARK: - Navigation

    func testNextMatchAdvancesAndWraps() {
        var engine = PreviewFindEngine()
        engine.search(query: "a", in: ["a cat", "a bat"])
        // Starts at index 0 (first "a" in block 0)
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 0))

        engine.nextMatch()
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 0)) // "a" in "cat"

        engine.nextMatch()
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 1)) // "a" in block 1

        engine.nextMatch()
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 1)) // "a" in "bat"

        // Wraps to start
        engine.nextMatch()
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 0))
    }

    func testPreviousMatchGoesBackAndWraps() {
        var engine = PreviewFindEngine()
        engine.search(query: "x", in: ["x", "xx"])
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 0))

        // Wrap to last
        engine.previousMatch()
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 1))

        engine.previousMatch()
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 1))

        engine.previousMatch()
        XCTAssertEqual(engine.currentMatch, PreviewFindMatch(blockIndex: 0))
    }

    func testNewSearchResetsCurrent() {
        var engine = PreviewFindEngine()
        engine.search(query: "a", in: ["a", "a"])
        engine.nextMatch()
        XCTAssertEqual(engine.currentIndex, 1)

        engine.search(query: "a", in: ["a", "a"])
        XCTAssertEqual(engine.currentIndex, 0)
    }

    func testNavigationWithNoMatchesIsNoOp() {
        var engine = PreviewFindEngine()
        engine.search(query: "missing", in: ["hello"])
        engine.nextMatch()
        XCTAssertNil(engine.currentMatch)
        engine.previousMatch()
        XCTAssertNil(engine.currentMatch)
    }

    // MARK: - Navigation produces distinct currentIndex for scroll tracking

    func testNavigationWithinSameBlockChangesCurrentIndex() {
        // Two matches in the same block must have different currentIndex values
        // so the scroll-to-match logic fires on every navigation step.
        var engine = PreviewFindEngine()
        engine.search(query: "a", in: ["a banana"])
        XCTAssertEqual(engine.matchCount, 4) // "a", "a" in ban, "a" in nan, "a" final
        XCTAssertEqual(engine.currentIndex, 0)

        engine.nextMatch()
        XCTAssertEqual(engine.currentIndex, 1)
        XCTAssertEqual(engine.currentMatch?.blockIndex, 0, "Still same block")

        engine.nextMatch()
        XCTAssertEqual(engine.currentIndex, 2)
        XCTAssertEqual(engine.currentMatch?.blockIndex, 0, "Still same block")
    }

    func testEveryNavigationStepProducesUniqueIndexBlockPair() {
        // Simulates what the scroll deduplication checks:
        // (currentIndex, blockIndex) must differ on every next/previous call
        // within one full cycle (before wrapping).
        var engine = PreviewFindEngine()
        engine.search(query: "x", in: ["x x", "x"])
        XCTAssertEqual(engine.matchCount, 3)

        var seen: Set<String> = ["\(engine.currentIndex)-\(engine.currentMatch!.blockIndex)"]

        // Navigate matchCount - 1 times (stops just before wrapping back to start)
        for _ in 0..<(engine.matchCount - 1) {
            engine.nextMatch()
            let key = "\(engine.currentIndex)-\(engine.currentMatch!.blockIndex)"
            XCTAssertFalse(seen.contains(key), "Duplicate (index, block) pair: \(key)")
            seen.insert(key)
        }

        XCTAssertEqual(seen.count, engine.matchCount)
    }

    // MARK: - Empty blocks

    func testEmptyBlocksAreSkipped() {
        var engine = PreviewFindEngine()
        engine.search(query: "hi", in: ["", "hi there", "", "say hi"])
        XCTAssertEqual(engine.matchCount, 2)
        XCTAssertEqual(engine.matches[0].blockIndex, 1)
        XCTAssertEqual(engine.matches[1].blockIndex, 3)
    }
}

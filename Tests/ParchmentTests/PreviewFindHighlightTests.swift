import XCTest
@testable import Parchment

final class PreviewFindHighlightTests: XCTestCase {

    func testEmptyQueryReturnsAllSegmentsUnhighlighted() {
        let segments = highlightSegments("Hello world", query: "")
        XCTAssertEqual(segments, [HighlightSegment(text: "Hello world", isHighlighted: false)])
    }

    func testNoMatchReturnsAllSegmentsUnhighlighted() {
        let segments = highlightSegments("Hello world", query: "xyz")
        XCTAssertEqual(segments, [HighlightSegment(text: "Hello world", isHighlighted: false)])
    }

    func testSingleMatchAtStart() {
        let segments = highlightSegments("Hello world", query: "Hello")
        XCTAssertEqual(segments, [
            HighlightSegment(text: "Hello", isHighlighted: true),
            HighlightSegment(text: " world", isHighlighted: false),
        ])
    }

    func testSingleMatchAtEnd() {
        let segments = highlightSegments("Hello world", query: "world")
        XCTAssertEqual(segments, [
            HighlightSegment(text: "Hello ", isHighlighted: false),
            HighlightSegment(text: "world", isHighlighted: true),
        ])
    }

    func testMultipleMatches() {
        let segments = highlightSegments("ab ab ab", query: "ab")
        XCTAssertEqual(segments, [
            HighlightSegment(text: "ab", isHighlighted: true),
            HighlightSegment(text: " ", isHighlighted: false),
            HighlightSegment(text: "ab", isHighlighted: true),
            HighlightSegment(text: " ", isHighlighted: false),
            HighlightSegment(text: "ab", isHighlighted: true),
        ])
    }

    func testCaseInsensitiveMatch() {
        let segments = highlightSegments("Hello HELLO hello", query: "hello")
        XCTAssertEqual(segments.filter { $0.isHighlighted }.count, 3)
        // Original casing is preserved in segment text
        XCTAssertEqual(segments[0].text, "Hello")
        XCTAssertEqual(segments[2].text, "HELLO")
        XCTAssertEqual(segments[4].text, "hello")
    }

    func testEntireStringMatches() {
        let segments = highlightSegments("abc", query: "abc")
        XCTAssertEqual(segments, [HighlightSegment(text: "abc", isHighlighted: true)])
    }

    func testAdjacentMatches() {
        let segments = highlightSegments("aaa", query: "a")
        XCTAssertEqual(segments, [
            HighlightSegment(text: "a", isHighlighted: true),
            HighlightSegment(text: "a", isHighlighted: true),
            HighlightSegment(text: "a", isHighlighted: true),
        ])
    }
}

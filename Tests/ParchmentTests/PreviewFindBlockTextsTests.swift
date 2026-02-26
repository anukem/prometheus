import XCTest
@testable import Parchment

final class PreviewFindBlockTextsTests: XCTestCase {

    func testExtractsBlockTextsFromMarkdown() {
        let source = """
        # Title

        Some paragraph text.

        Another paragraph.
        """
        let texts = PreviewFindController.blockTexts(from: source)
        XCTAssertEqual(texts.count, 3)
        XCTAssertEqual(texts[0], "Title")
        XCTAssertEqual(texts[1], "Some paragraph text.")
        XCTAssertEqual(texts[2], "Another paragraph.")
    }

    func testCodeBlockTextIsExtracted() {
        let source = """
        ```swift
        let x = 1
        ```
        """
        let texts = PreviewFindController.blockTexts(from: source)
        XCTAssertEqual(texts.count, 1)
        XCTAssertTrue(texts[0].contains("let x = 1"))
    }

    func testEmptySourceReturnsNoBlocks() {
        let texts = PreviewFindController.blockTexts(from: "")
        XCTAssertTrue(texts.isEmpty)
    }
}

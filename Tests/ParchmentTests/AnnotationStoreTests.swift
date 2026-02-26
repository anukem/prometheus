import XCTest
@testable import Parchment

@MainActor
final class AnnotationStoreTests: XCTestCase {
    func testAddCommentIfNotBlankRejectsWhitespaceOnly() {
        let store = AnnotationStore()
        let blockId = BlockIdentifier(blockIndex: 0, contentPrefix: "Block")

        let didAdd = store.addCommentIfNotBlank(blockId: blockId, text: "   \n\t  ")

        XCTAssertFalse(didAdd)
        XCTAssertEqual(store.annotations.count, 0)
        XCTAssertEqual(store.version, 0)
    }

    func testAddCommentIfNotBlankTrimsAndAppendsComment() {
        let store = AnnotationStore()
        let blockId = BlockIdentifier(blockIndex: 3, contentPrefix: "Target")

        let didAdd = store.addCommentIfNotBlank(blockId: blockId, text: "  looks good  \n")

        XCTAssertTrue(didAdd)
        XCTAssertEqual(store.annotations.count, 1)
        XCTAssertEqual(store.version, 1)
        XCTAssertEqual(store.annotations.first?.type, .comment)
        XCTAssertEqual(store.annotations.first?.blockId, blockId)
        XCTAssertEqual(store.annotations.first?.comment, "looks good")
    }
}

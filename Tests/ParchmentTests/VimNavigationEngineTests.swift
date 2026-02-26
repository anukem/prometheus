import XCTest
@testable import Parchment

final class VimNavigationEngineTests: XCTestCase {
    func testParseVimNavigationCommandMapsSupportedKeys() {
        XCTAssertEqual(parseVimNavigationCommand("j"), .moveDown)
        XCTAssertEqual(parseVimNavigationCommand("k"), .moveUp)
        XCTAssertEqual(parseVimNavigationCommand("c"), .comment)
        XCTAssertEqual(parseVimNavigationCommand("d"), .delete)
        XCTAssertEqual(parseVimNavigationCommand("\r"), .selectCurrent)
    }

    func testParseVimNavigationCommandIsCaseInsensitive() {
        XCTAssertEqual(parseVimNavigationCommand("J"), .moveDown)
        XCTAssertEqual(parseVimNavigationCommand("K"), .moveUp)
    }

    func testParseVimNavigationCommandRejectsUnknownKeys() {
        XCTAssertNil(parseVimNavigationCommand("x"))
        XCTAssertNil(parseVimNavigationCommand(" "))
        XCTAssertNil(parseVimNavigationCommand(""))
    }

    func testMoveDownFromNilSelectsFirstBlock() {
        var engine = VimNavigationEngine(blockCount: 3)
        let action = engine.handle(.moveDown)
        XCTAssertEqual(action, .moveSelection(to: 0))
        XCTAssertEqual(engine.selectedBlockIndex, 0)
        XCTAssertFalse(engine.isBlockSelected)
    }

    func testMoveRespectsBounds() {
        var engine = VimNavigationEngine(blockCount: 2)
        _ = engine.handle(.moveDown)
        _ = engine.handle(.moveDown)
        let action = engine.handle(.moveDown)
        XCTAssertEqual(action, .none)
        XCTAssertEqual(engine.selectedBlockIndex, 1)
    }

    func testEnterSelectsCurrentBlock() {
        var engine = VimNavigationEngine(blockCount: 4)
        _ = engine.handle(.moveDown)
        let action = engine.handle(.selectCurrent)
        XCTAssertEqual(action, .selectBlock(0))
        XCTAssertTrue(engine.isBlockSelected)
    }

    func testCommentUsesCurrentBlockWithoutEnter() {
        var engine = VimNavigationEngine(blockCount: 4)
        _ = engine.handle(.moveDown)
        XCTAssertEqual(engine.handle(.comment), .commentBlock(0))
    }

    func testDeleteUsesCurrentBlockWithoutEnter() {
        var engine = VimNavigationEngine(blockCount: 4)
        _ = engine.handle(.moveDown)
        XCTAssertEqual(engine.handle(.delete), .deleteBlock(0))
    }
}

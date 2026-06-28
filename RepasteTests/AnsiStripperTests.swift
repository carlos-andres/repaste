import XCTest
import RepasteCore

final class AnsiStripperTests: XCTestCase {
    private let stage = AnsiStripper()
    private func clean(_ s: String) -> String { stage.apply(s, .default) }

    func testStripsSGRColor() {
        XCTAssertEqual(clean("\u{1B}[31mred\u{1B}[0m"), "red")
    }

    func testStripsCursorControl() {
        XCTAssertEqual(clean("\u{1B}[2Jcleared"), "cleared")
    }

    func testStripsBracketedPaste() {
        XCTAssertEqual(clean("\u{1B}[200~pasted\u{1B}[201~"), "pasted")
    }

    func testOSC8KeepsLinkTextDropsURL() {
        let input = "\u{1B}]8;;https://example.com\u{1B}\\link text\u{1B}]8;;\u{1B}\\"
        XCTAssertEqual(clean(input), "link text")
    }

    func testStripsOSCTitleWithBEL() {
        XCTAssertEqual(clean("\u{1B}]0;window title\u{07}body"), "body")
    }

    func testStripsCharsetDesignation() {
        XCTAssertEqual(clean("\u{1B}(Bplain"), "plain")
    }

    func testPlainTextUnchanged() {
        XCTAssertEqual(clean("no escapes here"), "no escapes here")
    }

    // The OSC match is lazy and does NOT cross `\n`: with no ST on its line, nothing matches.
    func testOSCDoesNotCrossNewline() {
        let input = "\u{1B}]0;title\nstill body\u{07}"
        XCTAssertEqual(clean(input), input)
    }

    func testStripsBracketedPasteEnableDisable() {
        XCTAssertEqual(clean("\u{1B}[?2004htext\u{1B}[?2004l"), "text")
    }
}

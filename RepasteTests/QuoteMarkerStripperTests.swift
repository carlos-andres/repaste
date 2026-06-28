import XCTest
import RepasteCore

final class QuoteMarkerStripperTests: XCTestCase {
    private let stage = QuoteMarkerStripper()
    private func clean(_ s: String) -> String { stage.apply(s, .default) }

    // ▎ = U+258E (quote marker) · │ = U+2502 (box-drawing). Escaped to avoid confusion.
    func testStripsQuoteMarkerWithSpace() {
        XCTAssertEqual(clean("\u{258E} hello"), "hello")
    }

    func testStripsQuoteMarkerWithLeadingSpaces() {
        XCTAssertEqual(clean("   \u{258E} hello"), "hello")
    }

    func testStripsQuoteMarkerWithoutTrailingSpace() {
        XCTAssertEqual(clean("\u{258E}hello"), "hello")
    }

    func testBoxDrawingVerticalIsNeverTouched() {
        // The critical char: │ (U+2502) must stay intact (it's not ▎).
        XCTAssertEqual(clean("\u{2502} table \u{2502}"), "\u{2502} table \u{2502}")
    }

    func testLineWithoutMarkerUnchanged() {
        XCTAssertEqual(clean("no marker here"), "no marker here")
    }

    func testMarkerNotAtLineStartIsNotStripped() {
        // The marker only counts after leading spaces; mid-line it stays intact (the presence guard
        // detects the ▎ but the position logic lets it pass through verbatim).
        XCTAssertEqual(clean("hello \u{258E} world"), "hello \u{258E} world")
    }

    func testMixedLinesStripOnlyQuoted() {
        XCTAssertEqual(clean("\u{258E} quoted\n\u{2502} tabled"), "quoted\n\u{2502} tabled")
    }
}

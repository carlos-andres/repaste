import XCTest
import RepasteCore

final class TrailingWhitespaceTrimmerTests: XCTestCase {
    private let stage = TrailingWhitespaceTrimmer()
    private func clean(_ s: String) -> String { stage.apply(s, .default) }

    func testTrimsTrailingSpaces() {
        XCTAssertEqual(clean("hello   "), "hello")
    }

    func testTrimsTrailingTabs() {
        XCTAssertEqual(clean("hello\t\t"), "hello")
    }

    func testKeepsInteriorAndLeadingWhitespace() {
        XCTAssertEqual(clean("  keep  middle  x  "), "  keep  middle  x")
    }

    func testTrimsPerLine() {
        XCTAssertEqual(clean("a  \nb\t"), "a\nb")
    }

    func testAllWhitespaceLineBecomesEmpty() {
        XCTAssertEqual(clean("   "), "")
    }
}

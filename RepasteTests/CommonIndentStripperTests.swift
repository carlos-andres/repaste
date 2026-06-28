import XCTest
import RepasteCore

final class CommonIndentStripperTests: XCTestCase {
    private let stage = CommonIndentStripper()
    private func clean(_ s: String) -> String { stage.apply(s, .default) }

    // Strict majority of non-empty lines indented ≥2 → dedents the common minimum.
    func testDedentsCommonIndent() {
        XCTAssertEqual(clean("  a\n  b\n  c"), "a\nb\nc")
        XCTAssertEqual(clean("    a\n    b"), "a\nb")
    }

    // common = the minimum of the ≥2 indents; deeper lines keep the remainder.
    func testDedentsByMinimumCommon() {
        XCTAssertEqual(clean("  a\n    b\n  c"), "a\n  b\nc")
    }

    // A line indented less than common loses ALL its leading indent.
    func testLessIndentedLineLosesAllIndent() {
        // non-empty indents = [4,4,1]; nonZero(≥2)=[4,4] (2 > 3/2) → common=4; the 1-space one → 0.
        XCTAssertEqual(clean("    a\n    b\n c"), "a\nb\nc")
    }

    // No strict majority indented ≥2 → touches nothing.
    func testNoStrictMajorityLeavesUnchanged() {
        // indents=[2,0,0]; nonZero=[2], 1 <= 3/2 → no change.
        XCTAssertEqual(clean("  a\nb\nc"), "  a\nb\nc")
    }

    func testEmptyNonZeroLeavesUnchanged() {
        XCTAssertEqual(clean("a\nb\nc"), "a\nb\nc")
        // a 1-space indent doesn't count as ≥2.
        XCTAssertEqual(clean(" a\n b\n c"), " a\n b\n c")
    }

    // Blank lines are preserved as-is and don't count toward the calculation.
    func testBlankLinesPreservedAndIgnored() {
        XCTAssertEqual(clean("  a\n\n  b"), "a\n\nb")
        XCTAssertEqual(clean("  a\n   \n  b"), "a\n   \nb")
    }

    func testEmptyStringUnchanged() {
        XCTAssertEqual(clean(""), "")
    }

    func testIdempotentOnEqualIndent() {
        let once = clean("  a\n  b\n  c")
        XCTAssertEqual(clean(once), once)
    }
}

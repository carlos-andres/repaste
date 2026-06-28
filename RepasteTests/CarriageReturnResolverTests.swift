import XCTest
import RepasteCore

final class CarriageReturnResolverTests: XCTestCase {
    private let stage = CarriageReturnResolver()
    private func clean(_ s: String) -> String { stage.apply(s, .default) }

    // The 3 canonical cases of the `\r` per-column overlay.
    func testOverlayKeepsTailOfLongerSegment() {
        XCTAssertEqual(clean("abcdef\rXY"), "XYcdef")
    }

    func testProgressBarFullyOverwritten() {
        XCTAssertEqual(clean("100%\rdone"), "done")
    }

    func testShorterOverlayLeavesTail() {
        XCTAssertEqual(clean("Loading...\rOK"), "OKading...")
    }

    func testMultipleCarriageReturnsInLine() {
        XCTAssertEqual(clean("abcdef\rXY\rZ"), "ZYcdef")
    }

    func testOverlayIsPerLine() {
        XCTAssertEqual(clean("a\rb\nc\rd"), "b\nd")
    }

    func testLineWithoutCarriageReturnUnchanged() {
        XCTAssertEqual(clean("no carriage\nhere"), "no carriage\nhere")
    }

    func testTrailingCarriageReturnKeepsBuffer() {
        XCTAssertEqual(clean("abc\r"), "abc")
    }
}

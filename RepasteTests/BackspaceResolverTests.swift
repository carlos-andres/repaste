import XCTest
import RepasteCore

final class BackspaceResolverTests: XCTestCase {
    private let stage = BackspaceResolver()
    private func clean(_ s: String) -> String { stage.apply(s, .default) }

    func testSingleBackspaceOverwrites() {
        XCTAssertEqual(clean("X\u{08}Y"), "Y")
    }

    func testConsecutiveBackspaces() {
        XCTAssertEqual(clean("ab\u{08}\u{08}c"), "c")
    }

    func testBackspaceAtStartIsNoOp() {
        XCTAssertEqual(clean("\u{08}abc"), "abc")
    }

    func testResolvesPerLine() {
        XCTAssertEqual(clean("a\u{08}b\nc\u{08}d"), "b\nd")
    }

    func testNoBackspaceUnchanged() {
        XCTAssertEqual(clean("plain\ntext"), "plain\ntext")
    }

    // Deletes the previous scalar (combining mark), not the whole grapheme (parity with JS's `for…of`).
    func testDeletesPrecedingScalarNotGrapheme() {
        XCTAssertEqual(clean("e\u{301}\u{08}x"), "ex")
    }
}

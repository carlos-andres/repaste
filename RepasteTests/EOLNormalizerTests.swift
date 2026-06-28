import XCTest
import RepasteCore

final class EOLNormalizerTests: XCTestCase {
    private let stage = EOLNormalizer()
    private func clean(_ s: String) -> String { stage.apply(s, .default) }

    func testCRLFBecomesLF() {
        XCTAssertEqual(clean("a\r\nb"), "a\nb")
    }

    func testLoneCRBecomesLFWhenNoLFPresent() {
        XCTAssertEqual(clean("a\rb\rc"), "a\nb\nc")
    }

    func testLoneCRSurvivesWhenLFAlsoPresent() {
        // Mixed: the lone \r is NOT converted; it survives for Stage 3's overlay.
        XCTAssertEqual(clean("a\r\nb\rc"), "a\nb\rc")
    }

    func testPlainTextUnchanged() {
        XCTAssertEqual(clean("plain\ntext"), "plain\ntext")
    }

    func testEmptyStringUnchanged() {
        XCTAssertEqual(clean(""), "")
    }
}

import XCTest
import RepasteCore

final class TabNormalizerTests: XCTestCase {
    private let stage = TabNormalizer()

    func testTabBecomesFourSpacesByDefault() {
        XCTAssertEqual(stage.apply("a\tb", .default), "a    b")
    }

    func testLeadingTab() {
        XCTAssertEqual(stage.apply("\tx", .default), "    x")
    }

    func testWidthIsConfigurable() {
        XCTAssertEqual(stage.apply("a\tb", CleaningOptions(tabWidth: 2)), "a  b")
    }

    func testNoTabUnchanged() {
        XCTAssertEqual(stage.apply("plain text", .default), "plain text")
    }

    func testWidthZeroRemovesTabs() {
        XCTAssertEqual(stage.apply("a\tb", CleaningOptions(tabWidth: 0)), "ab")
    }
}

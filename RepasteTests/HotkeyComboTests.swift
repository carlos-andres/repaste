import XCTest
import AppKit
import Carbon.HIToolbox

@MainActor
final class HotkeyComboTests: XCTestCase {
    private func keyDown(_ mods: NSEvent.ModifierFlags, chars: String, keyCode: UInt16) throws -> NSEvent {
        // NSEvent.keyEvent can return nil without app infrastructure: XCTUnwrap attributes the failure to the test.
        try XCTUnwrap(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: mods, timestamp: 0,
                                       windowNumber: 0, context: nil, characters: chars,
                                       charactersIgnoringModifiers: chars, isARepeat: false, keyCode: keyCode))
    }

    func testValidComboMapsModifiersAndUppercasesLabel() throws {
        let combo = HotkeyCombo(event: try keyDown([.control, .option, .command], chars: "v", keyCode: 9))
        XCTAssertEqual(combo, HotkeyCombo(keyCode: 9,
                                          carbonModifiers: UInt32(controlKey | optionKey | cmdKey), keyLabel: "V"))
    }

    func testShiftOnlyIsRejected() throws {
        // A global hotkey with only ⇧ would clash with normal typing: requires a strong modifier (⌃/⌥/⌘).
        XCTAssertNil(HotkeyCombo(event: try keyDown([.shift], chars: "a", keyCode: 0)))
    }

    func testNoModifierIsRejected() throws {
        XCTAssertNil(HotkeyCombo(event: try keyDown([], chars: "a", keyCode: 0)))
    }

    func testStrongModifierWithEmptyLabelIsRejected() throws {
        // No character (e.g. a dead key) means no label to show → invalid combo.
        XCTAssertNil(HotkeyCombo(event: try keyDown([.command], chars: "", keyCode: 55)))
    }

    func testNonGlyphFunctionKeyIsRejected() throws {
        // charactersIgnoringModifiers yields a glyph-less sentinel (U+F700 = ↑) for arrows/function keys:
        // it would show blank in the recorder, so the combo is rejected despite having a strong modifier.
        XCTAssertNil(HotkeyCombo(event: try keyDown([.control, .command], chars: "\u{F700}", keyCode: 126)))
    }

    func testControlCharacterKeyIsRejected() throws {
        // Tab arrives as a control character (U+0009): no visible glyph → rejected just like the arrows.
        XCTAssertNil(HotkeyCombo(event: try keyDown([.command], chars: "\t", keyCode: 48)))
    }

    func testShiftCombinedWithStrongModifierIsAccepted() throws {
        let combo = HotkeyCombo(event: try keyDown([.control, .shift, .command], chars: "c", keyCode: 8))
        XCTAssertEqual(combo?.carbonModifiers, UInt32(controlKey | shiftKey | cmdKey))
        XCTAssertEqual(combo?.keyLabel, "C")
    }

    func testSpokenDescriptionUsesWordsNotGlyphs() {
        // VoiceOver reads the ⌃⌥⌘ glyphs as meaningless Unicode names; the spoken form uses words in macOS order.
        XCTAssertEqual(HotkeyCombo.cleanClipboardDefault.spokenDescription, "Control Option Command V")
        XCTAssertEqual(HotkeyCombo.copyAndCleanDefault.spokenDescription, "Control Shift Command C")
    }
}

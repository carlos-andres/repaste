import XCTest
import Carbon.HIToolbox

final class HotkeyStoreTests: XCTestCase {
    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "HotkeyStoreTests.\(UUID().uuidString)")!
    }

    func testDefaultsWhenNothingStored() {
        let store = HotkeyStore(defaults: freshDefaults())
        XCTAssertEqual(store.combo(for: .cleanClipboard), .cleanClipboardDefault)
        XCTAssertEqual(store.combo(for: .copyAndClean), .copyAndCleanDefault)
    }

    func testRoundTripPersistsAcrossNewInstance() {
        let defaults = freshDefaults()
        let combo = HotkeyCombo(keyCode: 9, carbonModifiers: UInt32(controlKey | cmdKey), keyLabel: "V")
        HotkeyStore(defaults: defaults).set(combo, for: .cleanClipboard)
        // A new instance = the app relaunched: reads the same persisted value.
        XCTAssertEqual(HotkeyStore(defaults: defaults).combo(for: .cleanClipboard), combo)
        // Recording one path doesn't touch the other.
        XCTAssertEqual(HotkeyStore(defaults: defaults).combo(for: .copyAndClean), .copyAndCleanDefault)
    }

    func testDisplayUsesAppleModifierOrder() {
        let combo = HotkeyCombo(keyCode: 9,
                                carbonModifiers: UInt32(controlKey | optionKey | cmdKey), keyLabel: "V")
        XCTAssertEqual(combo.display, "⌃⌥⌘V")
    }

    func testPartialRecordFallsBackToDefault() {
        let defaults = freshDefaults()
        // Partial record (only the keycode, no modifiers or label): ignored and falls back to the full default.
        defaults.set(9, forKey: "hotkeyCleanClipboard.keyCode")
        XCTAssertEqual(HotkeyStore(defaults: defaults).combo(for: .cleanClipboard), .cleanClipboardDefault)
    }
}

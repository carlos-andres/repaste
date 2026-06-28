import XCTest

@MainActor
final class HotkeyManagerTests: XCTestCase {
    private func freshStore() -> HotkeyStore {
        HotkeyStore(defaults: UserDefaults(suiteName: "HotkeyManagerTests.\(UUID().uuidString)")!)
    }

    // The rejection happens BEFORE constructing the HotkeyTrigger (Carbon), so this branch is testable host-free.
    func testUpdateRejectsComboEqualToOtherPath() {
        let store = freshStore()
        let manager = HotkeyManager(store: store, runCleanClipboard: {}, runCopyAndClean: {})
        // Giving one path the combo the other already has must be rejected: two hotkeys with the same combo
        // clobber each other in Carbon and one would go mute.
        let colliding = store.combo(for: .copyAndClean)
        XCTAssertFalse(manager.update(.cleanClipboard, to: colliding))
        // The rejection doesn't mutate the store: cleanClipboard stays at its own default.
        XCTAssertEqual(store.combo(for: .cleanClipboard), .cleanClipboardDefault)
    }
}

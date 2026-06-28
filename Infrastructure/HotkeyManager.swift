/// Owner of the global hotkeys' lifecycle: registers from the store at startup and re-registers when
/// the user records a new combo in Settings. Lives in the app target because it manages `HotkeyTrigger` (Carbon).
@MainActor
final class HotkeyManager {
    private let store: HotkeyStore
    private let runCleanClipboard: () -> Void
    private let runCopyAndClean: () -> Void
    private var cleanClipboardTrigger: HotkeyTrigger?
    private var copyAndCleanTrigger: HotkeyTrigger?

    init(store: HotkeyStore, runCleanClipboard: @escaping () -> Void, runCopyAndClean: @escaping () -> Void) {
        self.store = store
        self.runCleanClipboard = runCleanClipboard
        self.runCopyAndClean = runCopyAndClean
    }

    func registerAll() {
        cleanClipboardTrigger = HotkeyTrigger(combo: store.combo(for: .cleanClipboard),
                                              id: HotkeyPath.cleanClipboard.carbonID, run: runCleanClipboard)
        copyAndCleanTrigger = HotkeyTrigger(combo: store.combo(for: .copyAndClean),
                                            id: HotkeyPath.copyAndClean.carbonID, run: runCopyAndClean)
    }

    func combo(for path: HotkeyPath) -> HotkeyCombo { store.combo(for: path) }

    /// Persists and rebuilds the path's trigger. Rejects a combo equal to the other path's: two hotkeys with the
    /// same combo clobber each other in Carbon and one would go mute. `false` = rejected (the recorder reverts the display).
    @discardableResult
    func update(_ path: HotkeyPath, to combo: HotkeyCombo) -> Bool {
        guard combo != store.combo(for: path.other) else { return false }
        store.set(combo, for: path)
        // Releasing the old trigger (its deinit unregisters Carbon) BEFORE registering the new one avoids a
        // window with two handlers for the same id.
        switch path {
        case .cleanClipboard:
            cleanClipboardTrigger = nil
            cleanClipboardTrigger = HotkeyTrigger(combo: combo, id: path.carbonID, run: runCleanClipboard)
        case .copyAndClean:
            copyAndCleanTrigger = nil
            copyAndCleanTrigger = HotkeyTrigger(combo: combo, id: path.carbonID, run: runCopyAndClean)
        }
        return true
    }
}

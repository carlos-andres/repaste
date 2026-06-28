/// Selection port (Path B). The adapter (Infra) simulates ⌘C via `CGEvent` and waits for the
/// `changeCount` increment; the App layer knows nothing about CGEvent or AppKit.
public protocol SelectionPort {
    /// Copies the active selection to the clipboard. `true` = the clipboard changed (the selection was
    /// copied); `false` = unchanged (no selection, or the synthetic ⌘C didn't land).
    func copySelection() -> Bool
}

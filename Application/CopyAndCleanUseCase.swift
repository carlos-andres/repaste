/// Path B (one gesture): with Accessibility permission it simulates copying the selection and cleans; without
/// permission it requests it and falls back to Path A. Reuses `CleanClipboardUseCase` to avoid duplicating pipeline or pre-check.
/// @MainActor: its adapters (synthetic ⌘C via CGEvent, Accessibility) require the main thread.
@MainActor
public final class CopyAndCleanUseCase {
    private let selection: SelectionPort
    private let permission: PermissionPort
    private let cleanClipboard: CleanClipboardUseCase

    public init(selection: SelectionPort, permission: PermissionPort,
                cleanClipboard: CleanClipboardUseCase) {
        self.selection = selection
        self.permission = permission
        self.cleanClipboard = cleanClipboard
    }

    /// With Accessibility permission it simulates ⌘C over the selection and cleans; without permission, it requests it and falls back to
    /// cleaning the current clipboard.
    /// - Returns: the cleaning outcome (over the copied selection or, as a fallback, over whatever was already there).
    /// - Note: side effects — may present the Accessibility prompt and post a synthetic ⌘C.
    @discardableResult
    public func run() -> CleanOutcome {
        guard permission.isAccessibilityTrusted else {
            // Without permission the adapter guides (prompt + deep-link) and we fall back to cleaning the current
            // clipboard, instead of failing silently.
            permission.request()
            return cleanClipboard.run(command: .copyAndClean)
        }
        // With permission we try to copy the selection; whether or not the clipboard changed, we clean whatever
        // is there (copy ok = new text; copy failed = fallback to what was already there).
        _ = selection.copySelection()
        return cleanClipboard.run(command: .copyAndClean)
    }
}

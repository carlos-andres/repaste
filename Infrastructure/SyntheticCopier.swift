import AppKit
import Carbon.HIToolbox
import CoreGraphics
import RepasteCore

/// Path B: simulates ⌘C in the frontmost app and confirms the copy by waiting for the clipboard's `changeCount`
/// to rise. Doesn't read the content (that's the use case's job); only signals whether something new was copied.
final class SyntheticCopier: SelectionPort {
    private let pasteboard: NSPasteboard
    private let timeout: TimeInterval

    init(pasteboard: NSPasteboard = .general, timeout: TimeInterval = 0.3) {
        self.pasteboard = pasteboard
        self.timeout = timeout
    }

    func copySelection() -> Bool {
        let before = pasteboard.changeCount
        postCommandC()
        // The ⌘C is processed by another process (the frontmost app); we wait for its write, never longer than the timeout.
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline && pasteboard.changeCount == before {
            Thread.sleep(forTimeInterval: 0.01)
        }
        return pasteboard.changeCount != before
    }

    private func postCommandC() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let key = CGKeyCode(kVK_ANSI_C)
        // If creating either event fails we post nothing: a keyDown without its keyUp
        // would leave ⌘ "stuck" in the target app.
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false) else { return }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

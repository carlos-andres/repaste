import AppKit
import ApplicationServices
import RepasteCore

/// Accessibility permission (Path B only). `request()` triggers the system prompt and, since that prompt
/// appears only once per session, also opens the Settings pane so the user can grant it.
final class AccessibilityGate: PermissionPort {
    private static let settingsDeepLink = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")

    var isAccessibilityTrusted: Bool { AXIsProcessTrusted() }

    func request() {
        // Literal instead of the imported constant `kAXTrustedCheckOptionPrompt`: that global isn't Sendable
        // and warns in Swift 6 mode; its stable value is exactly this key.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        guard let url = Self.settingsDeepLink else { return }
        // Opening Settings touches AppKit; the caller (use case) may come from an off-main hotkey callback.
        Task { @MainActor in NSWorkspace.shared.open(url) }
    }
}

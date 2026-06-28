/// Accessibility permission port (Path B). The adapter (Infra) translates it to `AXIsProcessTrusted`;
/// `request()` also guides the user (system prompt + deep-link to Settings), which is why the App layer
/// doesn't build permission copy.
public protocol PermissionPort {
    /// `true` if the app has Accessibility permission (needed to copy the selection with a synthetic ⌘C).
    var isAccessibilityTrusted: Bool { get }
    /// Presents the system prompt and opens the deep-link to Settings. Fire-and-forget, non-throwing.
    func request()
}

import AppKit
import RepasteCore

/// `NSPasteboard.general` adapter: if the content is protected (nspasteboard / 1Password markers) it doesn't
/// even read the text — it never enters memory. Reads only on a user action, never via a watcher.
final class SystemPasteboard: PasteboardPort {
    private let pasteboard: NSPasteboard

    /// Marks the content's producer (nspasteboard.org standard); third-party clipboard managers
    /// read it to avoid re-processing their own writes.
    private static let sourceType = NSPasteboard.PasteboardType("org.nspasteboard.source")
    /// Content NOT to touch: Concealed (sensitive, e.g. passwords) and Transient (volatile) are from the
    /// nspasteboard.org standard; 1Password additionally publishes its own UTI.
    private static let protectedMarkers: Set<String> = [
        "org.nspasteboard.ConcealedType",
        "org.nspasteboard.TransientType",
        "com.agilebits.onepassword",
    ]

    init(pasteboard: NSPasteboard = .general) { self.pasteboard = pasteboard }

    func read() -> PasteboardContent {
        let isProtected = (pasteboard.types ?? []).contains { Self.protectedMarkers.contains($0.rawValue) }
        let text = isProtected ? nil : pasteboard.string(forType: .string)
        return PasteboardContent(text: text, isProtected: isProtected)
    }

    func write(_ text: String, source: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        pasteboard.setString(source, forType: Self.sourceType)
    }
}

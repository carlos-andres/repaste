/// Clipboard port. The adapter (Infra) translates it to `NSPasteboard` + nspasteboard markers;
/// the App layer knows nothing about UTIs or AppKit.
public protocol PasteboardPort {
    /// Reads the clipboard. If the content is protected, `PasteboardContent.text` is `nil` (it never enters memory).
    func read() -> PasteboardContent
    /// Writes the cleaned text and identifies the producer.
    /// - Parameter source: bundle id of the writing process; the adapter records it as the owner so that
    ///   third-party clipboard managers can distinguish this write.
    func write(_ text: String, source: String)
}

/// What the use case needs from the clipboard. `isProtected` = Concealed/Transient/1Password markers
/// are present → must not be processed or logged.
public struct PasteboardContent: Equatable, Sendable {
    public let text: String?
    public let isProtected: Bool

    public init(text: String?, isProtected: Bool) {
        self.text = text
        self.isProtected = isProtected
    }
}

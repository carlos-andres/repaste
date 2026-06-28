/// Stage 6 — Normalize tabs. Each `\t` → exactly `tabWidth` spaces (1→N substitution, not
/// column-aligned tab stops). Width configurable in `CleaningOptions` (default 4).
public struct TabNormalizer: CleaningStage {
    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        guard text.unicodeScalars.contains("\t") else { return text }
        let spaces = String(repeating: " ", count: max(0, options.tabWidth))
        return text.replacingOccurrences(of: "\t", with: spaces)
    }
}

import Foundation

/// Stage 1 — Normalize EOL. `\r\n`→`\n`; a lone `\r`→`\n` ONLY if there's no `\n` at all
/// (when mixed, `\r`s survive on purpose for Stage 3's overlay).
public struct EOLNormalizer: CleaningStage {
    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
        let scalars = normalized.unicodeScalars
        if scalars.contains("\r") && !scalars.contains("\n") {
            return normalized.replacingOccurrences(of: "\r", with: "\n")
        }
        return normalized
    }
}

/// Stage 4 — Backspace overprinting. Per line, iterating over UnicodeScalars: `\b` (U+0008) erases the
/// previous scalar; the rest accumulates. `X\bY` → `Y`. Handles consecutive `\b`.
public struct BackspaceResolver: CleaningStage {
    private static let backspace: Unicode.Scalar = "\u{08}"

    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        guard text.unicodeScalars.contains(Self.backspace) else { return text }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.map { resolveLine($0) }.joined(separator: "\n")
    }

    private func resolveLine(_ line: Substring) -> String {
        guard line.unicodeScalars.contains(Self.backspace) else { return String(line) }
        var result: [Unicode.Scalar] = []
        for scalar in line.unicodeScalars {
            if scalar == Self.backspace {
                if !result.isEmpty { result.removeLast() }
            } else {
                result.append(scalar)
            }
        }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: result)
        return String(view)
    }
}

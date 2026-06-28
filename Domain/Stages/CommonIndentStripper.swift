/// Stage 9 — Global dedent. Only acts if a strict majority of non-empty lines have ≥2 spaces of
/// indent; removes the common minimum. Lines below that minimum lose all indent; blank lines don't count.
public struct CommonIndentStripper: CleaningStage {
    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        // Not idempotent: if the dedent leaves a uniform residual indent, a 2nd pass dedents again.
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let indents = lines.filter { !isBlank($0) }.map(leadingSpaces)
        let nonZero = indents.filter { $0 >= 2 }
        guard !nonZero.isEmpty, nonZero.count > indents.count / 2, let common = nonZero.min() else {
            return text
        }
        return lines.map { line -> String in
            if isBlank(line) { return String(line) }
            let indent = leadingSpaces(line)
            return String(line.dropFirst(indent >= common ? common : indent))
        }.joined(separator: "\n")
    }

    private func isBlank(_ line: Substring) -> Bool {
        line.allSatisfy(\.isWhitespace)
    }

    private func leadingSpaces(_ line: Substring) -> Int {
        line.unicodeScalars.prefix { $0 == " " }.count
    }
}

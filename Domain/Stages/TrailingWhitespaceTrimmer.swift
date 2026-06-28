/// Stage 5 — Trailing whitespace. Per line, removes `[ \t]+$` (only space and tab, not `\v`/`\f`).
public struct TrailingWhitespaceTrimmer: CleaningStage {
    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.map { line in
            // Common case (no trailing ws): avoids materializing the line's scalar array.
            guard let last = line.unicodeScalars.last, last == " " || last == "\t" else { return String(line) }
            var scalars = Array(line.unicodeScalars)
            while let last = scalars.last, last == " " || last == "\t" {
                scalars.removeLast()
            }
            var view = String.UnicodeScalarView()
            view.append(contentsOf: scalars)
            return String(view)
        }.joined(separator: "\n")
    }
}

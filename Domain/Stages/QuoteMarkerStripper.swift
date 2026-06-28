/// Stage 8 — Strip quote marker. Removes ONLY `▎` (U+258E): per line, zero or more spaces,
/// the `▎`, and an optional space. NEVER touches `│` (U+2502), the box-drawing / TUI-gutter
/// character — confusing the two codepoints breaks tables.
public struct QuoteMarkerStripper: CleaningStage {
    private static let quoteMarker: Unicode.Scalar = "\u{258E}"

    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.map { stripLine($0) }.joined(separator: "\n")
    }

    private func stripLine(_ line: Substring) -> String {
        // With no marker on the line there's nothing to do: avoids materializing the scalar array.
        guard line.unicodeScalars.contains(Self.quoteMarker) else { return String(line) }
        let scalars = Array(line.unicodeScalars)
        var i = 0
        while i < scalars.count && scalars[i] == " " { i += 1 }
        guard i < scalars.count && scalars[i] == Self.quoteMarker else { return String(line) }
        i += 1
        if i < scalars.count && scalars[i] == " " { i += 1 }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars[i...])
        return String(view)
    }
}

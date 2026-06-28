/// Stage 3 — Resolve `\r`: per-column overlay (NOT "last segment"; a short segment doesn't erase the
/// prior tail), iterating over UnicodeScalars for parity with JS's `for…of`. E.g. `abcdef\rXY`→`XYcdef`.
public struct CarriageReturnResolver: CleaningStage {
    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        guard text.unicodeScalars.contains("\r") else { return text }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.map { resolveLine($0) }.joined(separator: "\n")
    }

    private func resolveLine(_ line: Substring) -> String {
        guard line.unicodeScalars.contains("\r") else { return String(line) }
        var buffer: [Unicode.Scalar] = []
        var column = 0
        for scalar in line.unicodeScalars {
            if scalar == "\r" {
                column = 0
            } else if column < buffer.count {
                buffer[column] = scalar
                column += 1
            } else {
                buffer.append(scalar)
                column += 1
            }
        }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: buffer)
        return String(view)
    }
}

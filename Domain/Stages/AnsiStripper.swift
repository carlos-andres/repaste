import Foundation

/// Stage 2 — Strip ANSI. Three global replacements in order: CSI/SGR/cursor/bracketed-paste, generic
/// OSC (incl. OSC8 and titles), and G0/G1 charset designation. OSC8 erases each sequence
/// separately → keeps the link text and discards the URL (no markdown generated in v1).
public struct AnsiStripper: CleaningStage {
    private static let regexes: [NSRegularExpression] = {
        let esc = "\u{1B}"
        let bel = "\u{07}"
        let patterns = [
            esc + "\\[\\??[0-9;]*[a-zA-Z~]",
            esc + "\\][^\\n]*?(?:" + bel + "|" + esc + "\\\\)",
            esc + "[()][AB012]",
        ]
        // try! is safe: fixed literal patterns; a throw would mean a malformed regex
        // (programmer bug), never a runtime condition.
        return patterns.map { try! NSRegularExpression(pattern: $0) }
    }()

    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        var result = text
        for regex in Self.regexes {
            let full = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: full, withTemplate: "")
        }
        return result
    }
}

import Foundation

/// Stage 7 — Strip shell prompts. OFF by default: it's destructive (a markdown blockquote `> `
/// also starts with a generic prompt). Per line, the FIRST matching pattern removes the prefix;
/// the pattern order is load-bearing. If no content remains after removal, the line is dropped.
public struct ShellPromptStripper: CleaningStage {
    // The optional `(?:\(...\)\s*)?` prefix covers the `(venv) `/`(conda) ` of virtual environments.
    private static let patterns: [NSRegularExpression] = [
        #"^(?:\([^)]+\)\s*)?[A-Za-z0-9_.-]+@[A-Za-z0-9_.-]+:[~/][A-Za-z0-9_/._-]*[$#%](\s+|$)"#,
        #"^PS [A-Z]:\\[^>]*>(\s+|$)"#,
        #"^[A-Z]:\\[^>]*>\s*"#,
        #"^>>>(\s+|$)"#,
        #"^irb[^>]*>(\s+|$)"#,
        #"^mysql>(\s+|$)"#,
        #"^(?:\([^)]+\)\s*)?[$#%>](\s+|$)"#,  // generic catch-all: goes last so it doesn't shadow the specific prompts.
    ].map { try! NSRegularExpression(pattern: $0) }  // try! is safe: literal patterns; a throw = malformed regex (programmer bug), not a runtime one.

    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        guard options.stripShellPrompts else { return text }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var out: [String] = []
        for line in lines {
            if let kept = strip(String(line)) { out.append(kept) }
        }
        return out.joined(separator: "\n")
    }

    /// Returns the remainder after removing the prompt, or `nil` if the line should be dropped (trimmed remainder empty).
    private func strip(_ line: String) -> String? {
        let ns = line as NSString
        let full = NSRange(location: 0, length: ns.length)
        for regex in Self.patterns {
            guard let match = regex.firstMatch(in: line, range: full) else { continue }
            let remaining = ns.substring(from: NSMaxRange(match.range))
            return remaining.allSatisfy(\.isWhitespace) ? nil : remaining
        }
        return line
    }
}

import Foundation

/// Stage 11 — Block detection + reflow. Marks structured blocks as `pre` (don't touch)
/// (tool-headers, TUI, diffs, gutters with ≥3 numbered lines), joins gutter wraps without a space, and reflows
/// prose/list runs: merges wrapped lines per a statistical heuristic (`shouldReflow`)
/// and absorbs bullet continuations. Faithful port of Terminal Text Fixer's JS (not reflow.py).
public struct ParagraphReflower: CleaningStage {
    private enum LineType {
        case toolHeader, tui, diffHeader, diffLine, diffContinuation, gutterCandidate, gutter, normal
    }

    private struct ProseEntry { let original: String; let trimmed: String }

    // `\w`→`[A-Za-z0-9_]` and `\d`→`[0-9]`: the reference implementation uses ASCII classes here; its string
    // length is UTF-16, which is why the length thresholds use `utf16.count`.
    private static let reToolHeader = rx(#"^●\s+[A-Za-z0-9_]+\("#)
    private static let reTui1 = rx(#"^\s*[⎿│├└┌┐┘┤┬┴┼]"#)
    private static let reTui2 = rx(#"^\|[^\n]*\|$"#)
    private static let reDiffGit = rx(#"^diff --git\s"#)
    private static let reDiffPM = rx(#"^(---|\+\+\+)\s"#)
    private static let reDiffAt = rx(#"^@@\s"#)
    private static let reDiffIndex = rx(#"^index\s[0-9a-f]+\.\.[0-9a-f]+"#)
    private static let reDiffLine1 = rx(#"^[-+]\s"#)
    private static let reDiffLine2 = rx(#"^[-+]\t"#)
    private static let reDiffCont = rx(#"^\s+\+\s"#)
    private static let reGutterCand = rx(#"^\s*[0-9]+\s{1,4}\S"#)
    private static let reIndent4 = rx(#"^\s{4,}"#)
    private static let reGutterStart = rx(#"^\s*[0-9]+\s"#)
    private static let reLeadingWs = rx(#"^\s"#)
    private static let reList = rx(#"^[-*+●○◼◻▪▫■□✓✔✗✘…] |^[0-9]+[.)]\s"#)
    private static let reBulletOnly = rx(#"^[-*+●○◼◻▪▫■□✓✔✗✘…] "#)
    private static let reIndentedEntry = rx(#"^(?:\t| {4,})"#)
    private static let reEndPunct = rx(#"[.!?:;]$"#)

    public init() {}

    public func apply(_ text: String, _ options: CleaningOptions) -> String {
        let lines = text.components(separatedBy: "\n")
        let marks = markPreformatted(lines)
        let joined = joinGutterContinuations(lines, marks)

        var result: [String] = []
        var i = 0
        while i < joined.lines.count {
            if joined.marks[i] {
                result.append(joined.lines[i]); i += 1
            } else if isBlank(joined.lines[i]) {
                result.append(joined.lines[i]); i += 1
            } else {
                var normalLines: [String] = []
                while i < joined.lines.count, !joined.marks[i], !isBlank(joined.lines[i]) {
                    normalLines.append(joined.lines[i]); i += 1
                }
                if !normalLines.isEmpty { result.append(reflowParagraph(normalLines)) }
            }
        }
        return result.joined(separator: "\n")
    }

    // MARK: - Classification

    private func classify(_ line: String) -> LineType {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if matches(Self.reToolHeader, trimmed) { return .toolHeader }
        if matches(Self.reTui1, line) { return .tui }
        if matches(Self.reTui2, trimmed) { return .tui }
        if matches(Self.reDiffGit, trimmed) || matches(Self.reDiffPM, trimmed)
            || matches(Self.reDiffAt, trimmed) || matches(Self.reDiffIndex, trimmed) { return .diffHeader }
        if matches(Self.reDiffLine1, trimmed) || matches(Self.reDiffLine2, trimmed) { return .diffLine }
        if matches(Self.reDiffCont, line) { return .diffContinuation }
        if matches(Self.reGutterCand, line) { return .gutterCandidate }
        return .normal
    }

    private func markPreformatted(_ lines: [String]) -> [Bool] {
        var types = lines.map { classify($0) }

        // A gutter is only confirmed with ≥3 consecutive candidates; otherwise they're normal prose.
        var i = 0
        while i < types.count {
            if types[i] == .gutterCandidate {
                var j = i
                while j < types.count, types[j] == .gutterCandidate { j += 1 }
                let confirmed = (j - i) >= 3
                for k in i..<j { types[k] = confirmed ? .gutter : .normal }
                i = j
            } else { i += 1 }
        }

        let starters: Set<LineType> = [.toolHeader, .tui, .gutter, .diffHeader]
        let continuers: Set<LineType> = [.toolHeader, .tui, .gutter, .diffContinuation, .diffHeader, .diffLine]
        var marks = Array(repeating: false, count: lines.count)

        var idx = 0
        while idx < lines.count {
            guard starters.contains(types[idx]) else { idx += 1; continue }
            while idx < lines.count {
                let type = types[idx]
                let blank = isBlank(lines[idx])
                let indented = !blank && matches(Self.reIndent4, lines[idx])
                if continuers.contains(type) {
                    marks[idx] = true; idx += 1
                } else if indented {
                    marks[idx] = true; idx += 1
                } else if blank {
                    // A blank line extends the block only if pre/indented content follows the blanks.
                    var j = idx
                    while j < lines.count, isBlank(lines[j]) { j += 1 }
                    if j < lines.count, continuers.contains(types[j]) || matches(Self.reIndent4, lines[j]) {
                        while idx < j { marks[idx] = true; idx += 1 }
                    } else { break }
                } else { break }
            }
        }
        return marks
    }

    // MARK: - Gutter continuation joining

    private func joinGutterContinuations(_ lines: [String], _ marks: [Bool]) -> (lines: [String], marks: [Bool]) {
        var rLines: [String] = []
        var rMarks: [Bool] = []
        var i = 0
        while i < lines.count {
            if !marks[i] || !matches(Self.reGutterStart, lines[i]) {
                rLines.append(lines[i]); rMarks.append(marks[i]); i += 1; continue
            }
            let gutterIndent = leadingWhitespaceCount(lines[i])
            var joined = lines[i]
            // LLM responses wrap long gutter lines with more indent and no number → join without a space.
            while i + 1 < lines.count, marks[i + 1] {
                let next = lines[i + 1]
                if !isBlank(next), !matches(Self.reGutterStart, next), leadingWhitespaceCount(next) > gutterIndent {
                    joined += trimStart(next)
                    i += 1
                } else { break }
            }
            rLines.append(joined); rMarks.append(true); i += 1
        }
        return (rLines, rMarks)
    }

    // MARK: - Paragraph reflow

    private func reflowParagraph(_ normalLines: [String]) -> String {
        var resultLines: [String] = []
        var currentProse: [ProseEntry] = []
        var inList = false

        for line in normalLines {
            let trimmed = leftTrimTabSpace(line)
            let isListItem = matches(Self.reList, trimmed)

            if inList {
                if matches(Self.reLeadingWs, line) {
                    // Shallow indent (1-2) without a bullet = LLM wrap → continuation; deep or bulleted = real sub-item.
                    let indent = leadingSpaceCount(line)
                    if indent <= 2, !matches(Self.reBulletOnly, trimmed) {
                        resultLines[resultLines.count - 1] += " " + trimmed
                    } else if isListItem {
                        resultLines.append(trimmed)
                    } else {
                        resultLines[resultLines.count - 1] += " " + trimmed
                    }
                } else if isListItem {
                    resultLines.append(trimmed)
                } else {
                    // Not indented and not an item: a wrapped continuation if the previous item was long, otherwise leaves the list.
                    if let last = resultLines.last, last.utf16.count >= 60 {
                        resultLines[resultLines.count - 1] += " " + trimmed
                    } else {
                        inList = false
                        currentProse.append(ProseEntry(original: line, trimmed: trimmed))
                    }
                }
            } else if isListItem {
                // "False bullet": a `1.` after long prose with no end punctuation is a continuation, not an item.
                let lastProse = currentProse.last
                let isWrappedProseContinuation = lastProse.map {
                    $0.original.utf16.count >= 60
                        && !matches(Self.reEndPunct, $0.trimmed.trimmingCharacters(in: .whitespacesAndNewlines))
                } ?? false

                if isWrappedProseContinuation {
                    currentProse.append(ProseEntry(original: line, trimmed: trimmed))
                } else {
                    if !currentProse.isEmpty {
                        flushProse(currentProse, into: &resultLines)
                        currentProse = []
                    }
                    inList = true
                    resultLines.append(trimmed)
                }
            } else {
                currentProse.append(ProseEntry(original: line, trimmed: trimmed))
            }
        }

        if !currentProse.isEmpty { flushProse(currentProse, into: &resultLines) }
        return resultLines.joined(separator: "\n")
    }

    private func flushProse(_ entries: [ProseEntry], into resultLines: inout [String]) {
        if entries.count <= 1 {
            resultLines.append(contentsOf: entries.map(\.trimmed))
            return
        }
        if shouldReflow(entries) {
            resultLines.append(entries.map(\.trimmed).joined(separator: " "))
        } else {
            // Shallow indent = LLM wrap artifact (use trimmed); deep (≥4) = real structure.
            let maxIndent = entries.map { leadingSpaceCount($0.original) }.max() ?? 0
            let useOriginal = maxIndent >= 4
            resultLines.append(contentsOf: entries.map { useOriginal ? $0.original : $0.trimmed })
        }
    }

    private func shouldReflow(_ entries: [ProseEntry]) -> Bool {
        let lengths = entries.map { $0.trimmed.utf16.count }
        let maxLen = lengths.max() ?? 0
        if maxLen < 30 { return false }

        // Tabular data (mostly with column gaps) or deliberate ≥4 indentation → don't reflow.
        let tabularCount = entries.filter { hasInternalMultipleSpaces($0.original) }.count
        if tabularCount > entries.count / 2 { return false }
        let indentedCount = entries.filter { matches(Self.reIndentedEntry, $0.original) }.count
        if indentedCount > entries.count / 2 { return false }

        if entries.count == 2 { return lengths[0] >= 30 }

        // 3+ lines: the first/last may be short; the majority of long middle lines decides.
        let wrapThreshold = max(Double(maxLen) * 0.7, 25)
        let middle = lengths[1..<(lengths.count - 1)]
        let longMiddle = middle.filter { Double($0) >= wrapThreshold }.count
        return longMiddle > middle.count / 2
    }

    // MARK: - Helpers

    private func isBlank(_ line: String) -> Bool {
        line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func hasInternalMultipleSpaces(_ line: String) -> Bool {
        String(line.drop(while: \.isWhitespace)).range(of: "  ") != nil
    }

    private func leftTrimTabSpace(_ s: String) -> String {
        String(s.drop(while: { $0 == " " || $0 == "\t" }))
    }

    private func trimStart(_ s: String) -> String {
        String(s.drop(while: \.isWhitespace))
    }

    private func leadingSpaceCount(_ s: String) -> Int {
        s.prefix(while: { $0 == " " }).count
    }

    private func leadingWhitespaceCount(_ s: String) -> Int {
        s.prefix(while: \.isWhitespace).count
    }

    private func matches(_ re: NSRegularExpression, _ s: String) -> Bool {
        re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }

    private static func rx(_ pattern: String) -> NSRegularExpression {
        // try! is safe: only called with literal patterns; a throw would be a programmer bug, not a runtime one.
        try! NSRegularExpression(pattern: pattern)
    }
}

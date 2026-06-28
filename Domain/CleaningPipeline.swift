/// Composes the stages in order and produces a `CleanResult`. The engine is `String → String`
/// over pure stages; the canonical order mirrors the reference implementation's.
public struct CleaningPipeline {
    public let stages: [CleaningStage]

    public init(stages: [CleaningStage]) {
        self.stages = stages
    }

    /// Runs the text through each stage in order and measures line counts before and after.
    /// - Returns: the cleaned text plus the input and output line counts (for the HUD's "N→M").
    public func clean(_ text: String, options: CleaningOptions = .default) -> CleanResult {
        var current = text
        for stage in stages {
            current = stage.apply(current, options)
        }
        return CleanResult(text: current,
                           inputLineCount: text.lineCount,
                           outputLineCount: current.lineCount)
    }
}

extension String {
    /// Logical lines for the HUD ("N→M"); empty string = 0 (not 1).
    var lineCount: Int {
        isEmpty ? 0 : split(separator: "\n", omittingEmptySubsequences: false).count
    }
}

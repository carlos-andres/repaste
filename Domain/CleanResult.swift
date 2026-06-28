/// Result of a cleaning pass: the text and the stats for the HUD ("N→M lines").
public struct CleanResult: Equatable, Sendable {
    /// The text already processed by the pipeline.
    public let text: String
    /// Input text line count (empty string = 0, not 1).
    public let inputLineCount: Int
    /// Output text line count (empty string = 0, not 1).
    public let outputLineCount: Int

    public init(text: String, inputLineCount: Int, outputLineCount: Int) {
        self.text = text
        self.inputLineCount = inputLineCount
        self.outputLineCount = outputLineCount
    }
}

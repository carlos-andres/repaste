/// A cleaning pipeline stage: transforms text into text, pure and deterministic.
/// The `CleaningPipeline` composes them in a load-bearing order.
public protocol CleaningStage: Sendable {
    /// Transforms the text by applying this stage. Pure and deterministic: no I/O or state between calls.
    /// - Parameters:
    ///   - text: input text (the previous stage's output).
    ///   - options: pipeline toggles (prompts, tabWidth, markdown).
    /// - Returns: the transformed text, which feeds the next stage.
    func apply(_ text: String, _ options: CleaningOptions) -> String
}

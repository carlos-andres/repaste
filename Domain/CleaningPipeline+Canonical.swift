public extension CleaningPipeline {
    /// v1 pipeline in the reference implementation's canonical order. The box-tables and
    /// OSC8→link stage are deferred to v2 (Markdown formatter). Toggles (prompts, tabWidth) are read from `options`.
    static func canonicalV1() -> CleaningPipeline {
        CleaningPipeline(stages: [
            EOLNormalizer(),             // 1
            AnsiStripper(),              // 2
            CarriageReturnResolver(),    // 3
            BackspaceResolver(),         // 4
            TrailingWhitespaceTrimmer(), // 5
            TabNormalizer(),             // 6
            ShellPromptStripper(),       // 7 (OFF by default)
            QuoteMarkerStripper(),       // 8
            CommonIndentStripper(),      // 9
            ParagraphReflower(),         // 11 — stage 10 (box-tables/OSC8→markdown) is inserted here in v2
        ])
    }
}

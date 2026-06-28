/// Cleaning pipeline toggles. Destructive options start OFF (opt-in).
public struct CleaningOptions: Sendable {
    /// Strips shell prompts at line start (`$ `, `(venv) `, …). OFF by default: it's destructive.
    public var stripShellPrompts: Bool
    /// Reserved for v2 (Markdown formatter: box tables→md, OSC8→link). No effect in v1.
    public var markdownFormatter: Bool
    /// Spaces per `\t` (1→N substitution, not column-aligned tab stops). Default 4.
    public var tabWidth: Int

    public init(stripShellPrompts: Bool = false,
                markdownFormatter: Bool = false,
                tabWidth: Int = 4) {
        self.stripShellPrompts = stripShellPrompts
        self.markdownFormatter = markdownFormatter
        self.tabWidth = tabWidth
    }

    public static let `default` = CleaningOptions()
}

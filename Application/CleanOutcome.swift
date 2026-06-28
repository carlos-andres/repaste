/// Observable result of a use-case run; the notification adapter translates it to the displayed copy.
public enum CleanOutcome: Equatable, Sendable {
    /// Flagged content (Concealed/Transient/1Password): not processed.
    case protected
    /// No plain text to clean.
    case empty
    /// Cleaned and written to the clipboard; the payload carries the text and the in/out line counts.
    case cleaned(CleanResult)
}

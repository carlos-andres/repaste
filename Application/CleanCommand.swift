/// The command that originated the cleaning. The logic is identical for both; it only lets the
/// notification adapter give different feedback depending on the origin.
public enum CleanCommand: Equatable, Sendable {
    case cleanClipboard
    case copyAndClean
}

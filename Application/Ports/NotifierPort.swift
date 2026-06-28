/// Notification port: the adapter translates the outcome to the on-screen copy. The copy lives in the adapter,
/// not in the App layer, to avoid coupling the use case to presentation.
public protocol NotifierPort {
    /// Delivers the result notification (fire-and-forget, non-throwing). The adapter decides the displayed copy.
    /// - Parameters:
    ///   - outcome: use-case result that determines the message.
    ///   - command: activation origin; may affect the copy.
    func notify(_ outcome: CleanOutcome, command: CleanCommand)
}

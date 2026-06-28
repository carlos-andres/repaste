/// Path A (copy-first): reads the clipboard → pre-check → pipeline → writes + source → notifies.
/// The pre-check lives here (App layer), not in the engine. Never logs or persists the clipboard content.
/// @MainActor: its pasteboard and notification adapters (NSPasteboard/UserNotifications) require the main thread.
@MainActor
public final class CleanClipboardUseCase {
    private let pasteboard: PasteboardPort
    private let notifier: NotifierPort
    private let settings: SettingsPort
    private let pipeline: CleaningPipeline
    private let bundleIdentifier: String

    public init(pasteboard: PasteboardPort, notifier: NotifierPort, settings: SettingsPort,
                pipeline: CleaningPipeline, bundleIdentifier: String) {
        self.pasteboard = pasteboard
        self.notifier = notifier
        self.settings = settings
        self.pipeline = pipeline
        self.bundleIdentifier = bundleIdentifier
    }

    /// Reads the clipboard, applies the pre-check and the pipeline, and rewrites the cleaned text.
    /// - Parameter command: the cleaning's origin; the notification adapter uses it for the copy.
    /// - Returns: `.protected` if the content has markers (untouched); `.empty` if there's no text to
    ///   clean; `.cleaned` with the result (and, if the toggle is ON, notifies success).
    @discardableResult
    public func run(command: CleanCommand = .cleanClipboard) -> CleanOutcome {
        let content = pasteboard.read()

        if content.isProtected {
            notifier.notify(.protected, command: command)
            return .protected
        }
        // Absent or whitespace-only text = nothing to clean: silent no-op (a notice would be redundant).
        guard let text = content.text, text.contains(where: { !$0.isWhitespace }) else {
            return .empty
        }

        let result = pipeline.clean(text, options: settings.options)
        pasteboard.write(result.text, source: bundleIdentifier)

        let outcome = CleanOutcome.cleaned(result)
        // The toggle is a visual aid: it silences the success ✓. Protected always notifies (explains the no-op).
        if settings.notificationsEnabled { notifier.notify(outcome, command: command) }
        return outcome
    }
}

/// Preferences port: exposes the pipeline toggles and whether success is notified.
public protocol SettingsPort {
    /// Pipeline toggles (prompts, tabWidth, markdown) read on each run.
    var options: CleaningOptions { get }
    /// When `false`, success (`.cleaned`) is not notified. Protected and empty are unaffected.
    var notificationsEnabled: Bool { get }
}

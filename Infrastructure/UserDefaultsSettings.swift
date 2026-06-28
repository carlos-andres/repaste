import Foundation
import RepasteCore

/// Preferences persisted in `UserDefaults`. By default everything starts OFF/4: the destructive options
/// (prompts, markdown) are opt-in and the success notification only appears if the user enables the visual aid.
final class UserDefaultsSettings: SettingsPort {
    private let defaults: UserDefaults

    // The Settings UI (@AppStorage) shares these keys to avoid duplicating the strings.
    enum Key {
        static let stripShellPrompts = "stripShellPrompts"
        static let markdownFormatter = "markdownFormatter"
        static let tabWidth = "tabWidth"
        static let notificationsEnabled = "notificationsEnabled"
    }

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var options: CleaningOptions {
        CleaningOptions(
            stripShellPrompts: defaults.bool(forKey: Key.stripShellPrompts),
            markdownFormatter: defaults.bool(forKey: Key.markdownFormatter),
            tabWidth: defaults.object(forKey: Key.tabWidth) as? Int ?? 4
        )
    }

    var notificationsEnabled: Bool { defaults.bool(forKey: Key.notificationsEnabled) }
}

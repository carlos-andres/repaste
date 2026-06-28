import UserNotifications
import RepasteCore
import os

/// NotifierPort adapter over the system notification center: the banner uses the standard macOS
/// look (icon + app name). The success gating lives in the use case; here it's only delivered.
final class UserNotificationNotifier: NotifierPort {
    private static let log = Logger(subsystem: "com.calo.RePaste", category: "notifications")

    /// Requested once at startup; once granted, notifications go out with no further friction.
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, error in
            // Without permission, add() is a silent no-op: we leave a signal (no content) for diagnostics.
            if let error { UserNotificationNotifier.log.error("auth error: \(error.localizedDescription, privacy: .public)") }
            else if !granted { UserNotificationNotifier.log.notice("notifications not granted") }
        }
    }

    func notify(_ outcome: CleanOutcome, command: CleanCommand) {
        let content = UNMutableNotificationContent()
        content.title = UserNotificationNotifier.message(for: outcome, command: command)

        let center = UNUserNotificationCenter.current()
        // Reusing the id tries to replace the previous banner instead of stacking (removeDelivered is async → best-effort).
        let id = "com.calo.RePaste.clean-feedback"
        center.removeDeliveredNotifications(withIdentifiers: [id])
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil))
    }

    private static func message(for outcome: CleanOutcome, command: CleanCommand) -> String {
        switch outcome {
        case .cleaned:
            switch command {
            case .cleanClipboard: return String(localized: "Clipboard cleaned")
            case .copyAndClean:   return String(localized: "Text cleaned")
            }
        case .protected: return String(localized: "Protected content — left untouched")
        case .empty:     return String(localized: "Nothing to clean")
        }
    }
}

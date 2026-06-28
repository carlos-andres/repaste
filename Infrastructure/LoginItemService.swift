import ServiceManagement
import os

/// Launch-at-login via `SMAppService.mainApp`. `register()` requires the app signed and installed in
/// /Applications + user approval; it can fail from a development build (validated when distributing).
@MainActor
final class LoginItemService {
    private static let log = Logger(subsystem: "com.calo.RePaste", category: "loginitem")

    var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    func setEnabled(_ enabled: Bool) {
        // We don't propagate the error (the UI re-reads `isEnabled`); the log records the rejection for diagnostics.
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            Self.log.error("login item set to \(enabled) failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

import SwiftUI
import RepasteCore

/// Settings window (SwiftUI hosted in an NSWindow). It only wires and displays: the notification setting persists via
/// `@AppStorage` (same key `UserDefaultsSettings` reads); launch-at-login and Accessibility go through their adapters.
struct SettingsView: View {
    let permission: PermissionPort
    let loginItem: LoginItemService
    let hotkeys: HotkeyManager

    @AppStorage(UserDefaultsSettings.Key.notificationsEnabled) private var notificationsEnabled = false
    @State private var launchAtLogin = false
    @State private var accessibilityTrusted = false

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Show ✓ when cleaning", isOn: $notificationsEnabled)
                    .accessibilityLabel("Show confirmation when cleaning")
            }
            Section("Shortcuts") {
                HotkeyRecorderView(label: "Clean clipboard",
                                   initial: hotkeys.combo(for: .cleanClipboard)) { combo in
                    hotkeys.update(.cleanClipboard, to: combo)
                }
                HotkeyRecorderView(label: "Copy and clean",
                                   initial: hotkeys.combo(for: .copyAndClean)) { combo in
                    hotkeys.update(.copyAndClean, to: combo)
                }
            }
            Section("System") {
                Toggle("Open Repaste at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        loginItem.setEnabled(enabled)
                        launchAtLogin = loginItem.isEnabled
                    }
            }
            Section("Permissions") {
                LabeledContent("Accessibility (for Copy and clean)") {
                    let status: LocalizedStringKey = accessibilityTrusted ? "Granted" : "Not granted"
                    Text(status)
                        .foregroundStyle(accessibilityTrusted ? Color.green : Color.secondary)
                }
                if !accessibilityTrusted {
                    Button("Grant…") { permission.request() }
                }
            }
        }
        .formStyle(.grouped)
        // Explicit height: hosted in an NSWindow, a grouped Form with no defined height collapses to ~0.
        .frame(width: 380, height: 430)
        .onAppear { refresh() }
        // Returning from System Settings reactivates the app: we refresh what the user may have changed there.
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refresh()
        }
    }

    private func refresh() {
        launchAtLogin = loginItem.isEnabled
        accessibilityTrusted = permission.isAccessibilityTrusted
    }
}

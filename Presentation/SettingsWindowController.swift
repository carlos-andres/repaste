import AppKit
import SwiftUI
import RepasteCore

/// Owns the Settings window (created lazily and reused). The app is an accessory (no Dock), so on open
/// it must be activated for the window to receive focus and interaction.
@MainActor
final class SettingsWindowController {
    private let permission: PermissionPort
    private let loginItem: LoginItemService
    private let hotkeys: HotkeyManager
    private var window: NSWindow?

    init(permission: PermissionPort, loginItem: LoginItemService, hotkeys: HotkeyManager) {
        self.permission = permission
        self.loginItem = loginItem
        self.hotkeys = hotkeys
    }

    func show() {
        if window == nil {
            let hosting = NSHostingController(
                rootView: SettingsView(permission: permission, loginItem: loginItem, hotkeys: hotkeys))
            let w = NSWindow(contentViewController: hosting)
            w.title = String(localized: "Repaste Settings")
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        // Accessory app: we activate and force the front. `orderFrontRegardless` covers the case where macOS 14+
        // defers activation and the window would end up behind the open apps.
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }
}

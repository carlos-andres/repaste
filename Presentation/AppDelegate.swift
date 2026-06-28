import AppKit
import RepasteCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var settingsWindow: SettingsWindowController?
    // Owns the global hotkeys (Carbon registration): must live for as long as the app runs.
    private var hotkeys: HotkeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menubar agent: no Dock or app switcher. Reinforces the Info.plist's LSUIElement=true at runtime.
        NSApp.setActivationPolicy(.accessory)

        // Composition root: the only place that knows concrete adapters; everything else depends on ports.
        let bundleId = Bundle.main.bundleIdentifier ?? "com.calo.RePaste"
        let accessibility = AccessibilityGate()
        let loginItem = LoginItemService()
        let notifier = UserNotificationNotifier()
        notifier.requestAuthorization()
        let cleanClipboard = CleanClipboardUseCase(
            pasteboard: SystemPasteboard(),
            notifier: notifier,
            settings: UserDefaultsSettings(),
            pipeline: .canonicalV1(),
            bundleIdentifier: bundleId
        )
        let copyAndClean = CopyAndCleanUseCase(
            selection: SyntheticCopier(),
            permission: accessibility,
            cleanClipboard: cleanClipboard
        )

        // The Carbon hotkey delivers the event with no actor guarantee; the hop to @MainActor ensures the use case
        // (NSPasteboard/notifications) always runs on the main actor, without assuming Carbon's thread.
        let runPathA: () -> Void = { Task { @MainActor in _ = cleanClipboard.run() } }
        let runPathB: () -> Void = { Task { @MainActor in _ = copyAndClean.run() } }

        let hotkeys = HotkeyManager(store: HotkeyStore(),
                                    runCleanClipboard: runPathA, runCopyAndClean: runPathB)
        self.hotkeys = hotkeys
        hotkeys.registerAll()

        let settings = SettingsWindowController(permission: accessibility, loginItem: loginItem, hotkeys: hotkeys)
        settingsWindow = settings
        statusItemController = StatusItemController(cleanTrigger: MenuTrigger(run: runPathA),
                                                    copyAndCleanTrigger: MenuTrigger(run: runPathB),
                                                    openSettings: { settings.show() })
    }
}

import AppKit
import RepasteCore

/// Owns the menubar's NSStatusItem and its menu; delegates each action to an `ActivationTrigger`.
@MainActor
final class StatusItemController {
    private let statusItem: NSStatusItem
    private let cleanTrigger: ActivationTrigger
    private let copyAndCleanTrigger: ActivationTrigger
    private let openSettings: @MainActor () -> Void

    init(cleanTrigger: ActivationTrigger, copyAndCleanTrigger: ActivationTrigger,
         openSettings: @escaping @MainActor () -> Void) {
        self.cleanTrigger = cleanTrigger
        self.copyAndCleanTrigger = copyAndCleanTrigger
        self.openSettings = openSettings
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureButton()
        statusItem.menu = makeMenu()
    }

    private func configureButton() {
        guard let button = statusItem.button else { return }
        let image = NSImage(named: "MenubarIcon")
            ?? NSImage(systemSymbolName: "wand.and.sparkles", accessibilityDescription: "Repaste")
        image?.isTemplate = true
        button.image = image
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        let clean = NSMenuItem(title: String(localized: "Clean clipboard"),
                               action: #selector(cleanClipboard), keyEquivalent: "")
        clean.target = self
        menu.addItem(clean)
        let copyClean = NSMenuItem(title: String(localized: "Copy and clean"),
                                   action: #selector(copyAndCleanSelection), keyEquivalent: "")
        copyClean.target = self
        menu.addItem(copyClean)
        menu.addItem(.separator())
        let settings = NSMenuItem(title: String(localized: "Settings…"), action: #selector(showSettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(withTitle: String(localized: "Quit"),
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        return menu
    }

    @objc private func cleanClipboard() { cleanTrigger.activate() }
    @objc private func copyAndCleanSelection() { copyAndCleanTrigger.activate() }
    @objc private func showSettings() { openSettings() }
}

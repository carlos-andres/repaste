import AppKit
import Carbon.HIToolbox

/// Global hotkey in Carbon. `keyLabel` is captured at record time to show the key without a reverse
/// keycode→character mapping (which varies with the keyboard layout).
struct HotkeyCombo: Equatable {
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let keyLabel: String

    /// Modifiers in the conventional macOS order (⌃⌥⇧⌘).
    var display: String {
        var s = ""
        if carbonModifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if carbonModifiers & UInt32(optionKey)  != 0 { s += "⌥" }
        if carbonModifiers & UInt32(shiftKey)   != 0 { s += "⇧" }
        if carbonModifiers & UInt32(cmdKey)     != 0 { s += "⌘" }
        return s + keyLabel
    }

    /// Spoken form for VoiceOver: `display` uses glyphs (⌃⌥⌘) that the reader reads as meaningless Unicode
    /// names; here the modifiers go as words.
    var spokenDescription: String {
        var parts: [String] = []
        if carbonModifiers & UInt32(controlKey) != 0 { parts.append("Control") }
        if carbonModifiers & UInt32(optionKey)  != 0 { parts.append("Option") }
        if carbonModifiers & UInt32(shiftKey)   != 0 { parts.append("Shift") }
        if carbonModifiers & UInt32(cmdKey)     != 0 { parts.append("Command") }
        parts.append(keyLabel)
        return parts.joined(separator: " ")
    }
}

extension HotkeyCombo {
    /// Combo from a keyDown. Requires a "strong" modifier (⌃/⌥/⌘): a global hotkey with only ⇧ would clash
    /// with normal typing. `nil` = invalid combo → the recorder keeps listening.
    init?(event: NSEvent) {
        var carbon: UInt32 = 0
        let flags = event.modifierFlags
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        guard carbon & UInt32(controlKey | optionKey | cmdKey) != 0 else { return nil }
        let label = (event.charactersIgnoringModifiers ?? "").uppercased()
        // charactersIgnoringModifiers yields glyph-less sentinels for arrows/function keys (U+F700–U+F8FF) and
        // controls (Tab/Return/Delete): they'd show blank in the recorder. We only accept visible keys.
        guard !label.isEmpty, label.unicodeScalars.allSatisfy(HotkeyCombo.isVisibleKey) else { return nil }
        self.init(keyCode: UInt32(event.keyCode), carbonModifiers: carbon, keyLabel: label)
    }

    /// `false` for keys with no visible glyph: ASCII/C1 controls and the arrow/function-key range.
    private static func isVisibleKey(_ s: Unicode.Scalar) -> Bool {
        s.value >= 0x20 && !(0x7F...0x9F).contains(s.value) && !(0xF700...0xF8FF).contains(s.value)
    }

    static let cleanClipboardDefault = HotkeyCombo(
        keyCode: UInt32(kVK_ANSI_V), carbonModifiers: UInt32(controlKey | optionKey | cmdKey), keyLabel: "V")
    static let copyAndCleanDefault = HotkeyCombo(
        keyCode: UInt32(kVK_ANSI_C), carbonModifiers: UInt32(controlKey | shiftKey | cmdKey), keyLabel: "C")

    /// Esc cancels recording; comparing the keyCode (not the character) keeps it stable across layouts.
    static func isEscape(_ keyCode: UInt16) -> Bool { keyCode == UInt16(kVK_Escape) }
}

enum HotkeyPath {
    case cleanClipboard, copyAndClean

    /// Carbon hotkey id: distinguishes which hotkey was pressed when the event arrives.
    var carbonID: UInt32 { self == .cleanClipboard ? 1 : 2 }

    var defaultCombo: HotkeyCombo {
        self == .cleanClipboard ? .cleanClipboardDefault : .copyAndCleanDefault
    }

    var defaultsKeyPrefix: String {
        self == .cleanClipboard ? "hotkeyCleanClipboard" : "hotkeyCopyAndClean"
    }

    /// The other path: two hotkeys with the same combo clobber each other in Carbon, so `update` checks it.
    var other: HotkeyPath { self == .cleanClipboard ? .copyAndClean : .cleanClipboard }
}

/// Persists the combos in UserDefaults; falls back to the default when the path hasn't been recorded yet.
final class HotkeyStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func combo(for path: HotkeyPath) -> HotkeyCombo {
        let k = HotkeyStore.keys(for: path)
        // We require all 3 keys: a partial record would show a combo with the label out of sync with the keycode.
        guard defaults.object(forKey: k.code) != nil,
              defaults.object(forKey: k.mods) != nil,
              let label = defaults.string(forKey: k.label) else { return path.defaultCombo }
        return HotkeyCombo(keyCode: UInt32(defaults.integer(forKey: k.code)),
                           carbonModifiers: UInt32(defaults.integer(forKey: k.mods)),
                           keyLabel: label)
    }

    func set(_ combo: HotkeyCombo, for path: HotkeyPath) {
        let k = HotkeyStore.keys(for: path)
        defaults.set(Int(combo.keyCode), forKey: k.code)
        defaults.set(Int(combo.carbonModifiers), forKey: k.mods)
        defaults.set(combo.keyLabel, forKey: k.label)
    }

    private static func keys(for path: HotkeyPath) -> (code: String, mods: String, label: String) {
        let p = path.defaultsKeyPrefix
        return ("\(p).keyCode", "\(p).modifiers", "\(p).label")
    }
}

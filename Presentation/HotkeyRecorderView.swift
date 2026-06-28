import SwiftUI

/// Recorder model, `@MainActor` so it can be captured safely in the event-monitor closure.
/// While recording it listens for the next keyDown; the caller's `onChange` persists and returns whether it accepted the combo.
@MainActor @Observable
final class HotkeyRecorderModel {
    private(set) var combo: HotkeyCombo
    private(set) var recording = false
    private var monitor: Any?
    private let onChange: (HotkeyCombo) -> Bool

    init(initial: HotkeyCombo, onChange: @escaping (HotkeyCombo) -> Bool) {
        self.combo = initial
        self.onChange = onChange
    }

    func toggle() { recording ? stop() : start() }

    /// Stops recording if the window closes mid-way; otherwise the monitor would stay installed for the app's lifetime.
    func cancel() { if recording { stop() } }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
            return nil   // nil swallows the event: the combo must not fire or be inserted as text while recording
        }
    }

    private func handle(_ event: NSEvent) {
        if HotkeyCombo.isEscape(event.keyCode) { stop(); return }
        guard let captured = HotkeyCombo(event: event) else { return }
        stop()
        if onChange(captured) { combo = captured }
    }

    private func stop() {
        recording = false
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

/// Settings row for recording a keyboard shortcut.
struct HotkeyRecorderView: View {
    let label: LocalizedStringKey
    @State private var model: HotkeyRecorderModel

    init(label: LocalizedStringKey, initial: HotkeyCombo, onChange: @escaping (HotkeyCombo) -> Bool) {
        self.label = label
        _model = State(initialValue: HotkeyRecorderModel(initial: initial, onChange: onChange))
    }

    var body: some View {
        LabeledContent(label) {
            // The combo (⌃⌥⌘V) is a non-translatable symbol → verbatim; only "Listening…" goes through String(localized:).
            Button(model.recording ? String(localized: "Listening… (Esc cancels)") : model.combo.display) {
                model.toggle()
            }
            .frame(minWidth: 170)
            // VoiceOver would read the combo's glyphs as Unicode names; we announce the spoken form instead.
            .accessibilityLabel(model.recording
                ? Text("Listening for a shortcut, Escape cancels")
                : Text(model.combo.spokenDescription))
        }
        .onDisappear { model.cancel() }
    }
}

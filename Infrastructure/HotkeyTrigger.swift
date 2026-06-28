import Carbon.HIToolbox
import RepasteCore
import os

/// Global hotkey (Carbon `RegisterEventHotKey`) that fires an activation — Path A or Path B depending on the closure.
/// Lives in Infra because Carbon is a system framework; the composition root picks the closure, not the combination.
final class HotkeyTrigger: ActivationTrigger {
    private static let log = Logger(subsystem: "com.calo.RePaste", category: "hotkey")
    private let run: () -> Void
    private let hotKeyID: EventHotKeyID
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    /// `id` must be unique across triggers: distinguishes which hotkey was pressed when Carbon delivers the event.
    init(keyCode: UInt32, modifiers: UInt32, id: UInt32, run: @escaping () -> Void) {
        self.run = run
        self.hotKeyID = EventHotKeyID(signature: HotkeyTrigger.signature, id: id)
        register(keyCode: keyCode, modifiers: modifiers)
    }

    convenience init(combo: HotkeyCombo, id: UInt32, run: @escaping () -> Void) {
        self.init(keyCode: combo.keyCode, modifiers: combo.carbonModifiers, id: id, run: run)
    }

    func activate() { run() }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }

    private static let signature: OSType = 0x52505354 // 'RPST'

    private func register(keyCode: UInt32, modifiers: UInt32) {
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let handlerStatus = InstallEventHandler(GetApplicationEventTarget(), hotkeyHandler, 1, &eventSpec,
                                                Unmanaged.passUnretained(self).toOpaque(), &handlerRef)
        let hotKeyStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        // Without this, a combo the system rejects (e.g. already taken by another app) leaves the hotkey mute with no diagnostic.
        if handlerStatus != noErr || hotKeyStatus != noErr {
            Self.log.error("hotkey id=\(self.hotKeyID.id) registration failed: handler=\(handlerStatus) hotkey=\(hotKeyStatus)")
        }
    }

    /// `true` = the event was this trigger's (Carbon stops dispatching); `false` = let it try the others.
    fileprivate func fire(if firedID: EventHotKeyID) -> Bool {
        guard firedID.id == hotKeyID.id, firedID.signature == hotKeyID.signature else { return false }
        activate()
        return true
    }
}

/// Carbon calls this handler (C, no capture) for every hotkey; `userData` carries the trigger that installed it.
private func hotkeyHandler(_ call: EventHandlerCallRef?, _ event: EventRef?,
                           _ userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var firedID = EventHotKeyID()
    let status = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                   EventParamType(typeEventHotKeyID), nil,
                                   MemoryLayout<EventHotKeyID>.size, nil, &firedID)
    guard status == noErr else { return OSStatus(eventNotHandledErr) }
    let trigger = Unmanaged<HotkeyTrigger>.fromOpaque(userData).takeUnretainedValue()
    return trigger.fire(if: firedID) ? noErr : OSStatus(eventNotHandledErr)
}

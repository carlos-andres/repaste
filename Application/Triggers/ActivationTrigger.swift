/// A cleaning activation (menu item, global hotkey). Adding or removing activations doesn't touch the
/// use cases. The hotkey triggers (Carbon) live in Infra; `MenuTrigger` is pure.
public protocol ActivationTrigger {
    func activate()
}

/// Menu-item activation: runs the associated action (Path A or Path B) when the user selects it.
/// Pure (no AppKit): Presentation's `NSMenu` invokes `activate()`.
public final class MenuTrigger: ActivationTrigger {
    private let run: () -> Void

    public init(run: @escaping () -> Void) { self.run = run }

    public func activate() { run() }
}

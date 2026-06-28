import XCTest
import RepasteCore

@MainActor
final class CopyAndCleanUseCaseTests: XCTestCase {
    private let bundleId = "com.calo.RePaste"

    // MARK: - Port test doubles

    private final class MockPasteboard: PasteboardPort {
        var content: PasteboardContent
        private(set) var written: (text: String, source: String)?
        private(set) var readCount = 0
        init(_ content: PasteboardContent) { self.content = content }
        func read() -> PasteboardContent { readCount += 1; return content }
        func write(_ text: String, source: String) { written = (text, source) }
    }

    private final class MockNotifier: NotifierPort {
        private(set) var outcomes: [CleanOutcome] = []
        private(set) var commands: [CleanCommand] = []
        func notify(_ outcome: CleanOutcome, command: CleanCommand) {
            outcomes.append(outcome); commands.append(command)
        }
    }

    private struct StubSettings: SettingsPort {
        var options: CleaningOptions = .default
        var notificationsEnabled: Bool = true
    }

    private final class MockSelection: SelectionPort {
        var result: Bool
        var onCopy: (() -> Void)?              // simulates the copy changing the clipboard
        private(set) var copyCount = 0
        init(result: Bool) { self.result = result }
        func copySelection() -> Bool { copyCount += 1; onCopy?(); return result }
    }

    private final class MockPermission: PermissionPort {
        var isAccessibilityTrusted: Bool
        private(set) var requestCount = 0
        init(trusted: Bool) { isAccessibilityTrusted = trusted }
        func request() { requestCount += 1 }
    }

    private func makeCleanClipboard(_ pb: MockPasteboard, _ nt: MockNotifier) -> CleanClipboardUseCase {
        CleanClipboardUseCase(pasteboard: pb, notifier: nt, settings: StubSettings(),
                              pipeline: .canonicalV1(), bundleIdentifier: bundleId)
    }

    // MARK: - With permission (copies the selection, then cleans)

    func testTrustedCopiesSelectionThenCleansTheCopiedText() {
        let pb = MockPasteboard(PasteboardContent(text: "stale", isProtected: false))
        let nt = MockNotifier()
        let sel = MockSelection(result: true)
        sel.onCopy = { pb.content = PasteboardContent(text: "fresh   \nsel   ", isProtected: false) }
        let perm = MockPermission(trusted: true)
        let useCase = CopyAndCleanUseCase(selection: sel, permission: perm,
                                          cleanClipboard: makeCleanClipboard(pb, nt))

        let outcome = useCase.run()

        XCTAssertEqual(sel.copyCount, 1)               // tries to copy the selection
        XCTAssertEqual(perm.requestCount, 0)           // permission already granted: doesn't re-request
        XCTAssertEqual(pb.readCount, 1)                // cleans only once
        XCTAssertEqual(pb.written?.text, "fresh\nsel") // cleans the just-copied text, not the old one
        guard case .cleaned = outcome else { return XCTFail("expected .cleaned") }
    }

    func testTrustedButCopyFailsStillCleansExistingClipboard() {
        // Deliberate fallback: with permission but no new copy, cleaning what's already on the clipboard
        // is more useful than a silent no-op.
        let pb = MockPasteboard(PasteboardContent(text: "dirty   ", isProtected: false))
        let nt = MockNotifier()
        let sel = MockSelection(result: false)         // synthetic ⌘C didn't change the clipboard
        let perm = MockPermission(trusted: true)
        let useCase = CopyAndCleanUseCase(selection: sel, permission: perm,
                                          cleanClipboard: makeCleanClipboard(pb, nt))

        let outcome = useCase.run()

        XCTAssertEqual(sel.copyCount, 1)
        XCTAssertEqual(perm.requestCount, 0)
        XCTAssertEqual(pb.readCount, 1)
        XCTAssertEqual(pb.written?.text, "dirty")      // cleans what was already there
        guard case .cleaned = outcome else { return XCTFail("expected .cleaned") }
    }

    func testTrustedCopiedContentProtectedIsNotWritten() {
        // If the just-copied selection turns out protected (e.g. a password manager), the fallback's
        // pre-check respects it: nothing is written.
        let pb = MockPasteboard(PasteboardContent(text: "stale", isProtected: false))
        let nt = MockNotifier()
        let sel = MockSelection(result: true)
        sel.onCopy = { pb.content = PasteboardContent(text: "s3cr3t", isProtected: true) }
        let perm = MockPermission(trusted: true)
        let useCase = CopyAndCleanUseCase(selection: sel, permission: perm,
                                          cleanClipboard: makeCleanClipboard(pb, nt))

        let outcome = useCase.run()

        XCTAssertEqual(sel.copyCount, 1)
        XCTAssertNil(pb.written)                       // protected content is left untouched
        XCTAssertEqual(outcome, .protected)
        XCTAssertEqual(nt.commands, [.copyAndClean])   // protected always notifies, and as Path B
    }

    // MARK: - Without permission (fallback: cleans the current clipboard)

    func testNotTrustedRequestsPermissionAndFallsBackToClean() {
        let pb = MockPasteboard(PasteboardContent(text: "dirty   ", isProtected: false))
        let nt = MockNotifier()
        let sel = MockSelection(result: true)
        let perm = MockPermission(trusted: false)
        let useCase = CopyAndCleanUseCase(selection: sel, permission: perm,
                                          cleanClipboard: makeCleanClipboard(pb, nt))

        let outcome = useCase.run()

        XCTAssertEqual(perm.requestCount, 1)           // requests permission (guide + deep-link in the adapter)
        XCTAssertEqual(sel.copyCount, 0)               // without permission it doesn't attempt the synthetic ⌘C
        XCTAssertEqual(pb.readCount, 1)
        XCTAssertEqual(pb.written?.text, "dirty")      // fallback: cleans the current clipboard
        guard case .cleaned = outcome else { return XCTFail("expected .cleaned") }
    }

    func testNotTrustedFallbackHonorsProtectedPreCheck() {
        let pb = MockPasteboard(PasteboardContent(text: "s3cr3t", isProtected: true))
        let nt = MockNotifier()
        let sel = MockSelection(result: true)
        let perm = MockPermission(trusted: false)
        let useCase = CopyAndCleanUseCase(selection: sel, permission: perm,
                                          cleanClipboard: makeCleanClipboard(pb, nt))

        let outcome = useCase.run()

        XCTAssertEqual(perm.requestCount, 1)
        XCTAssertEqual(sel.copyCount, 0)
        XCTAssertNil(pb.written)                       // the fallback's pre-check protects the content
        XCTAssertEqual(outcome, .protected)
    }

    // MARK: - Different feedback per path

    func testNotifiesAsCopyAndCleanCommand() {
        // Path B must be notified as copy-and-clean (HUD "Text cleaned"), not as Path A, even though it reuses
        // CleanClipboardUseCase internally.
        let pb = MockPasteboard(PasteboardContent(text: "dirty   ", isProtected: false))
        let nt = MockNotifier()
        let sel = MockSelection(result: true)
        let perm = MockPermission(trusted: true)
        let useCase = CopyAndCleanUseCase(selection: sel, permission: perm,
                                          cleanClipboard: makeCleanClipboard(pb, nt))

        _ = useCase.run()

        XCTAssertEqual(nt.commands, [.copyAndClean])
    }

    func testFallbackToPathAStillNotifiesAsCopyAndClean() {
        // Without permission we fall back to cleaning the clipboard, but the user invoked "Copy and clean":
        // the feedback must reflect the invoked command, not the internal fallback.
        let pb = MockPasteboard(PasteboardContent(text: "dirty   ", isProtected: false))
        let nt = MockNotifier()
        let sel = MockSelection(result: true)
        let perm = MockPermission(trusted: false)
        let useCase = CopyAndCleanUseCase(selection: sel, permission: perm,
                                          cleanClipboard: makeCleanClipboard(pb, nt))

        _ = useCase.run()

        XCTAssertEqual(nt.commands, [.copyAndClean])
    }
}

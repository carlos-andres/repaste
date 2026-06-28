import XCTest
import RepasteCore

@MainActor
final class CleanClipboardUseCaseTests: XCTestCase {
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

    private func makeUseCase(_ pb: MockPasteboard, _ nt: MockNotifier,
                             _ settings: StubSettings = StubSettings()) -> CleanClipboardUseCase {
        CleanClipboardUseCase(pasteboard: pb, notifier: nt, settings: settings,
                              pipeline: .canonicalV1(), bundleIdentifier: bundleId)
    }

    // MARK: - Pre-check

    func testProtectedContentAbortsWithoutWriting() {
        let pb = MockPasteboard(PasteboardContent(text: "s3cr3t", isProtected: true))
        let nt = MockNotifier()
        let outcome = makeUseCase(pb, nt).run()
        XCTAssertEqual(outcome, .protected)
        XCTAssertNil(pb.written)                 // protected content is never written
        XCTAssertEqual(nt.outcomes, [.protected])
    }

    func testNoPlainTextIsNoOp() {
        let pb = MockPasteboard(PasteboardContent(text: nil, isProtected: false))
        let nt = MockNotifier()
        let outcome = makeUseCase(pb, nt).run()
        XCTAssertEqual(outcome, .empty)
        XCTAssertNil(pb.written)
        XCTAssertTrue(nt.outcomes.isEmpty)       // silent no-op: nothing to clean means no notification
    }

    func testWhitespaceOnlyIsNoOp() {
        let pb = MockPasteboard(PasteboardContent(text: "   \n\t ", isProtected: false))
        let nt = MockNotifier()
        let outcome = makeUseCase(pb, nt).run()
        XCTAssertEqual(outcome, .empty)
        XCTAssertNil(pb.written)
        XCTAssertTrue(nt.outcomes.isEmpty)       // silent no-op: nothing to clean means no notification
    }

    // MARK: - Happy path

    func testHappyPathWritesCleanedTextWithSource() {
        let pb = MockPasteboard(PasteboardContent(text: "hi   \nthere   ", isProtected: false))
        let nt = MockNotifier()
        let outcome = makeUseCase(pb, nt).run()

        XCTAssertEqual(pb.readCount, 1)                      // reads the clipboard once
        XCTAssertEqual(pb.written?.text, "hi\nthere")        // trailing whitespace cleaned by the pipeline
        XCTAssertEqual(pb.written?.source, bundleId)         // source = our own bundle id
        guard case .cleaned(let result) = outcome else { return XCTFail("expected .cleaned") }
        XCTAssertEqual(result.text, "hi\nthere")
        XCTAssertEqual(result.outputLineCount, 2)
        XCTAssertEqual(nt.outcomes, [outcome])               // notifies success
    }

    func testSuccessNotificationGatedByToggle() {
        let pb = MockPasteboard(PasteboardContent(text: "hi   \nthere   ", isProtected: false))
        let nt = MockNotifier()
        let outcome = makeUseCase(pb, nt, StubSettings(notificationsEnabled: false)).run()

        XCTAssertEqual(pb.written?.text, "hi\nthere")        // it still writes
        if case .cleaned = outcome {} else { XCTFail("expected .cleaned") }
        XCTAssertTrue(nt.outcomes.isEmpty)                   // but doesn't notify success
    }

    func testDefaultCommandIsCleanClipboard() {
        let pb = MockPasteboard(PasteboardContent(text: "hi   ", isProtected: false))
        let nt = MockNotifier()
        _ = makeUseCase(pb, nt).run()
        XCTAssertEqual(nt.commands, [.cleanClipboard])   // no explicit command = Path A (the default)
    }

    // The use case must forward Settings' toggles to the pipeline (here: prompts ON strips the `$ `).
    func testForwardsSettingsOptionsToPipeline() {
        let pb = MockPasteboard(PasteboardContent(text: "$ echo hi\noutput", isProtected: false))
        let nt = MockNotifier()
        let settings = StubSettings(options: CleaningOptions(stripShellPrompts: true))
        _ = makeUseCase(pb, nt, settings).run()
        XCTAssertEqual(pb.written?.text, "echo hi\noutput")
    }
}

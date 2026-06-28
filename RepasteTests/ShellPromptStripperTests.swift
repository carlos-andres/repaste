import XCTest
import RepasteCore

final class ShellPromptStripperTests: XCTestCase {
    private let stage = ShellPromptStripper()
    private func strip(_ s: String) -> String { stage.apply(s, CleaningOptions(stripShellPrompts: true)) }
    private func off(_ s: String) -> String { stage.apply(s, .default) }

    // OFF by default: the stage is destructive (it would eat a markdown blockquote), only acts on opt-in.
    func testOffByDefaultIsNoOp() {
        XCTAssertEqual(off("$ echo hi"), "$ echo hi")
        XCTAssertEqual(off("user@host:~/p$ ls"), "user@host:~/p$ ls")
    }

    // Pattern 1: user@host:path$ prompt (with and without venv/conda; with root's #).
    func testStripsUserHostPrompt() {
        XCTAssertEqual(strip("user@host:~/proj$ ls -la"), "ls -la")
        XCTAssertEqual(strip("(myenv) user@host:~/proj$ git status"), "git status")
        XCTAssertEqual(strip("root@box:/var/log# tail -f x"), "tail -f x")
    }

    // Patterns 2/3: PowerShell and cmd.exe.
    func testStripsWindowsPrompts() {
        XCTAssertEqual(strip(#"PS C:\Users\me> Get-ChildItem"#), "Get-ChildItem")
        XCTAssertEqual(strip(#"C:\Users\me> dir"#), "dir")
    }

    // Patterns 4/5/6: REPLs (python, irb, mysql).
    func testStripsReplPrompts() {
        XCTAssertEqual(strip(">>> print(1)"), "print(1)")
        XCTAssertEqual(strip("irb(main):001:0> puts 1"), "puts 1")
        XCTAssertEqual(strip("mysql> SELECT 1;"), "SELECT 1;")
    }

    // Pattern 7: generic $ # % > prompt (with venv). The '> ' shows why the stage is OFF by default.
    func testStripsGenericPrompts() {
        XCTAssertEqual(strip("$ echo hi"), "echo hi")
        XCTAssertEqual(strip("# whoami"), "whoami")
        XCTAssertEqual(strip("(venv) $ pip install x"), "pip install x")
        XCTAssertEqual(strip("> quote note"), "quote note")
    }

    // If no content remains after removing the prompt (trim==""), the whole line is dropped.
    func testEmptyAfterPromptDropsLine() {
        XCTAssertEqual(strip("$ "), "")
        XCTAssertEqual(strip("$"), "")
        XCTAssertEqual(strip(">>>"), "")
    }

    func testDroppedLineRemovedFromMultiline() {
        XCTAssertEqual(strip("$ ls\n$ \noutput"), "ls\noutput")
    }

    // A blank line is preserved even when empty-prompt lines around it are dropped.
    func testBlankLinePreservedWhilePromptOnlyDropped() {
        XCTAssertEqual(strip("$ a\n\n$ \nb"), "a\n\nb")
    }

    // The content after the prompt (non-ASCII included) survives the UTF-16 offset cut intact.
    func testPreservesNonAsciiAfterPrompt() {
        XCTAssertEqual(strip("$ echo → café \u{258E}"), "echo → café \u{258E}")
    }

    // Line with no prompt: intact. Blank line: intact (not dropped; only empty prompts are dropped).
    func testNonPromptLineUnchanged() {
        XCTAssertEqual(strip("just some text"), "just some text")
        XCTAssertEqual(strip("plain\n\nmore"), "plain\n\nmore")
    }

    // The pattern order is load-bearing: the full host prompt is removed (pattern 1), not a sub-prefix.
    func testFirstMatchStripsFullHostPrompt() {
        XCTAssertEqual(strip("dev@srv:~/a/b$ make build"), "make build")
    }
}

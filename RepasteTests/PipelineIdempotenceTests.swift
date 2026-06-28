import XCTest
import RepasteCore

/// Hard engine invariant: `clean(clean(x)) == clean(x)` over all fixtures.
/// Runs the production pipeline (`canonicalV1`, stages 1-9 and 11). Prompts (7) defaults OFF.
final class PipelineIdempotenceTests: XCTestCase {
    private let pipeline = CleaningPipeline.canonicalV1()

    private let fixtures = [
        "abcdef\rXY",
        "100%\rdone",
        "Loading...\rOK",
        "\u{258E} quoted line\r\nplain\r\n\u{2502} table \u{2502}",
        "\u{1B}[31mred\u{1B}[0m\r\ndone   ",
        "X\u{08}Y\thi\u{1B}[0m",
        "a\r\nb\rc",
        // OSC start and its BEL terminator sit on separate lines: the lazy OSC regex can't cross \n, so it
        // survives. Line 1 must stay under the reflow length threshold, or the two lines join and a later pass strips it.
        "\u{1B}]0;osc with no ST here\nbody\u{07}",
        "nothing to clean",
        "  a\n  b\n  c",
        "$ echo hi\noutput line",
        "This is a long wrapped paragraph that the terminal split\nacross several visual lines and should reflow into one line.",
        "- bullet item that is quite long and wraps onto the very next\n  visual line of the narrow terminal window over on the right",
        "",
    ]

    // Prompts (stage 7) drops lines → changes the count the dedent (stage 9) sees; idempotence
    // must hold with the destructive stage enabled too.
    private let promptFixtures = [
        "user@host:~/proj$ ls -la\ntotal 8",
        "$ git status\nOn branch main\nnothing to commit",
        "(venv) $ pip install requests\nCollecting requests",
        ">>> 1+1\n2",
        "$ \noutput after empty prompt",
        "PS C:\\Users\\me> dir\nVolume",
    ]

    func testIdempotentOverAllFixtures() {
        for input in fixtures {
            let once = pipeline.clean(input).text
            let twice = pipeline.clean(once).text
            XCTAssertEqual(once, twice, "Not idempotent for: \(input.debugDescription)")
        }
    }

    func testIdempotentWithPromptsOn() {
        let options = CleaningOptions(stripShellPrompts: true)
        for input in promptFixtures {
            let once = pipeline.clean(input, options: options).text
            let twice = pipeline.clean(once, options: options).text
            XCTAssertEqual(once, twice, "Not idempotent (prompts ON) for: \(input.debugDescription)")
        }
    }

    func testLineCountsReported() {
        let result = pipeline.clean("a\nb\nc")
        XCTAssertEqual(result.inputLineCount, 3)
        XCTAssertEqual(result.outputLineCount, 3)
    }
}

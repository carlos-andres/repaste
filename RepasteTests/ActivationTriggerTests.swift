import XCTest
import RepasteCore

final class ActivationTriggerTests: XCTestCase {
    func testMenuTriggerRunsActionOnActivate() {
        var fired = 0
        let trigger: ActivationTrigger = MenuTrigger(run: { fired += 1 })
        trigger.activate()
        XCTAssertEqual(fired, 1)
    }

    func testMenuTriggerRunsActionEachTimeItIsActivated() {
        var fired = 0
        let trigger = MenuTrigger(run: { fired += 1 })
        trigger.activate()
        trigger.activate()
        XCTAssertEqual(fired, 2)
    }
}

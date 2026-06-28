import XCTest
import RepasteCore

final class UserDefaultsSettingsTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "test.repaste.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testDefaultsWhenNothingStored() {
        let settings = UserDefaultsSettings(defaults: defaults)
        XCTAssertFalse(settings.notificationsEnabled)      // visual aid OFF by default
        XCTAssertFalse(settings.options.stripShellPrompts) // prompts OFF (destructive)
        XCTAssertFalse(settings.options.markdownFormatter) // markdown OFF (v2)
        XCTAssertEqual(settings.options.tabWidth, 4)       // tabs → 4 spaces
    }

    func testReadsStoredValues() {
        defaults.set(true, forKey: "notificationsEnabled")
        defaults.set(true, forKey: "stripShellPrompts")
        defaults.set(8, forKey: "tabWidth")

        let settings = UserDefaultsSettings(defaults: defaults)
        XCTAssertTrue(settings.notificationsEnabled)
        XCTAssertTrue(settings.options.stripShellPrompts)
        XCTAssertEqual(settings.options.tabWidth, 8)
    }
}

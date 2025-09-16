import XCTest

final class ExerciseUITestsBasic: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launch()
    }

    override func tearDownWithError() throws {
        self.app = nil
    }

    func testAppLaunches() throws {
        // Simple test to verify the app launches
        XCTAssertTrue(self.app.exists)
    }
}

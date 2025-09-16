import XCTest

final class ExerciseUITestsBasic: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testAppLaunches() throws {
        // Simple test to verify the app launches
        XCTAssertTrue(app.exists)
    }
}
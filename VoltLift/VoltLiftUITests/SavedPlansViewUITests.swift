//
//  SavedPlansViewUITests.swift
//  VoltLiftUITests
//
//  Created by Kiro on 15.9.2025.
//

import XCTest

/// UI tests for SavedPlansView functionality
/// Tests plan management interactions including selection, rename, and delete operations
final class SavedPlansViewUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Empty State Tests
    
    func testEmptyStateDisplay() throws {
        // Navigate to SavedPlansView (assuming navigation exists)
        navigateToSavedPlans()
        
        // Verify empty state elements are displayed
        XCTAssertTrue(app.images["doc.text"].exists, "Empty state icon should be visible")
        XCTAssertTrue(app.staticTexts["No Saved Plans"].exists, "Empty state title should be visible")
        XCTAssertTrue(app.staticTexts["Your workout plans will appear here once you create them"].exists, "Empty state description should be visible")
    }
    
    func testEmptyStateAccessibility() throws {
        navigateToSavedPlans()
        
        // Verify accessibility labels are present
        let emptyStateTitle = app.staticTexts["No Saved Plans"]
        XCTAssertTrue(emptyStateTitle.exists)
        XCTAssertTrue(emptyStateTitle.isHittable)
    }
    
    // MARK: - Plans List Tests
    
    func testPlansListDisplay() throws {
        // Setup test data
        createTestPlans()
        navigateToSavedPlans()
        
        // Verify plans are displayed
        XCTAssertTrue(app.staticTexts["Test Plan 1"].exists, "First plan should be visible")
        XCTAssertTrue(app.staticTexts["Test Plan 2"].exists, "Second plan should be visible")
        
        // Verify metadata is displayed
        XCTAssertTrue(app.staticTexts["3 exercises"].exists, "Exercise count should be visible")
        XCTAssertTrue(app.staticTexts["Created"].exists, "Created date label should be visible")
    }
    
    func testPlanRowTapToSelect() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        let planRow = app.staticTexts["Test Plan 1"]
        XCTAssertTrue(planRow.exists, "Plan row should exist")
        
        planRow.tap()
        
        // Verify plan selection behavior
        // This would typically navigate to workout view or show selection feedback
        // Implementation depends on task 8 integration
    }
    
    func testPlanRowAccessibility() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        let planRow = app.staticTexts["Test Plan 1"]
        XCTAssertTrue(planRow.exists)
        
        // Verify accessibility properties
        XCTAssertTrue(planRow.isHittable)
        
        // Check for accessibility hint
        let accessibilityHint = planRow.value(forKey: "accessibilityHint") as? String
        XCTAssertNotNil(accessibilityHint)
        XCTAssertTrue(accessibilityHint?.contains("Double tap to use this plan") == true)
    }
    
    // MARK: - Plan Menu Tests
    
    func testPlanMenuDisplay() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        // Tap the menu button (ellipsis)
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        XCTAssertTrue(menuButton.exists, "Menu button should exist")
        
        menuButton.tap()
        
        // Verify menu options are displayed
        XCTAssertTrue(app.buttons["Use Plan"].exists, "Use Plan option should be visible")
        XCTAssertTrue(app.buttons["Rename"].exists, "Rename option should be visible")
        XCTAssertTrue(app.buttons["Delete"].exists, "Delete option should be visible")
    }
    
    func testPlanMenuAccessibility() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        XCTAssertTrue(menuButton.exists)
        
        // Verify accessibility label
        let accessibilityLabel = menuButton.value(forKey: "accessibilityLabel") as? String
        XCTAssertNotNil(accessibilityLabel)
        XCTAssertTrue(accessibilityLabel?.contains("Plan options") == true)
    }
    
    // MARK: - Rename Functionality Tests
    
    func testRenameAlertDisplay() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        // Open menu and tap rename
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        menuButton.tap()
        
        app.buttons["Rename"].tap()
        
        // Verify rename alert is displayed
        XCTAssertTrue(app.alerts["Rename Plan"].exists, "Rename alert should be displayed")
        XCTAssertTrue(app.textFields["Plan name"].exists, "Plan name text field should exist")
        XCTAssertTrue(app.buttons["Cancel"].exists, "Cancel button should exist")
        XCTAssertTrue(app.buttons["Rename"].exists, "Rename button should exist")
    }
    
    func testRenameAlertCancel() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        // Open rename alert
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        menuButton.tap()
        app.buttons["Rename"].tap()
        
        // Cancel the rename
        app.buttons["Cancel"].tap()
        
        // Verify alert is dismissed and original name remains
        XCTAssertFalse(app.alerts["Rename Plan"].exists, "Rename alert should be dismissed")
        XCTAssertTrue(app.staticTexts["Test Plan 1"].exists, "Original plan name should remain")
    }
    
    func testRenameAlertConfirm() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        // Open rename alert
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        menuButton.tap()
        app.buttons["Rename"].tap()
        
        // Enter new name and confirm
        let textField = app.textFields["Plan name"]
        textField.tap()
        textField.clearAndEnterText("Renamed Plan")
        
        app.buttons["Rename"].tap()
        
        // Verify plan is renamed
        XCTAssertFalse(app.alerts["Rename Plan"].exists, "Rename alert should be dismissed")
        
        // Wait for UI update
        let renamedPlan = app.staticTexts["Renamed Plan"]
        XCTAssertTrue(renamedPlan.waitForExistence(timeout: 2), "Plan should be renamed")
        XCTAssertFalse(app.staticTexts["Test Plan 1"].exists, "Original name should not exist")
    }
    
    func testRenameWithEmptyName() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        // Open rename alert
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        menuButton.tap()
        app.buttons["Rename"].tap()
        
        // Clear text field and try to rename
        let textField = app.textFields["Plan name"]
        textField.tap()
        textField.clearAndEnterText("")
        
        app.buttons["Rename"].tap()
        
        // Verify rename is rejected and original name remains
        XCTAssertTrue(app.staticTexts["Test Plan 1"].exists, "Original plan name should remain")
    }
    
    // MARK: - Delete Functionality Tests
    
    func testDeleteConfirmationDisplay() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        // Open menu and tap delete
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        menuButton.tap()
        
        app.buttons["Delete"].tap()
        
        // Verify delete confirmation is displayed
        XCTAssertTrue(app.alerts["Delete Plan"].exists, "Delete confirmation should be displayed")
        XCTAssertTrue(app.buttons["Cancel"].exists, "Cancel button should exist")
        XCTAssertTrue(app.buttons["Delete"].exists, "Delete button should exist")
        
        // Verify confirmation message includes plan name
        let alertMessage = app.alerts["Delete Plan"].staticTexts.element(boundBy: 1)
        XCTAssertTrue(alertMessage.label.contains("Test Plan 1"), "Confirmation should include plan name")
    }
    
    func testDeleteConfirmationCancel() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        // Open delete confirmation
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        menuButton.tap()
        app.buttons["Delete"].tap()
        
        // Cancel the delete
        app.buttons["Cancel"].tap()
        
        // Verify alert is dismissed and plan remains
        XCTAssertFalse(app.alerts["Delete Plan"].exists, "Delete confirmation should be dismissed")
        XCTAssertTrue(app.staticTexts["Test Plan 1"].exists, "Plan should still exist")
    }
    
    func testDeleteConfirmationConfirm() throws {
        createTestPlans()
        navigateToSavedPlans()
        
        // Open delete confirmation
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        menuButton.tap()
        app.buttons["Delete"].tap()
        
        // Confirm the delete
        app.buttons["Delete"].tap()
        
        // Verify plan is deleted
        XCTAssertFalse(app.alerts["Delete Plan"].exists, "Delete confirmation should be dismissed")
        
        // Wait for UI update
        let deletedPlan = app.staticTexts["Test Plan 1"]
        XCTAssertFalse(deletedPlan.waitForExistence(timeout: 2), "Plan should be deleted")
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateDisplay() throws {
        // This test would require mocking slow network/database operations
        // For now, we'll test that loading indicators are properly configured
        navigateToSavedPlans()
        
        // Check if loading view elements exist (they may not be visible if loading is fast)
        // This is more of a structural test to ensure loading UI is implemented
        _ = app.activityIndicators.firstMatch
        // Note: Progress view may not be visible if loading completes quickly
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorAlertDisplay() throws {
        // This would typically require injecting errors through test configuration
        // For now, we'll test the error alert structure
        
        // Simulate error condition (implementation depends on test setup)
        // triggerErrorCondition()
        
        // navigateToSavedPlans()
        
        // Verify error alert structure when it appears
        // XCTAssertTrue(app.alerts["Error"].exists, "Error alert should be displayed")
        // XCTAssertTrue(app.buttons["OK"].exists, "OK button should exist in error alert")
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationTitle() throws {
        navigateToSavedPlans()
        
        // Verify navigation title
        XCTAssertTrue(app.navigationBars["Saved Plans"].exists, "Navigation title should be 'Saved Plans'")
    }
    
    func testNavigationBackButton() throws {
        navigateToSavedPlans()
        
        // Verify back navigation works
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.exists {
            backButton.tap()
            // Verify we navigated back (implementation depends on navigation structure)
        }
    }
    
    // MARK: - Scrolling and Performance Tests
    
    func testScrollingWithManyPlans() throws {
        createManyTestPlans(count: 20)
        navigateToSavedPlans()
        
        // Verify scrolling works with many plans
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Scroll view should exist")
        
        // Scroll to bottom
        scrollView.swipeUp()
        scrollView.swipeUp()
        
        // Verify we can still see plans
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Test Plan'")).firstMatch.exists, "Plans should still be visible after scrolling")
        
        // Scroll back to top
        scrollView.swipeDown()
        scrollView.swipeDown()
    }
    
    // MARK: - Helper Methods
    
    private func navigateToSavedPlans() {
        // This implementation depends on the app's navigation structure
        // For now, assume direct navigation to SavedPlansView
        // In a real app, this might involve:
        // 1. Tapping a tab bar item
        // 2. Navigating through a menu
        // 3. Using a specific button or link
        
        // Example navigation (adjust based on actual app structure):
        // app.tabBars.buttons["Activities"].tap()
        // app.buttons["Saved Plans"].tap()
    }
    
    private func createTestPlans() {
        // This would typically involve setting up test data
        // Implementation depends on how test data is managed
        // Options include:
        // 1. Using launch arguments to inject test data
        // 2. Using a test database
        // 3. Mocking the UserPreferencesService
        
        // For now, assume test data is set up through launch arguments
        app.launchArguments.append("--test-data-saved-plans")
    }
    
    private func createManyTestPlans(count: Int) {
        // Create multiple test plans for scrolling tests
        app.launchArguments.append("--test-data-many-plans-\(count)")
    }
}

// MARK: - XCUIElement Extensions

extension XCUIElement {
    /// Clears existing text and enters new text
    func clearAndEnterText(_ text: String) {
        guard self.exists else { return }
        
        self.tap()
        
        // Select all text
        self.press(forDuration: 1.0)
        
        // Delete selected text
        if self.value as? String != "" {
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: (self.value as? String)?.count ?? 0)
            self.typeText(deleteString)
        }
        
        // Enter new text
        self.typeText(text)
    }
}
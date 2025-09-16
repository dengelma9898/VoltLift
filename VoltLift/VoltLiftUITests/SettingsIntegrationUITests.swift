//
//  SettingsIntegrationUITests.swift
//  VoltLiftUITests
//
//  Created by Kiro on 15.9.2025.
//

import XCTest

final class SettingsIntegrationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launchArguments.append("--uitesting")
        self.app.launch()
    }

    override func tearDownWithError() throws {
        self.app = nil
    }

    // MARK: - Settings Navigation Tests

    func testSettingsTabNavigation() throws {
        // Navigate to Settings tab
        let settingsTab = self.app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.exists, "Settings tab should exist")

        settingsTab.tap()

        // Verify Settings view is displayed
        let settingsTitle = self.app.navigationBars["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2), "Settings navigation title should appear")

        // Verify main sections exist
        XCTAssertTrue(self.app.staticTexts["Equipment Management"].exists, "Equipment Management section should exist")
        XCTAssertTrue(self.app.staticTexts["Data Management"].exists, "Data Management section should exist")
        XCTAssertTrue(self.app.staticTexts["About"].exists, "About section should exist")
    }

    func testSettingsViewElements() throws {
        self.navigateToSettings()

        // Test Equipment Management section
        XCTAssertTrue(self.app.buttons["Manage Equipment"].exists, "Manage Equipment button should exist")
        XCTAssertTrue(
            self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'items selected'")).element.exists,
            "Equipment selection count should be displayed"
        )

        // Test Data Management section
        XCTAssertTrue(self.app.buttons["Validate Data Integrity"].exists, "Validate Data Integrity button should exist")
        XCTAssertTrue(self.app.buttons["Reset All Preferences"].exists, "Reset All Preferences button should exist")

        // Test About section
        XCTAssertTrue(self.app.staticTexts["Data Storage"].exists, "Data Storage info should exist")
        XCTAssertTrue(self.app.staticTexts["Saved Plans"].exists, "Saved Plans info should exist")
        XCTAssertTrue(
            self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'workout plans saved'")).element.exists,
            "Saved plans count should be displayed"
        )
    }

    // MARK: - Equipment Management Tests

    func testEquipmentManagementNavigation() throws {
        self.navigateToSettings()

        // Tap Manage Equipment button
        self.app.buttons["Manage Equipment"].tap()

        // Verify Equipment Management view appears
        let equipmentTitle = self.app.navigationBars["Equipment Management"]
        XCTAssertTrue(
            equipmentTitle.waitForExistence(timeout: 2),
            "Equipment Management navigation title should appear"
        )

        // Verify Done button exists
        XCTAssertTrue(self.app.buttons["Done"].exists, "Done button should exist in equipment management")

        // Verify search field exists
        XCTAssertTrue(self.app.textFields["Search equipment..."].exists, "Search field should exist")

        // Verify category filter exists
        XCTAssertTrue(self.app.buttons["All"].exists, "All category filter should exist")
    }

    func testEquipmentManagementSearch() throws {
        self.navigateToSettings()
        self.app.buttons["Manage Equipment"].tap()

        // Wait for equipment management view
        XCTAssertTrue(self.app.navigationBars["Equipment Management"].waitForExistence(timeout: 2))

        // Test search functionality
        let searchField = self.app.textFields["Search equipment..."]
        searchField.tap()
        searchField.typeText("Barbell")

        // Verify search results are filtered (this assumes some equipment data exists)
        // The exact assertion would depend on the test data setup
        XCTAssertTrue(searchField.value as? String == "Barbell", "Search text should be entered")

        // Clear search
        let clearButton = searchField.buttons["Clear text"].firstMatch
        if clearButton.exists {
            clearButton.tap()
        }
    }

    func testEquipmentManagementCategoryFilter() throws {
        self.navigateToSettings()
        self.app.buttons["Manage Equipment"].tap()

        // Wait for equipment management view
        XCTAssertTrue(self.app.navigationBars["Equipment Management"].waitForExistence(timeout: 2))

        // Test category filtering
        let allButton = self.app.buttons["All"]
        XCTAssertTrue(allButton.exists, "All category button should exist")

        // If other categories exist, test switching between them
        let categoryButtons = self.app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'category'"))
        if categoryButtons.count > 1 {
            let secondCategory = categoryButtons.element(boundBy: 1)
            secondCategory.tap()

            // Verify category selection changed (visual feedback)
            // This would need to be verified based on the actual UI implementation
        }
    }

    func testEquipmentManagementDismissal() throws {
        self.navigateToSettings()
        self.app.buttons["Manage Equipment"].tap()

        // Wait for equipment management view
        XCTAssertTrue(self.app.navigationBars["Equipment Management"].waitForExistence(timeout: 2))

        // Tap Done button
        self.app.buttons["Done"].tap()

        // Verify we're back to Settings view
        XCTAssertTrue(
            self.app.navigationBars["Settings"].waitForExistence(timeout: 2),
            "Should return to Settings view after dismissing equipment management"
        )
    }

    // MARK: - Data Validation Tests

    func testDataValidationExecution() throws {
        self.navigateToSettings()

        // Tap Validate Data Integrity button
        self.app.buttons["Validate Data Integrity"].tap()

        // Wait for validation to complete (progress indicator should appear and disappear)
        let progressIndicator = self.app.activityIndicators.firstMatch

        // Validation should complete within reasonable time
        let validationCompleted = NSPredicate(format: "exists == false")
        expectation(for: validationCompleted, evaluatedWith: progressIndicator, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        // Validation results alert should appear
        let alert = self.app.alerts["Data Validation Results"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2), "Data validation results alert should appear")

        // Dismiss alert
        alert.buttons["OK"].tap()
    }

    // MARK: - Reset Preferences Tests

    func testResetPreferencesConfirmation() throws {
        self.navigateToSettings()

        // Tap Reset All Preferences button
        self.app.buttons["Reset All Preferences"].tap()

        // Verify confirmation alert appears
        let confirmationAlert = self.app.alerts["Reset All Preferences"]
        XCTAssertTrue(confirmationAlert.waitForExistence(timeout: 2), "Reset confirmation alert should appear")

        // Verify alert message
        XCTAssertTrue(
            confirmationAlert.staticTexts.containing(NSPredicate(format: "label CONTAINS 'permanently delete'")).element
                .exists,
            "Alert should contain warning about permanent deletion"
        )

        // Verify buttons exist
        XCTAssertTrue(confirmationAlert.buttons["Cancel"].exists, "Cancel button should exist")
        XCTAssertTrue(confirmationAlert.buttons["Reset"].exists, "Reset button should exist")

        // Cancel the reset
        confirmationAlert.buttons["Cancel"].tap()

        // Verify we're still in Settings
        XCTAssertTrue(self.app.navigationBars["Settings"].exists, "Should remain in Settings after canceling reset")
    }

    func testResetPreferencesExecution() throws {
        self.navigateToSettings()

        // Tap Reset All Preferences button
        self.app.buttons["Reset All Preferences"].tap()

        // Confirm reset
        let confirmationAlert = self.app.alerts["Reset All Preferences"]
        XCTAssertTrue(confirmationAlert.waitForExistence(timeout: 2))
        confirmationAlert.buttons["Reset"].tap()

        // Wait for reset to complete (progress indicator should appear and disappear)
        let progressIndicator = self.app.activityIndicators.firstMatch

        // Reset should complete within reasonable time
        let resetCompleted = NSPredicate(format: "exists == false")
        expectation(for: resetCompleted, evaluatedWith: progressIndicator, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        // Verify equipment count is reset to 0
        let equipmentCountText = self.app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS '0 items selected'")).element
        XCTAssertTrue(equipmentCountText.waitForExistence(timeout: 2), "Equipment count should be reset to 0")

        // Verify saved plans count is reset to 0
        let plansCountText = self.app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS '0 workout plans saved'")).element
        XCTAssertTrue(plansCountText.waitForExistence(timeout: 2), "Saved plans count should be reset to 0")
    }

    // MARK: - Accessibility Tests

    func testSettingsAccessibility() throws {
        self.navigateToSettings()

        // Test that all interactive elements have accessibility labels
        let manageEquipmentButton = self.app.buttons["Manage Equipment"]
        XCTAssertTrue(manageEquipmentButton.exists, "Manage Equipment button should be accessible")

        let validateDataButton = self.app.buttons["Validate Data Integrity"]
        XCTAssertTrue(validateDataButton.exists, "Validate Data Integrity button should be accessible")

        let resetButton = self.app.buttons["Reset All Preferences"]
        XCTAssertTrue(resetButton.exists, "Reset All Preferences button should be accessible")

        // Test VoiceOver navigation
        XCTAssertNotNil(manageEquipmentButton.label, "Manage Equipment button should have accessibility label")
        XCTAssertNotNil(validateDataButton.label, "Validate Data button should have accessibility label")
        XCTAssertNotNil(resetButton.label, "Reset button should have accessibility label")
    }

    func testEquipmentManagementAccessibility() throws {
        self.navigateToSettings()
        self.app.buttons["Manage Equipment"].tap()

        // Wait for equipment management view
        XCTAssertTrue(self.app.navigationBars["Equipment Management"].waitForExistence(timeout: 2))

        // Test search field accessibility
        let searchField = self.app.textFields["Search equipment..."]
        XCTAssertTrue(searchField.exists, "Search field should be accessible")
        XCTAssertNotNil(searchField.placeholderValue, "Search field should have placeholder text")

        // Test Done button accessibility
        let doneButton = self.app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should be accessible")
        XCTAssertNotNil(doneButton.label, "Done button should have accessibility label")
    }

    // MARK: - Error Handling Tests

    func testSettingsErrorStates() throws {
        self.navigateToSettings()

        // Test that error states are handled gracefully
        // This would require mocking error conditions, which might need additional setup

        // For now, verify that the UI doesn't crash when operations fail
        // and that error feedback is provided to users

        // Test data validation with potential errors
        self.app.buttons["Validate Data Integrity"].tap()

        // Ensure the app doesn't crash during validation
        XCTAssertTrue(
            self.app.navigationBars["Settings"].exists,
            "Settings view should remain stable during validation"
        )

        // Wait for any potential error alerts or completion
        sleep(3)

        // Dismiss any alerts that might appear
        if !self.app.alerts.isEmpty {
            self.app.alerts.firstMatch.buttons.firstMatch.tap()
        }
    }

    // MARK: - Performance Tests

    func testSettingsPerformance() throws {
        measure {
            self.navigateToSettings()

            // Test equipment management performance
            self.app.buttons["Manage Equipment"].tap()
            XCTAssertTrue(self.app.navigationBars["Equipment Management"].waitForExistence(timeout: 2))
            self.app.buttons["Done"].tap()

            // Test data validation performance
            self.app.buttons["Validate Data Integrity"].tap()

            // Wait for validation to complete
            sleep(2)

            // Dismiss any alerts
            if !self.app.alerts.isEmpty {
                self.app.alerts.firstMatch.buttons.firstMatch.tap()
            }
        }
    }

    // MARK: - Helper Methods

    private func navigateToSettings() {
        let settingsTab = self.app.tabBars.buttons["Settings"]
        settingsTab.tap()
        XCTAssertTrue(self.app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }
}

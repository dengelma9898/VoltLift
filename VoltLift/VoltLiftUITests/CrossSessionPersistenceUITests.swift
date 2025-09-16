//
//  CrossSessionPersistenceUITests.swift
//  VoltLiftUITests
//
//  Created by Kiro on 15.9.2025.
//

import XCTest

/// UI tests for cross-session persistence verification
/// Tests that user data persists correctly across app launches and terminations
final class CrossSessionPersistenceUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launchArguments.append("--uitesting")
        self.app.launchArguments.append("--reset-for-testing")
    }

    override func tearDownWithError() throws {
        self.app = nil
    }

    // MARK: - Equipment Selection Persistence Tests

    /// Tests that equipment selection persists across app restarts
    func testEquipmentSelectionPersistence() throws {
        // First app session: Select equipment
        self.app.launch()

        // Navigate to equipment selection (assuming onboarding flow)
        self.navigateToEquipmentSelection()

        // Select specific equipment items
        let dumbellsToggle = self.app.switches["Dumbbells"]
        let barbellToggle = self.app.switches["Barbell"]
        let kettlebellToggle = self.app.switches["Kettlebell"]

        XCTAssertTrue(dumbellsToggle.waitForExistence(timeout: 5), "Dumbbells toggle should exist")
        XCTAssertTrue(barbellToggle.waitForExistence(timeout: 5), "Barbell toggle should exist")
        XCTAssertTrue(kettlebellToggle.waitForExistence(timeout: 5), "Kettlebell toggle should exist")

        // Select dumbbells and barbell, leave kettlebell unselected
        if dumbellsToggle.value as? String == "0" {
            dumbellsToggle.tap()
        }
        if barbellToggle.value as? String == "0" {
            barbellToggle.tap()
        }
        if kettlebellToggle.value as? String == "1" {
            kettlebellToggle.tap()
        }

        // Verify selections
        XCTAssertEqual(dumbellsToggle.value as? String, "1", "Dumbbells should be selected")
        XCTAssertEqual(barbellToggle.value as? String, "1", "Barbell should be selected")
        XCTAssertEqual(kettlebellToggle.value as? String, "0", "Kettlebell should not be selected")

        // Complete equipment selection
        let continueButton = self.app.buttons["Continue"]
        if continueButton.exists {
            continueButton.tap()
        }

        // Terminate and relaunch app
        self.app.terminate()
        self.app.launch()

        // Navigate to equipment management to verify persistence
        self.navigateToSettings()
        self.app.buttons["Manage Equipment"].tap()

        // Wait for equipment management view
        XCTAssertTrue(self.app.navigationBars["Equipment Management"].waitForExistence(timeout: 5))

        // Verify equipment selections persisted
        let persistedDumbbells = self.app.switches["Dumbbells"]
        let persistedBarbell = self.app.switches["Barbell"]
        let persistedKettlebell = self.app.switches["Kettlebell"]

        XCTAssertTrue(persistedDumbbells.waitForExistence(timeout: 5))
        XCTAssertTrue(persistedBarbell.waitForExistence(timeout: 5))
        XCTAssertTrue(persistedKettlebell.waitForExistence(timeout: 5))

        XCTAssertEqual(persistedDumbbells.value as? String, "1", "Dumbbells selection should persist")
        XCTAssertEqual(persistedBarbell.value as? String, "1", "Barbell selection should persist")
        XCTAssertEqual(persistedKettlebell.value as? String, "0", "Kettlebell selection should persist")
    }

    /// Tests equipment selection modifications persist across sessions
    func testEquipmentModificationPersistence() throws {
        // First session: Initial equipment setup
        self.app.launch()
        self.setupInitialEquipment()

        // Navigate to equipment management
        self.navigateToSettings()
        self.app.buttons["Manage Equipment"].tap()

        // Modify equipment selection
        let resistanceBandsToggle = self.app.switches["Resistance Bands"]
        XCTAssertTrue(resistanceBandsToggle.waitForExistence(timeout: 5))

        // Toggle resistance bands
        resistanceBandsToggle.tap()
        let newValue = resistanceBandsToggle.value as? String

        // Save changes
        self.app.buttons["Done"].tap()

        // Terminate and relaunch
        self.app.terminate()
        self.app.launch()

        // Verify modification persisted
        self.navigateToSettings()
        self.app.buttons["Manage Equipment"].tap()

        let persistedResistanceBands = self.app.switches["Resistance Bands"]
        XCTAssertTrue(persistedResistanceBands.waitForExistence(timeout: 5))
        XCTAssertEqual(persistedResistanceBands.value as? String, newValue, "Equipment modification should persist")
    }

    // MARK: - Workout Plan Persistence Tests

    /// Tests that saved workout plans persist across app restarts
    func testWorkoutPlanPersistence() throws {
        // First session: Create and save workout plans
        self.app.launch()
        self.setupInitialEquipment()

        // Create first workout plan
        self.createWorkoutPlan(name: "Upper Body Workout", exercises: ["Push-ups", "Pull-ups"])

        // Create second workout plan
        self.createWorkoutPlan(name: "Lower Body Workout", exercises: ["Squats", "Lunges"])

        // Navigate to saved plans to verify they exist
        self.navigateToSavedPlans()

        XCTAssertTrue(self.app.staticTexts["Upper Body Workout"].waitForExistence(timeout: 5))
        XCTAssertTrue(self.app.staticTexts["Lower Body Workout"].waitForExistence(timeout: 5))

        // Terminate and relaunch app
        self.app.terminate()
        self.app.launch()

        // Verify plans persisted
        self.navigateToSavedPlans()

        XCTAssertTrue(
            self.app.staticTexts["Upper Body Workout"].waitForExistence(timeout: 5),
            "Upper Body Workout should persist across sessions"
        )
        XCTAssertTrue(
            self.app.staticTexts["Lower Body Workout"].waitForExistence(timeout: 5),
            "Lower Body Workout should persist across sessions"
        )

        // Verify plan details are intact
        self.app.staticTexts["Upper Body Workout"].tap()

        // Check that exercises are preserved (implementation depends on plan detail view)
        XCTAssertTrue(
            self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Push-ups'")).element.exists,
            "Exercise details should persist"
        )
    }

    /// Tests workout plan usage tracking persists across sessions
    func testWorkoutPlanUsageTrackingPersistence() throws {
        // First session: Create plan and mark as used
        self.app.launch()
        self.setupInitialEquipment()

        self.createWorkoutPlan(name: "Test Workout", exercises: ["Exercise 1"])

        // Navigate to saved plans and use the plan
        self.navigateToSavedPlans()

        let planRow = self.app.staticTexts["Test Workout"]
        XCTAssertTrue(planRow.waitForExistence(timeout: 5))

        // Use the plan (tap to select and start workout)
        planRow.tap()

        // If there's a "Start Workout" button, tap it
        let startWorkoutButton = self.app.buttons["Start Workout"]
        if startWorkoutButton.exists {
            startWorkoutButton.tap()

            // Complete or end the workout to mark as used
            let endWorkoutButton = self.app.buttons["End Workout"]
            if endWorkoutButton.waitForExistence(timeout: 5) {
                endWorkoutButton.tap()
            }
        }

        // Terminate and relaunch
        self.app.terminate()
        self.app.launch()

        // Verify usage tracking persisted
        self.navigateToSavedPlans()

        // Check for "Last used" indicator or similar UI element
        let lastUsedIndicator = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Last used'"))
            .element
        XCTAssertTrue(
            lastUsedIndicator.waitForExistence(timeout: 5),
            "Usage tracking should persist across sessions"
        )
    }

    /// Tests plan management operations persist across sessions
    func testPlanManagementPersistence() throws {
        // First session: Create and modify plans
        self.app.launch()
        self.setupInitialEquipment()

        self.createWorkoutPlan(name: "Original Plan", exercises: ["Exercise 1"])
        self.createWorkoutPlan(name: "Plan to Delete", exercises: ["Exercise 2"])

        self.navigateToSavedPlans()

        // Rename first plan
        let menuButton = self.app.buttons.matching(identifier: "ellipsis").firstMatch
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()

        self.app.buttons["Rename"].tap()

        let textField = self.app.textFields["Plan name"]
        textField.tap()
        textField.clearAndEnterText("Renamed Plan")
        self.app.buttons["Rename"].tap()

        // Delete second plan
        let secondMenuButton = self.app.buttons.matching(identifier: "ellipsis").element(boundBy: 1)
        if secondMenuButton.exists {
            secondMenuButton.tap()
            self.app.buttons["Delete"].tap()
            self.app.buttons["Delete"].tap() // Confirm deletion
        }

        // Verify changes in current session
        XCTAssertTrue(self.app.staticTexts["Renamed Plan"].waitForExistence(timeout: 5))
        XCTAssertFalse(self.app.staticTexts["Plan to Delete"].exists)

        // Terminate and relaunch
        self.app.terminate()
        self.app.launch()

        // Verify changes persisted
        self.navigateToSavedPlans()

        XCTAssertTrue(
            self.app.staticTexts["Renamed Plan"].waitForExistence(timeout: 5),
            "Plan rename should persist across sessions"
        )
        XCTAssertFalse(
            self.app.staticTexts["Plan to Delete"].exists,
            "Plan deletion should persist across sessions"
        )
        XCTAssertFalse(
            self.app.staticTexts["Original Plan"].exists,
            "Original plan name should not exist after rename"
        )
    }

    // MARK: - Settings Persistence Tests

    /// Tests that settings and preferences persist across sessions
    func testSettingsPersistence() throws {
        // First session: Modify settings
        self.app.launch()
        self.setupInitialEquipment()

        self.navigateToSettings()

        // Check initial state
        let equipmentCountBefore = self.getEquipmentCount()
        let plansCountBefore = self.getPlansCount()

        // Create some data
        self.createWorkoutPlan(name: "Settings Test Plan", exercises: ["Exercise"])

        // Modify equipment
        self.app.buttons["Manage Equipment"].tap()
        let yogaMatToggle = self.app.switches["Yoga Mat"]
        if yogaMatToggle.waitForExistence(timeout: 5) {
            yogaMatToggle.tap()
        }
        self.app.buttons["Done"].tap()

        // Check updated counts
        let equipmentCountAfter = self.getEquipmentCount()
        let plansCountAfter = self.getPlansCount()

        XCTAssertNotEqual(equipmentCountBefore, equipmentCountAfter, "Equipment count should change")
        XCTAssertNotEqual(plansCountBefore, plansCountAfter, "Plans count should change")

        // Terminate and relaunch
        self.app.terminate()
        self.app.launch()

        // Verify settings persisted
        self.navigateToSettings()

        let persistedEquipmentCount = self.getEquipmentCount()
        let persistedPlansCount = self.getPlansCount()

        XCTAssertEqual(
            equipmentCountAfter,
            persistedEquipmentCount,
            "Equipment count should persist across sessions"
        )
        XCTAssertEqual(
            plansCountAfter,
            persistedPlansCount,
            "Plans count should persist across sessions"
        )
    }

    // MARK: - Data Reset and Recovery Tests

    /// Tests data persistence after reset operations
    func testDataPersistenceAfterReset() throws {
        // First session: Create data
        self.app.launch()
        self.setupInitialEquipment()
        self.createWorkoutPlan(name: "Pre-Reset Plan", exercises: ["Exercise"])

        // Perform reset
        self.navigateToSettings()
        self.app.buttons["Reset All Preferences"].tap()

        let resetAlert = self.app.alerts["Reset All Preferences"]
        XCTAssertTrue(resetAlert.waitForExistence(timeout: 5))
        resetAlert.buttons["Reset"].tap()

        // Wait for reset to complete
        let resetCompleted = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS '0 items selected'"))
            .element
        XCTAssertTrue(resetCompleted.waitForExistence(timeout: 10))

        // Terminate and relaunch
        self.app.terminate()
        self.app.launch()

        // Verify reset persisted
        self.navigateToSettings()

        let equipmentCount = self.getEquipmentCount()
        let plansCount = self.getPlansCount()

        XCTAssertEqual(equipmentCount, 0, "Equipment should remain reset after app restart")
        XCTAssertEqual(plansCount, 0, "Plans should remain reset after app restart")

        // Verify we're back to onboarding state
        // This would depend on the app's onboarding flow implementation
    }

    // MARK: - Multiple Session Workflow Tests

    /// Tests complex workflows across multiple app sessions
    func testMultipleSessionWorkflow() throws {
        // Session 1: Initial setup
        self.app.launch()
        self.setupInitialEquipment()
        self.createWorkoutPlan(name: "Session 1 Plan", exercises: ["Exercise 1"])
        self.app.terminate()

        // Session 2: Add more data
        self.app.launch()
        self.createWorkoutPlan(name: "Session 2 Plan", exercises: ["Exercise 2"])

        // Use Session 1 plan
        self.navigateToSavedPlans()
        self.app.staticTexts["Session 1 Plan"].tap()
        // Simulate workout completion
        self.app.terminate()

        // Session 3: Modify existing data
        self.app.launch()
        self.navigateToSavedPlans()

        // Rename Session 2 plan
        let menuButton = self.app.buttons.matching(identifier: "ellipsis").element(boundBy: 1)
        if menuButton.exists {
            menuButton.tap()
            self.app.buttons["Rename"].tap()

            let textField = self.app.textFields["Plan name"]
            textField.tap()
            textField.clearAndEnterText("Modified Session 2 Plan")
            self.app.buttons["Rename"].tap()
        }

        self.app.terminate()

        // Session 4: Verify all changes
        self.app.launch()
        self.navigateToSavedPlans()

        XCTAssertTrue(
            self.app.staticTexts["Session 1 Plan"].waitForExistence(timeout: 5),
            "Session 1 plan should persist"
        )
        XCTAssertTrue(
            self.app.staticTexts["Modified Session 2 Plan"].waitForExistence(timeout: 5),
            "Modified Session 2 plan should persist"
        )
        XCTAssertFalse(
            self.app.staticTexts["Session 2 Plan"].exists,
            "Original Session 2 plan name should not exist"
        )

        // Verify usage tracking
        let lastUsedIndicator = self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Last used'"))
            .element
        XCTAssertTrue(lastUsedIndicator.exists, "Usage tracking should persist across multiple sessions")
    }

    // MARK: - Error Recovery Tests

    /// Tests data persistence after app crashes or unexpected terminations
    func testDataPersistenceAfterUnexpectedTermination() throws {
        // This test simulates unexpected app termination during data operations
        self.app.launch()
        self.setupInitialEquipment()

        // Start creating a workout plan
        self.navigateToWorkoutCreation()

        // Begin plan creation process
        self.enterWorkoutPlanName("Interrupted Plan")

        // Simulate unexpected termination during plan creation
        self.app.terminate()

        // Relaunch and verify app recovers gracefully
        self.app.launch()

        // App should not crash and should handle incomplete data gracefully
        XCTAssertTrue(self.app.exists, "App should launch successfully after unexpected termination")

        // Navigate to saved plans to check for any corrupted data
        self.navigateToSavedPlans()

        // App should handle any incomplete data without crashing
        // The incomplete plan should either be completed or cleaned up
        let incompleteplan = self.app.staticTexts["Interrupted Plan"]

        // Either the plan exists (was saved) or doesn't exist (was cleaned up)
        // Both are acceptable outcomes for graceful error recovery
        if incompleteplan.exists {
            // If it exists, it should be functional
            incompleteplan.tap()
            // Should not crash when accessing the plan
        }
    }

    // MARK: - Helper Methods

    private func navigateToEquipmentSelection() {
        // Implementation depends on app's onboarding flow
        // This might involve skipping intro screens, tapping "Get Started", etc.
        let getStartedButton = self.app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
        }

        let equipmentSelectionTitle = self.app.navigationBars["Select Equipment"]
        XCTAssertTrue(equipmentSelectionTitle.waitForExistence(timeout: 5))
    }

    private func navigateToSettings() {
        let settingsTab = self.app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()

        XCTAssertTrue(self.app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    private func navigateToSavedPlans() {
        // Implementation depends on app navigation structure
        let activitiesTab = self.app.tabBars.buttons["Activities"]
        if activitiesTab.waitForExistence(timeout: 5) {
            activitiesTab.tap()
        }

        let savedPlansButton = self.app.buttons["Saved Plans"]
        if savedPlansButton.waitForExistence(timeout: 5) {
            savedPlansButton.tap()
        }
    }

    private func navigateToWorkoutCreation() {
        let homeTab = self.app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 5) {
            homeTab.tap()
        }

        let createWorkoutButton = self.app.buttons["Create Workout"]
        if createWorkoutButton.waitForExistence(timeout: 5) {
            createWorkoutButton.tap()
        }
    }

    private func setupInitialEquipment() {
        // Quick setup of basic equipment for tests
        self.navigateToEquipmentSelection()

        // Select a few basic items
        let dumbbellsToggle = self.app.switches["Dumbbells"]
        if dumbbellsToggle.waitForExistence(timeout: 5), dumbbellsToggle.value as? String == "0" {
            dumbbellsToggle.tap()
        }

        let continueButton = self.app.buttons["Continue"]
        if continueButton.exists {
            continueButton.tap()
        }
    }

    private func createWorkoutPlan(name: String, exercises: [String]) {
        self.navigateToWorkoutCreation()

        self.enterWorkoutPlanName(name)

        // Add exercises (implementation depends on workout creation UI)
        for exercise in exercises {
            self.addExerciseToWorkoutPlan(exercise)
        }

        // Save the workout plan
        let saveButton = self.app.buttons["Save Plan"]
        if saveButton.waitForExistence(timeout: 5) {
            saveButton.tap()
        }
    }

    private func enterWorkoutPlanName(_ name: String) {
        let nameField = self.app.textFields["Workout Plan Name"]
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText(name)
        }
    }

    private func addExerciseToWorkoutPlan(_ exerciseName: String) {
        let addExerciseButton = self.app.buttons["Add Exercise"]
        if addExerciseButton.exists {
            addExerciseButton.tap()
        }

        // Select exercise from list or enter custom exercise
        let exerciseButton = self.app.buttons[exerciseName]
        if exerciseButton.waitForExistence(timeout: 5) {
            exerciseButton.tap()
        }
    }

    private func getEquipmentCount() -> Int {
        let equipmentCountText = self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'items selected'"))
            .firstMatch
        if equipmentCountText.exists {
            let text = equipmentCountText.label
            let components = text.components(separatedBy: " ")
            if let countString = components.first, let count = Int(countString) {
                return count
            }
        }
        return 0
    }

    private func getPlansCount() -> Int {
        let plansCountText = self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'workout plans saved'"))
            .firstMatch
        if plansCountText.exists {
            let text = plansCountText.label
            let components = text.components(separatedBy: " ")
            if let countString = components.first, let count = Int(countString) {
                return count
            }
        }
        return 0
    }
}

// MARK: - XCUIElement Extensions

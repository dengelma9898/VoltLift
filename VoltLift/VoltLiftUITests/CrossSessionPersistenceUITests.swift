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
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--reset-for-testing")
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Equipment Selection Persistence Tests
    
    /// Tests that equipment selection persists across app restarts
    func testEquipmentSelectionPersistence() throws {
        // First app session: Select equipment
        app.launch()
        
        // Navigate to equipment selection (assuming onboarding flow)
        navigateToEquipmentSelection()
        
        // Select specific equipment items
        let dumbellsToggle = app.switches["Dumbbells"]
        let barbellToggle = app.switches["Barbell"]
        let kettlebellToggle = app.switches["Kettlebell"]
        
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
        let continueButton = app.buttons["Continue"]
        if continueButton.exists {
            continueButton.tap()
        }
        
        // Terminate and relaunch app
        app.terminate()
        app.launch()
        
        // Navigate to equipment management to verify persistence
        navigateToSettings()
        app.buttons["Manage Equipment"].tap()
        
        // Wait for equipment management view
        XCTAssertTrue(app.navigationBars["Equipment Management"].waitForExistence(timeout: 5))
        
        // Verify equipment selections persisted
        let persistedDumbbells = app.switches["Dumbbells"]
        let persistedBarbell = app.switches["Barbell"]
        let persistedKettlebell = app.switches["Kettlebell"]
        
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
        app.launch()
        setupInitialEquipment()
        
        // Navigate to equipment management
        navigateToSettings()
        app.buttons["Manage Equipment"].tap()
        
        // Modify equipment selection
        let resistanceBandsToggle = app.switches["Resistance Bands"]
        XCTAssertTrue(resistanceBandsToggle.waitForExistence(timeout: 5))
        
        // Toggle resistance bands
        resistanceBandsToggle.tap()
        let newValue = resistanceBandsToggle.value as? String
        
        // Save changes
        app.buttons["Done"].tap()
        
        // Terminate and relaunch
        app.terminate()
        app.launch()
        
        // Verify modification persisted
        navigateToSettings()
        app.buttons["Manage Equipment"].tap()
        
        let persistedResistanceBands = app.switches["Resistance Bands"]
        XCTAssertTrue(persistedResistanceBands.waitForExistence(timeout: 5))
        XCTAssertEqual(persistedResistanceBands.value as? String, newValue, "Equipment modification should persist")
    }
    
    // MARK: - Workout Plan Persistence Tests
    
    /// Tests that saved workout plans persist across app restarts
    func testWorkoutPlanPersistence() throws {
        // First session: Create and save workout plans
        app.launch()
        setupInitialEquipment()
        
        // Create first workout plan
        createWorkoutPlan(name: "Upper Body Workout", exercises: ["Push-ups", "Pull-ups"])
        
        // Create second workout plan
        createWorkoutPlan(name: "Lower Body Workout", exercises: ["Squats", "Lunges"])
        
        // Navigate to saved plans to verify they exist
        navigateToSavedPlans()
        
        XCTAssertTrue(app.staticTexts["Upper Body Workout"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Lower Body Workout"].waitForExistence(timeout: 5))
        
        // Terminate and relaunch app
        app.terminate()
        app.launch()
        
        // Verify plans persisted
        navigateToSavedPlans()
        
        XCTAssertTrue(app.staticTexts["Upper Body Workout"].waitForExistence(timeout: 5), 
                     "Upper Body Workout should persist across sessions")
        XCTAssertTrue(app.staticTexts["Lower Body Workout"].waitForExistence(timeout: 5), 
                     "Lower Body Workout should persist across sessions")
        
        // Verify plan details are intact
        app.staticTexts["Upper Body Workout"].tap()
        
        // Check that exercises are preserved (implementation depends on plan detail view)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Push-ups'")).element.exists,
                     "Exercise details should persist")
    }
    
    /// Tests workout plan usage tracking persists across sessions
    func testWorkoutPlanUsageTrackingPersistence() throws {
        // First session: Create plan and mark as used
        app.launch()
        setupInitialEquipment()
        
        createWorkoutPlan(name: "Test Workout", exercises: ["Exercise 1"])
        
        // Navigate to saved plans and use the plan
        navigateToSavedPlans()
        
        let planRow = app.staticTexts["Test Workout"]
        XCTAssertTrue(planRow.waitForExistence(timeout: 5))
        
        // Use the plan (tap to select and start workout)
        planRow.tap()
        
        // If there's a "Start Workout" button, tap it
        let startWorkoutButton = app.buttons["Start Workout"]
        if startWorkoutButton.exists {
            startWorkoutButton.tap()
            
            // Complete or end the workout to mark as used
            let endWorkoutButton = app.buttons["End Workout"]
            if endWorkoutButton.waitForExistence(timeout: 5) {
                endWorkoutButton.tap()
            }
        }
        
        // Terminate and relaunch
        app.terminate()
        app.launch()
        
        // Verify usage tracking persisted
        navigateToSavedPlans()
        
        // Check for "Last used" indicator or similar UI element
        let lastUsedIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Last used'")).element
        XCTAssertTrue(lastUsedIndicator.waitForExistence(timeout: 5), 
                     "Usage tracking should persist across sessions")
    }
    
    /// Tests plan management operations persist across sessions
    func testPlanManagementPersistence() throws {
        // First session: Create and modify plans
        app.launch()
        setupInitialEquipment()
        
        createWorkoutPlan(name: "Original Plan", exercises: ["Exercise 1"])
        createWorkoutPlan(name: "Plan to Delete", exercises: ["Exercise 2"])
        
        navigateToSavedPlans()
        
        // Rename first plan
        let menuButton = app.buttons.matching(identifier: "ellipsis").firstMatch
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.tap()
        
        app.buttons["Rename"].tap()
        
        let textField = app.textFields["Plan name"]
        textField.tap()
        textField.clearAndEnterText("Renamed Plan")
        app.buttons["Rename"].tap()
        
        // Delete second plan
        let secondMenuButton = app.buttons.matching(identifier: "ellipsis").element(boundBy: 1)
        if secondMenuButton.exists {
            secondMenuButton.tap()
            app.buttons["Delete"].tap()
            app.buttons["Delete"].tap() // Confirm deletion
        }
        
        // Verify changes in current session
        XCTAssertTrue(app.staticTexts["Renamed Plan"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Plan to Delete"].exists)
        
        // Terminate and relaunch
        app.terminate()
        app.launch()
        
        // Verify changes persisted
        navigateToSavedPlans()
        
        XCTAssertTrue(app.staticTexts["Renamed Plan"].waitForExistence(timeout: 5), 
                     "Plan rename should persist across sessions")
        XCTAssertFalse(app.staticTexts["Plan to Delete"].exists, 
                      "Plan deletion should persist across sessions")
        XCTAssertFalse(app.staticTexts["Original Plan"].exists, 
                      "Original plan name should not exist after rename")
    }
    
    // MARK: - Settings Persistence Tests
    
    /// Tests that settings and preferences persist across sessions
    func testSettingsPersistence() throws {
        // First session: Modify settings
        app.launch()
        setupInitialEquipment()
        
        navigateToSettings()
        
        // Check initial state
        let equipmentCountBefore = getEquipmentCount()
        let plansCountBefore = getPlansCount()
        
        // Create some data
        createWorkoutPlan(name: "Settings Test Plan", exercises: ["Exercise"])
        
        // Modify equipment
        app.buttons["Manage Equipment"].tap()
        let yogaMatToggle = app.switches["Yoga Mat"]
        if yogaMatToggle.waitForExistence(timeout: 5) {
            yogaMatToggle.tap()
        }
        app.buttons["Done"].tap()
        
        // Check updated counts
        let equipmentCountAfter = getEquipmentCount()
        let plansCountAfter = getPlansCount()
        
        XCTAssertNotEqual(equipmentCountBefore, equipmentCountAfter, "Equipment count should change")
        XCTAssertNotEqual(plansCountBefore, plansCountAfter, "Plans count should change")
        
        // Terminate and relaunch
        app.terminate()
        app.launch()
        
        // Verify settings persisted
        navigateToSettings()
        
        let persistedEquipmentCount = getEquipmentCount()
        let persistedPlansCount = getPlansCount()
        
        XCTAssertEqual(equipmentCountAfter, persistedEquipmentCount, 
                      "Equipment count should persist across sessions")
        XCTAssertEqual(plansCountAfter, persistedPlansCount, 
                      "Plans count should persist across sessions")
    }
    
    // MARK: - Data Reset and Recovery Tests
    
    /// Tests data persistence after reset operations
    func testDataPersistenceAfterReset() throws {
        // First session: Create data
        app.launch()
        setupInitialEquipment()
        createWorkoutPlan(name: "Pre-Reset Plan", exercises: ["Exercise"])
        
        // Perform reset
        navigateToSettings()
        app.buttons["Reset All Preferences"].tap()
        
        let resetAlert = app.alerts["Reset All Preferences"]
        XCTAssertTrue(resetAlert.waitForExistence(timeout: 5))
        resetAlert.buttons["Reset"].tap()
        
        // Wait for reset to complete
        let resetCompleted = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '0 items selected'")).element
        XCTAssertTrue(resetCompleted.waitForExistence(timeout: 10))
        
        // Terminate and relaunch
        app.terminate()
        app.launch()
        
        // Verify reset persisted
        navigateToSettings()
        
        let equipmentCount = getEquipmentCount()
        let plansCount = getPlansCount()
        
        XCTAssertEqual(equipmentCount, 0, "Equipment should remain reset after app restart")
        XCTAssertEqual(plansCount, 0, "Plans should remain reset after app restart")
        
        // Verify we're back to onboarding state
        // This would depend on the app's onboarding flow implementation
    }
    
    // MARK: - Multiple Session Workflow Tests
    
    /// Tests complex workflows across multiple app sessions
    func testMultipleSessionWorkflow() throws {
        // Session 1: Initial setup
        app.launch()
        setupInitialEquipment()
        createWorkoutPlan(name: "Session 1 Plan", exercises: ["Exercise 1"])
        app.terminate()
        
        // Session 2: Add more data
        app.launch()
        createWorkoutPlan(name: "Session 2 Plan", exercises: ["Exercise 2"])
        
        // Use Session 1 plan
        navigateToSavedPlans()
        app.staticTexts["Session 1 Plan"].tap()
        // Simulate workout completion
        app.terminate()
        
        // Session 3: Modify existing data
        app.launch()
        navigateToSavedPlans()
        
        // Rename Session 2 plan
        let menuButton = app.buttons.matching(identifier: "ellipsis").element(boundBy: 1)
        if menuButton.exists {
            menuButton.tap()
            app.buttons["Rename"].tap()
            
            let textField = app.textFields["Plan name"]
            textField.tap()
            textField.clearAndEnterText("Modified Session 2 Plan")
            app.buttons["Rename"].tap()
        }
        
        app.terminate()
        
        // Session 4: Verify all changes
        app.launch()
        navigateToSavedPlans()
        
        XCTAssertTrue(app.staticTexts["Session 1 Plan"].waitForExistence(timeout: 5), 
                     "Session 1 plan should persist")
        XCTAssertTrue(app.staticTexts["Modified Session 2 Plan"].waitForExistence(timeout: 5), 
                     "Modified Session 2 plan should persist")
        XCTAssertFalse(app.staticTexts["Session 2 Plan"].exists, 
                      "Original Session 2 plan name should not exist")
        
        // Verify usage tracking
        let lastUsedIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Last used'")).element
        XCTAssertTrue(lastUsedIndicator.exists, "Usage tracking should persist across multiple sessions")
    }
    
    // MARK: - Error Recovery Tests
    
    /// Tests data persistence after app crashes or unexpected terminations
    func testDataPersistenceAfterUnexpectedTermination() throws {
        // This test simulates unexpected app termination during data operations
        app.launch()
        setupInitialEquipment()
        
        // Start creating a workout plan
        navigateToWorkoutCreation()
        
        // Begin plan creation process
        enterWorkoutPlanName("Interrupted Plan")
        
        // Simulate unexpected termination during plan creation
        app.terminate()
        
        // Relaunch and verify app recovers gracefully
        app.launch()
        
        // App should not crash and should handle incomplete data gracefully
        XCTAssertTrue(app.exists, "App should launch successfully after unexpected termination")
        
        // Navigate to saved plans to check for any corrupted data
        navigateToSavedPlans()
        
        // App should handle any incomplete data without crashing
        // The incomplete plan should either be completed or cleaned up
        let incompleteplan = app.staticTexts["Interrupted Plan"]
        
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
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
        }
        
        let equipmentSelectionTitle = app.navigationBars["Select Equipment"]
        XCTAssertTrue(equipmentSelectionTitle.waitForExistence(timeout: 5))
    }
    
    private func navigateToSettings() {
        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5))
        settingsTab.tap()
        
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
    }
    
    private func navigateToSavedPlans() {
        // Implementation depends on app navigation structure
        let activitiesTab = app.tabBars.buttons["Activities"]
        if activitiesTab.waitForExistence(timeout: 5) {
            activitiesTab.tap()
        }
        
        let savedPlansButton = app.buttons["Saved Plans"]
        if savedPlansButton.waitForExistence(timeout: 5) {
            savedPlansButton.tap()
        }
    }
    
    private func navigateToWorkoutCreation() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.waitForExistence(timeout: 5) {
            homeTab.tap()
        }
        
        let createWorkoutButton = app.buttons["Create Workout"]
        if createWorkoutButton.waitForExistence(timeout: 5) {
            createWorkoutButton.tap()
        }
    }
    
    private func setupInitialEquipment() {
        // Quick setup of basic equipment for tests
        navigateToEquipmentSelection()
        
        // Select a few basic items
        let dumbbellsToggle = app.switches["Dumbbells"]
        if dumbbellsToggle.waitForExistence(timeout: 5) && dumbbellsToggle.value as? String == "0" {
            dumbbellsToggle.tap()
        }
        
        let continueButton = app.buttons["Continue"]
        if continueButton.exists {
            continueButton.tap()
        }
    }
    
    private func createWorkoutPlan(name: String, exercises: [String]) {
        navigateToWorkoutCreation()
        
        enterWorkoutPlanName(name)
        
        // Add exercises (implementation depends on workout creation UI)
        for exercise in exercises {
            addExerciseToWorkoutPlan(exercise)
        }
        
        // Save the workout plan
        let saveButton = app.buttons["Save Plan"]
        if saveButton.waitForExistence(timeout: 5) {
            saveButton.tap()
        }
    }
    
    private func enterWorkoutPlanName(_ name: String) {
        let nameField = app.textFields["Workout Plan Name"]
        if nameField.waitForExistence(timeout: 5) {
            nameField.tap()
            nameField.typeText(name)
        }
    }
    
    private func addExerciseToWorkoutPlan(_ exerciseName: String) {
        let addExerciseButton = app.buttons["Add Exercise"]
        if addExerciseButton.exists {
            addExerciseButton.tap()
        }
        
        // Select exercise from list or enter custom exercise
        let exerciseButton = app.buttons[exerciseName]
        if exerciseButton.waitForExistence(timeout: 5) {
            exerciseButton.tap()
        }
    }
    
    private func getEquipmentCount() -> Int {
        let equipmentCountText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'items selected'")).firstMatch
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
        let plansCountText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'workout plans saved'")).firstMatch
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


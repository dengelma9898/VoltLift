import XCTest

final class ExerciseWorkflowIntegrationUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Complete Workflow Integration Tests
    
    func testCompleteExerciseWorkflowWithEquipment() throws {
        // Step 1: Navigate to workout setup
        let workoutButton = app.buttons["Krafttraining"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 5))
        workoutButton.tap()
        
        // Step 2: Set up equipment
        let addEquipmentButton = app.buttons["Add Equipment"]
        XCTAssertTrue(addEquipmentButton.waitForExistence(timeout: 3))
        addEquipmentButton.tap()
        
        // Select multiple equipment types
        let equipmentToSelect = ["Dumbbells", "Resistance Bands", "Yoga Mat"]
        for equipment in equipmentToSelect {
            let equipmentRow = app.staticTexts[equipment]
            XCTAssertTrue(equipmentRow.exists, "\(equipment) should be available")
            equipmentRow.tap()
            
            // Verify selection indicator appears
            let checkmark = app.images["checkmark"]
            XCTAssertTrue(checkmark.exists, "Checkmark should appear for selected equipment")
        }
        
        // Confirm equipment selection
        let equipmentDoneButton = app.navigationBars.buttons["Done"]
        equipmentDoneButton.tap()
        
        // Step 3: Create workout plan
        let addPlanButton = app.buttons["Add Plan"]
        XCTAssertTrue(addPlanButton.waitForExistence(timeout: 3))
        addPlanButton.tap()
        
        // Enter plan details
        let planNameField = app.textFields["Name"]
        XCTAssertTrue(planNameField.waitForExistence(timeout: 3))
        planNameField.tap()
        planNameField.typeText("Full Body Workout")
        
        // Step 4: Add exercises from multiple muscle groups
        let muscleGroups = ["Chest", "Back", "Legs"]
        var totalExercisesAdded = 0
        
        for muscleGroup in muscleGroups {
            // Navigate to exercise selection
            let addExerciseButton = app.buttons["Add Exercise"]
            XCTAssertTrue(addExerciseButton.exists)
            addExerciseButton.tap()
            
            // Select muscle group
            let muscleGroupPicker = app.pickers["Muscle Group"]
            XCTAssertTrue(muscleGroupPicker.exists)
            muscleGroupPicker.tap()
            app.pickerWheels.element.adjust(toPickerWheelValue: muscleGroup)
            
            // Wait for exercises to load
            let exercisesList = app.tables.firstMatch
            XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))
            
            // Select exercises (mix of available and equipment-requiring)
            let exerciseCells = exercisesList.cells
            let exercisesToSelect = min(2, exerciseCells.count)
            
            for i in 0..<exercisesToSelect {
                let cell = exerciseCells.element(boundBy: i)
                if cell.exists {
                    // Test exercise detail view for first exercise
                    if i == 0 {
                        let infoButton = cell.buttons["info.circle"]
                        XCTAssertTrue(infoButton.exists, "Info button should be present")
                        infoButton.tap()
                        
                        // Verify exercise detail view
                        let exerciseDetailView = app.scrollViews.firstMatch
                        XCTAssertTrue(exerciseDetailView.waitForExistence(timeout: 3))
                        
                        // Test adding from detail view
                        exerciseDetailView.swipeUp()
                        exerciseDetailView.swipeUp()
                        
                        let addToWorkoutButton = app.buttons["Add to Workout"]
                        if addToWorkoutButton.waitForExistence(timeout: 3) {
                            addToWorkoutButton.tap()
                            totalExercisesAdded += 1
                        } else {
                            // Fallback: close detail view and select normally
                            let doneButton = app.buttons["Done"]
                            doneButton.tap()
                            cell.tap()
                            totalExercisesAdded += 1
                        }
                    } else {
                        // Select exercise normally
                        cell.tap()
                        totalExercisesAdded += 1
                    }
                    
                    // Verify selection indicator
                    let selectedIcon = cell.images["checkmark.circle.fill"]
                    XCTAssertTrue(selectedIcon.exists, "Exercise should show as selected")
                }
            }
            
            // Add selected exercises to plan
            let addButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
            XCTAssertTrue(addButton.exists)
            
            // Verify button shows correct count
            let buttonLabel = addButton.label
            XCTAssertTrue(buttonLabel.contains("\(exercisesToSelect)"), "Button should show correct exercise count")
            
            addButton.tap()
            
            // Verify we're back to plan creation
            let planCreationTitle = app.navigationBars["New Plan"]
            XCTAssertTrue(planCreationTitle.waitForExistence(timeout: 3))
        }
        
        // Step 5: Verify exercises were added to plan
        let exercisesSection = app.tables.firstMatch
        XCTAssertTrue(exercisesSection.exists)
        
        let exerciseCells = exercisesSection.cells
        XCTAssertGreaterThanOrEqual(exerciseCells.count, totalExercisesAdded, "All exercises should be added to plan")
        
        // Step 6: Save the plan
        let savePlanButton = app.buttons["Save"]
        XCTAssertTrue(savePlanButton.exists)
        savePlanButton.tap()
        
        // Verify we're back to workout setup with plan created
        let workoutSetupTitle = app.navigationBars["Workout"]
        XCTAssertTrue(workoutSetupTitle.waitForExistence(timeout: 3))
        
        // Verify plan appears in plans section
        let plansSection = app.staticTexts["Plans"]
        XCTAssertTrue(plansSection.exists, "Plans section should be visible")
        
        let planRow = app.staticTexts["Full Body Workout"]
        XCTAssertTrue(planRow.exists, "Created plan should be visible")
    }
    
    func testExerciseWorkflowWithoutEquipment() throws {
        // Test the workflow when no equipment is selected
        let workoutButton = app.buttons["Krafttraining"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 5))
        workoutButton.tap()
        
        // Skip equipment setup
        let addPlanButton = app.buttons["Add Plan"]
        XCTAssertTrue(addPlanButton.waitForExistence(timeout: 3))
        addPlanButton.tap()
        
        // Create plan
        let planNameField = app.textFields["Name"]
        XCTAssertTrue(planNameField.waitForExistence(timeout: 3))
        planNameField.tap()
        planNameField.typeText("Bodyweight Workout")
        
        // Add exercises
        let addExerciseButton = app.buttons["Add Exercise"]
        addExerciseButton.tap()
        
        // Verify bodyweight exercises are available
        let exercisesList = app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))
        
        let bodyweightIndicators = app.staticTexts["Bodyweight"]
        XCTAssertTrue(bodyweightIndicators.firstMatch.exists, "Should show bodyweight exercises")
        
        // Verify equipment-requiring exercises show proper indicators
        let needsEquipmentIndicators = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Needs:'"))
        if needsEquipmentIndicators.count > 0 {
            // Test that equipment requirements are clearly shown
            let firstNeedsIndicator = needsEquipmentIndicators.firstMatch
            XCTAssertTrue(firstNeedsIndicator.exists)
            XCTAssertTrue(firstNeedsIndicator.label.contains("Needs:"), "Should clearly indicate equipment needs")
        }
        
        // Select a bodyweight exercise
        let exerciseCells = exercisesList.cells
        var selectedBodyweightExercise = false
        
        for i in 0..<min(5, exerciseCells.count) {
            let cell = exerciseCells.element(boundBy: i)
            let bodyweightText = cell.staticTexts["Bodyweight"]
            
            if bodyweightText.exists {
                cell.tap()
                selectedBodyweightExercise = true
                
                // Verify selection
                let selectedIcon = cell.images["checkmark.circle.fill"]
                XCTAssertTrue(selectedIcon.exists, "Bodyweight exercise should be selectable")
                break
            }
        }
        
        XCTAssertTrue(selectedBodyweightExercise, "Should be able to select bodyweight exercises")
        
        // Add to plan
        let addButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
        addButton.tap()
        
        // Save plan
        let savePlanButton = app.buttons["Save"]
        savePlanButton.tap()
        
        // Verify plan was created
        let planRow = app.staticTexts["Bodyweight Workout"]
        XCTAssertTrue(planRow.waitForExistence(timeout: 3), "Bodyweight plan should be created")
    }
    
    func testExerciseDetailViewIntegrationWithWorkflow() throws {
        // Test that exercise detail view integrates properly with the overall workflow
        navigateToExerciseSelection()
        
        // Open exercise detail view
        let exercisesList = app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))
        
        let firstCell = exercisesList.cells.firstMatch
        let infoButton = firstCell.buttons["info.circle"]
        infoButton.tap()
        
        // Test all sections of detail view
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
        
        // Verify header information
        let difficultyBadges = app.staticTexts.matching(NSPredicate(format: "label IN {'Beginner', 'Intermediate', 'Advanced'}"))
        XCTAssertGreaterThan(difficultyBadges.count, 0, "Difficulty should be displayed")
        
        // Test scrolling through all sections
        let sectionsToTest = ["Description", "Instructions", "Safety Tips", "Target Muscles"]
        for section in sectionsToTest {
            let sectionHeader = app.staticTexts[section]
            if !sectionHeader.isHittable {
                scrollView.swipeUp()
            }
            XCTAssertTrue(sectionHeader.waitForExistence(timeout: 2), "\(section) section should be present")
        }
        
        // Test variations section if present
        let variationsHeader = app.staticTexts["Variations"]
        if variationsHeader.exists {
            if !variationsHeader.isHittable {
                scrollView.swipeUp()
            }
            XCTAssertTrue(variationsHeader.isHittable, "Variations section should be accessible")
        }
        
        // Test add to workout from detail view
        scrollView.swipeUp()
        let addToWorkoutButton = app.buttons["Add to Workout"]
        if addToWorkoutButton.waitForExistence(timeout: 3) {
            addToWorkoutButton.tap()
            
            // Verify we're back to exercise selection with exercise selected
            let exerciseSelectionTitle = app.navigationBars["Add Exercise"]
            XCTAssertTrue(exerciseSelectionTitle.waitForExistence(timeout: 3))
            
            // Verify exercise is selected
            let selectedIcon = app.images["checkmark.circle.fill"]
            XCTAssertTrue(selectedIcon.exists, "Exercise should be selected after adding from detail view")
            
            // Complete the workflow
            let addButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
            addButton.tap()
            
            // Verify we're back to plan creation
            let planCreationTitle = app.navigationBars["New Plan"]
            XCTAssertTrue(planCreationTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testErrorHandlingAndEdgeCases() throws {
        navigateToExerciseSelection()
        
        // Test empty selection
        let addButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
        XCTAssertTrue(addButton.exists)
        
        // Button should be disabled when no exercises selected
        let isEnabled = addButton.isEnabled
        XCTAssertFalse(isEnabled, "Add button should be disabled when no exercises selected")
        
        // Test muscle group with no exercises (if any)
        let muscleGroupPicker = app.pickers["Muscle Group"]
        let muscleGroups = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Full Body"]
        
        for muscleGroup in muscleGroups {
            muscleGroupPicker.tap()
            app.pickerWheels.element.adjust(toPickerWheelValue: muscleGroup)
            
            let exercisesList = app.tables.firstMatch
            XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))
            
            let noExercisesMessage = app.staticTexts["No exercises available for this muscle group"]
            let hasCells = exercisesList.cells.count > 0
            
            // Either should have exercises or show appropriate message
            XCTAssertTrue(hasCells || noExercisesMessage.exists, 
                         "Should show exercises or no exercises message for \(muscleGroup)")
        }
        
        // Test navigation cancellation
        let exercisesList = app.tables.firstMatch
        if exercisesList.cells.count > 0 {
            let firstCell = exercisesList.cells.firstMatch
            let infoButton = firstCell.buttons["info.circle"]
            infoButton.tap()
            
            // Cancel from detail view
            let doneButton = app.buttons["Done"]
            doneButton.tap()
            
            // Should be back to exercise selection
            let exerciseSelectionTitle = app.navigationBars["Add Exercise"]
            XCTAssertTrue(exerciseSelectionTitle.waitForExistence(timeout: 3))
        }
    }
    
    func testPerformanceWithLargeExerciseList() throws {
        // Test that the UI remains responsive with a large number of exercises
        navigateToExerciseSelection()
        
        let startTime = Date()
        
        // Test muscle group switching performance
        let muscleGroupPicker = app.pickers["Muscle Group"]
        let muscleGroups = ["Chest", "Back", "Shoulders", "Arms", "Legs"]
        
        for muscleGroup in muscleGroups {
            muscleGroupPicker.tap()
            app.pickerWheels.element.adjust(toPickerWheelValue: muscleGroup)
            
            let exercisesList = app.tables.firstMatch
            XCTAssertTrue(exercisesList.waitForExistence(timeout: 2), "Exercise list should load quickly for \(muscleGroup)")
        }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsedTime, 10.0, "Muscle group switching should be performant")
        
        // Test scrolling performance
        let exercisesList = app.tables.firstMatch
        if exercisesList.cells.count > 5 {
            let scrollStartTime = Date()
            
            // Scroll through the list
            for _ in 0..<3 {
                exercisesList.swipeUp()
            }
            
            let scrollElapsedTime = Date().timeIntervalSince(scrollStartTime)
            XCTAssertLessThan(scrollElapsedTime, 3.0, "Scrolling should be smooth and responsive")
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToExerciseSelection() {
        let workoutButton = app.buttons["Krafttraining"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 5))
        workoutButton.tap()
        
        let addPlanButton = app.buttons["Add Plan"]
        if !addPlanButton.exists {
            let addEquipmentButton = app.buttons["Add Equipment"]
            if addEquipmentButton.exists {
                addEquipmentButton.tap()
                let doneButton = app.navigationBars.buttons["Done"]
                doneButton.tap()
            }
        }
        
        XCTAssertTrue(addPlanButton.waitForExistence(timeout: 3))
        addPlanButton.tap()
        
        let planNameField = app.textFields["Name"]
        XCTAssertTrue(planNameField.waitForExistence(timeout: 3))
        planNameField.tap()
        planNameField.typeText("Test Plan")
        
        let addExerciseButton = app.buttons["Add Exercise"]
        XCTAssertTrue(addExerciseButton.exists)
        addExerciseButton.tap()
    }
}
import XCTest

final class ExerciseSelectionUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launch()
    }

    override func tearDownWithError() throws {
        self.app = nil
    }

    // MARK: - Exercise Selection Flow Tests

    func testCompleteExerciseSelectionFlow() throws {
        // Navigate to workout setup
        let workoutButton = self.app.buttons["Krafttraining"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 5))
        workoutButton.tap()

        // Add equipment first
        let addEquipmentButton = self.app.buttons["Add Equipment"]
        if addEquipmentButton.exists {
            addEquipmentButton.tap()

            // Select some equipment
            let dumbbellsRow = self.app.staticTexts["Dumbbells"]
            XCTAssertTrue(dumbbellsRow.waitForExistence(timeout: 3))
            dumbbellsRow.tap()

            let resistanceBandsRow = self.app.staticTexts["Resistance Bands"]
            resistanceBandsRow.tap()

            // Confirm equipment selection
            let doneButton = self.app.navigationBars.buttons["Done"]
            doneButton.tap()
        }

        // Create a plan
        let addPlanButton = self.app.buttons["Add Plan"]
        XCTAssertTrue(addPlanButton.waitForExistence(timeout: 3))
        addPlanButton.tap()

        // Enter plan name
        let planNameField = self.app.textFields["Name"]
        XCTAssertTrue(planNameField.waitForExistence(timeout: 3))
        planNameField.tap()
        planNameField.typeText("Test Workout Plan")

        // Add exercises
        let addExerciseButton = self.app.buttons["Add Exercise"]
        XCTAssertTrue(addExerciseButton.exists)
        addExerciseButton.tap()

        // Verify exercise selection view appears
        let addExerciseTitle = self.app.navigationBars["Add Exercise"]
        XCTAssertTrue(addExerciseTitle.waitForExistence(timeout: 3))

        // Test muscle group selection
        let muscleGroupPicker = self.app.pickers["Muscle Group"]
        XCTAssertTrue(muscleGroupPicker.exists)

        // Select chest muscle group
        muscleGroupPicker.tap()
        let chestOption = self.app.pickerWheels.element.adjust(toPickerWheelValue: "Chest")

        // Verify exercises are displayed
        let exercisesList = self.app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

        // Verify at least one exercise is shown
        let firstExerciseCell = exercisesList.cells.firstMatch
        XCTAssertTrue(firstExerciseCell.exists)
    }

    func testEquipmentIndicatorsDisplay() throws {
        // Navigate to exercise selection
        self.navigateToExerciseSelection()

        // Look for equipment indicators
        let availableIndicator = self.app.staticTexts["Available"]
        let bodyweightIndicator = self.app.staticTexts["Bodyweight"]
        let needsEquipmentIndicator = self.app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Needs:'"))
            .firstMatch

        // At least one type of indicator should be present
        let hasIndicators = availableIndicator.exists || bodyweightIndicator.exists || needsEquipmentIndicator.exists
        XCTAssertTrue(hasIndicators, "Equipment indicators should be displayed")

        // Verify success/warning icons are present
        let successIcon = self.app.images["checkmark.circle.fill"]
        let warningIcon = self.app.images["exclamationmark.triangle.fill"]
        let bodyweightIcon = self.app.images["figure.strengthtraining.traditional"]

        let hasStatusIcons = successIcon.exists || warningIcon.exists || bodyweightIcon.exists
        XCTAssertTrue(hasStatusIcons, "Status icons should be displayed")
    }

    func testExerciseSelectionWithMultipleEquipment() throws {
        // Set up equipment first
        self.setupEquipment(["Dumbbells", "Resistance Bands", "Yoga Mat"])

        // Navigate to exercise selection
        self.navigateToExerciseSelection()

        // Select multiple exercises
        let exercisesList = self.app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

        let exerciseCells = exercisesList.cells
        let cellCount = min(3, exerciseCells.count) // Select up to 3 exercises

        for i in 0 ..< cellCount {
            let cell = exerciseCells.element(boundBy: i)
            if cell.exists {
                cell.tap()

                // Verify selection indicator changes
                let selectedIcon = cell.images["checkmark.circle.fill"]
                XCTAssertTrue(selectedIcon.exists, "Exercise should show as selected")
            }
        }

        // Verify add button updates count
        let addButton = self.app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
        XCTAssertTrue(addButton.exists)

        // The button should show the count of selected exercises
        let buttonLabel = addButton.label
        XCTAssertTrue(buttonLabel.contains("\(cellCount)"), "Add button should show selected count")
    }

    func testMuscleGroupFiltering() throws {
        self.navigateToExerciseSelection()

        let muscleGroupPicker = self.app.pickers["Muscle Group"]
        XCTAssertTrue(muscleGroupPicker.exists)

        let muscleGroups = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"]

        for muscleGroup in muscleGroups {
            // Select muscle group
            muscleGroupPicker.tap()
            self.app.pickerWheels.element.adjust(toPickerWheelValue: muscleGroup)

            // Wait for exercises to load
            let exercisesList = self.app.tables.firstMatch
            XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

            // Verify exercises are shown (or appropriate message if none)
            let hasExercises = !exercisesList.cells.isEmpty
            let noExercisesMessage = self.app.staticTexts["No exercises available for this muscle group"]

            XCTAssertTrue(
                hasExercises || noExercisesMessage.exists,
                "Should show exercises or no exercises message for \(muscleGroup)"
            )
        }
    }

    func testExerciseAdditionToWorkoutPlan() throws {
        self.navigateToExerciseSelection()

        // Select an exercise
        let exercisesList = self.app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

        let firstExercise = exercisesList.cells.firstMatch
        XCTAssertTrue(firstExercise.exists)
        firstExercise.tap()

        // Add selected exercises
        let addButton = self.app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
        XCTAssertTrue(addButton.exists)
        addButton.tap()

        // Verify we're back to plan creation
        let planCreationTitle = self.app.navigationBars["New Plan"]
        XCTAssertTrue(planCreationTitle.waitForExistence(timeout: 3))

        // Verify exercise was added to the plan
        let exercisesSection = self.app.tables.firstMatch
        XCTAssertTrue(exercisesSection.exists)

        // Should have at least one exercise now
        let exerciseCells = exercisesSection.cells
        XCTAssertGreaterThan(exerciseCells.count, 0, "Exercise should be added to plan")
    }

    // MARK: - Helper Methods

    private func navigateToExerciseSelection() {
        // Navigate to workout setup
        let workoutButton = self.app.buttons["Krafttraining"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 5))
        workoutButton.tap()

        // Skip equipment setup if needed
        let addPlanButton = self.app.buttons["Add Plan"]
        if !addPlanButton.exists {
            let addEquipmentButton = self.app.buttons["Add Equipment"]
            if addEquipmentButton.exists {
                addEquipmentButton.tap()
                let doneButton = self.app.navigationBars.buttons["Done"]
                doneButton.tap()
            }
        }

        // Create a plan
        XCTAssertTrue(addPlanButton.waitForExistence(timeout: 3))
        addPlanButton.tap()

        // Enter plan name
        let planNameField = self.app.textFields["Name"]
        XCTAssertTrue(planNameField.waitForExistence(timeout: 3))
        planNameField.tap()
        planNameField.typeText("Test Plan")

        // Navigate to exercise selection
        let addExerciseButton = self.app.buttons["Add Exercise"]
        XCTAssertTrue(addExerciseButton.exists)
        addExerciseButton.tap()
    }

    private func setupEquipment(_ equipmentNames: [String]) {
        let workoutButton = self.app.buttons["Krafttraining"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 5))
        workoutButton.tap()

        let addEquipmentButton = self.app.buttons["Add Equipment"]
        if addEquipmentButton.exists {
            addEquipmentButton.tap()

            for equipment in equipmentNames {
                let equipmentRow = self.app.staticTexts[equipment]
                if equipmentRow.exists {
                    equipmentRow.tap()
                }
            }

            let doneButton = self.app.navigationBars.buttons["Done"]
            doneButton.tap()
        }
    }
}

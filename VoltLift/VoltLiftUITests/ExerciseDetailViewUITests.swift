import XCTest

final class ExerciseDetailViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Exercise Detail View Tests
    
    func testExerciseDetailViewNavigation() throws {
        // Navigate to exercise selection
        navigateToExerciseSelection()
        
        // Find and tap info button for first exercise
        let exercisesList = app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))
        
        let firstExerciseCell = exercisesList.cells.firstMatch
        XCTAssertTrue(firstExerciseCell.exists)
        
        let infoButton = firstExerciseCell.buttons["info.circle"]
        XCTAssertTrue(infoButton.exists, "Info button should be present")
        infoButton.tap()
        
        // Verify exercise detail view appears
        let exerciseDetailView = app.scrollViews.firstMatch
        XCTAssertTrue(exerciseDetailView.waitForExistence(timeout: 3))
        
        // Verify navigation elements
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should be present")
        
        // Verify navigation title exists (exercise name)
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists, "Navigation bar should be present")
    }
    
    func testExerciseDetailViewInformationDisplay() throws {
        navigateToExerciseDetailView()
        
        // Test header section elements
        let exerciseIcon = app.images.firstMatch
        XCTAssertTrue(exerciseIcon.exists, "Exercise icon should be displayed")
        
        // Test difficulty badge
        let difficultyBadges = app.staticTexts.matching(NSPredicate(format: "label IN {'Beginner', 'Intermediate', 'Advanced'}"))
        XCTAssertGreaterThan(difficultyBadges.count, 0, "Difficulty badge should be displayed")
        
        // Test muscle group badge
        let muscleGroupBadges = app.staticTexts.matching(NSPredicate(format: "label IN {'Chest', 'Back', 'Shoulders', 'Arms', 'Legs', 'Core', 'Full Body'}"))
        XCTAssertGreaterThan(muscleGroupBadges.count, 0, "Muscle group badge should be displayed")
        
        // Test section headers
        let descriptionHeader = app.staticTexts["Description"]
        XCTAssertTrue(descriptionHeader.exists, "Description section should be present")
        
        let instructionsHeader = app.staticTexts["Instructions"]
        XCTAssertTrue(instructionsHeader.exists, "Instructions section should be present")
        
        let safetyTipsHeader = app.staticTexts["Safety Tips"]
        XCTAssertTrue(safetyTipsHeader.exists, "Safety Tips section should be present")
        
        let targetMusclesHeader = app.staticTexts["Target Muscles"]
        XCTAssertTrue(targetMusclesHeader.exists, "Target Muscles section should be present")
    }
    
    func testExerciseInstructionsDisplay() throws {
        navigateToExerciseDetailView()
        
        // Scroll to instructions section
        let scrollView = app.scrollViews.firstMatch
        let instructionsHeader = app.staticTexts["Instructions"]
        
        if !instructionsHeader.isHittable {
            scrollView.swipeUp()
        }
        
        XCTAssertTrue(instructionsHeader.waitForExistence(timeout: 3))
        
        // Verify numbered instructions are present
        let numberedInstructions = app.staticTexts.matching(NSPredicate(format: "label MATCHES '^[1-9]$'"))
        XCTAssertGreaterThan(numberedInstructions.count, 0, "Numbered instruction steps should be displayed")
        
        // Verify instruction text is present
        let instructionTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'position' OR label CONTAINS 'movement' OR label CONTAINS 'exercise'"))
        XCTAssertGreaterThan(instructionTexts.count, 0, "Instruction text should be displayed")
    }
    
    func testSafetyTipsDisplay() throws {
        navigateToExerciseDetailView()
        
        // Scroll to safety tips section
        let scrollView = app.scrollViews.firstMatch
        let safetyTipsHeader = app.staticTexts["Safety Tips"]
        
        if !safetyTipsHeader.isHittable {
            scrollView.swipeUp()
        }
        
        XCTAssertTrue(safetyTipsHeader.waitForExistence(timeout: 3))
        
        // Verify safety tip checkmarks are present
        let checkmarkIcons = app.images["checkmark.circle.fill"]
        XCTAssertTrue(checkmarkIcons.exists, "Safety tip checkmarks should be displayed")
        
        // Verify safety tip text is present
        let safetyTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'keep' OR label CONTAINS 'maintain' OR label CONTAINS 'avoid'"))
        XCTAssertGreaterThan(safetyTexts.count, 0, "Safety tip text should be displayed")
    }
    
    func testTargetMusclesDisplay() throws {
        navigateToExerciseDetailView()
        
        // Scroll to target muscles section
        let scrollView = app.scrollViews.firstMatch
        let targetMusclesHeader = app.staticTexts["Target Muscles"]
        
        if !targetMusclesHeader.isHittable {
            scrollView.swipeUp()
        }
        
        XCTAssertTrue(targetMusclesHeader.waitForExistence(timeout: 3))
        
        // Verify primary muscles section
        let primaryHeader = app.staticTexts["Primary"]
        XCTAssertTrue(primaryHeader.exists, "Primary muscles section should be present")
        
        // Verify muscle indicators (circles) are present
        let muscleIndicators = app.images.matching(NSPredicate(format: "identifier CONTAINS 'circle'"))
        XCTAssertGreaterThan(muscleIndicators.count, 0, "Muscle indicators should be displayed")
        
        // Check for secondary muscles if they exist
        let secondaryHeader = app.staticTexts["Secondary"]
        if secondaryHeader.exists {
            // Verify secondary muscles are displayed differently from primary
            XCTAssertTrue(secondaryHeader.isHittable, "Secondary muscles section should be accessible")
        }
    }
    
    func testExerciseVariationsDisplay() throws {
        navigateToExerciseDetailView()
        
        // Scroll to variations section (if it exists)
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp() // Scroll more to reach variations
        
        let variationsHeader = app.staticTexts["Variations"]
        
        if variationsHeader.exists {
            // Verify variation cards are displayed
            let variationCards = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'variation'"))
            
            // Verify difficulty indicators for variations
            let difficultyIndicators = app.images.matching(NSPredicate(format: "identifier CONTAINS 'circle'"))
            XCTAssertGreaterThan(difficultyIndicators.count, 0, "Difficulty indicators should be present for variations")
        }
    }
    
    func testEquipmentRequirementsDisplay() throws {
        // Navigate to an exercise that requires equipment
        navigateToExerciseSelection()
        
        // Set up some equipment first to see equipment requirements
        app.navigationBars.buttons.firstMatch.tap() // Go back
        setupEquipment(["Dumbbells"])
        navigateToExerciseSelection()
        
        // Find an exercise that requires equipment
        let exercisesList = app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))
        
        // Look for an exercise with equipment requirements
        let exerciseCells = exercisesList.cells
        var foundEquipmentExercise = false
        
        for i in 0..<min(5, exerciseCells.count) {
            let cell = exerciseCells.element(boundBy: i)
            let needsText = cell.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Needs:'")).firstMatch
            
            if needsText.exists {
                let infoButton = cell.buttons["info.circle"]
                infoButton.tap()
                foundEquipmentExercise = true
                break
            }
        }
        
        if foundEquipmentExercise {
            // Verify equipment section is displayed
            let equipmentHeader = app.staticTexts["Required Equipment"]
            XCTAssertTrue(equipmentHeader.waitForExistence(timeout: 3), "Equipment requirements should be displayed")
            
            // Verify equipment icons are present
            let equipmentIcons = app.images.matching(NSPredicate(format: "identifier CONTAINS 'wrench' OR identifier CONTAINS 'dumbbell'"))
            XCTAssertGreaterThan(equipmentIcons.count, 0, "Equipment icons should be displayed")
        }
    }
    
    func testAddToWorkoutFromDetailView() throws {
        navigateToExerciseDetailView()
        
        // Scroll to bottom to find Add to Workout button
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        scrollView.swipeUp()
        
        let addToWorkoutButton = app.buttons["Add to Workout"]
        XCTAssertTrue(addToWorkoutButton.waitForExistence(timeout: 3), "Add to Workout button should be present")
        
        addToWorkoutButton.tap()
        
        // Verify we're back to exercise selection with exercise selected
        let exerciseSelectionTitle = app.navigationBars["Add Exercise"]
        XCTAssertTrue(exerciseSelectionTitle.waitForExistence(timeout: 3), "Should return to exercise selection")
        
        // Verify the exercise is now selected
        let selectedIcon = app.images["checkmark.circle.fill"]
        XCTAssertTrue(selectedIcon.exists, "Exercise should be selected after adding from detail view")
    }
    
    func testExerciseDetailViewAccessibility() throws {
        navigateToExerciseDetailView()
        
        // Test that key elements have accessibility labels
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.isAccessibilityElement || scrollView.exists, "Main content should be accessible")
        
        // Test navigation elements
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.isAccessibilityElement, "Done button should be accessible")
        
        // Test that section headers are accessible
        let descriptionHeader = app.staticTexts["Description"]
        XCTAssertTrue(descriptionHeader.isAccessibilityElement, "Section headers should be accessible")
        
        // Test that the add to workout button is accessible
        scrollView.swipeUp()
        scrollView.swipeUp()
        
        let addToWorkoutButton = app.buttons["Add to Workout"]
        if addToWorkoutButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(addToWorkoutButton.isAccessibilityElement, "Add to Workout button should be accessible")
        }
    }
    
    func testExerciseDetailViewDismissal() throws {
        navigateToExerciseDetailView()
        
        // Test dismissal via Done button
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists)
        doneButton.tap()
        
        // Verify we're back to exercise selection
        let exerciseSelectionTitle = app.navigationBars["Add Exercise"]
        XCTAssertTrue(exerciseSelectionTitle.waitForExistence(timeout: 3), "Should return to exercise selection")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToExerciseSelection() {
        // Navigate to workout setup
        let workoutButton = app.buttons["Krafttraining"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 5))
        workoutButton.tap()
        
        // Skip equipment setup if needed
        let addPlanButton = app.buttons["Add Plan"]
        if !addPlanButton.exists {
            let addEquipmentButton = app.buttons["Add Equipment"]
            if addEquipmentButton.exists {
                addEquipmentButton.tap()
                let doneButton = app.navigationBars.buttons["Done"]
                doneButton.tap()
            }
        }
        
        // Create a plan
        XCTAssertTrue(addPlanButton.waitForExistence(timeout: 3))
        addPlanButton.tap()
        
        // Enter plan name
        let planNameField = app.textFields["Name"]
        XCTAssertTrue(planNameField.waitForExistence(timeout: 3))
        planNameField.tap()
        planNameField.typeText("Test Plan")
        
        // Navigate to exercise selection
        let addExerciseButton = app.buttons["Add Exercise"]
        XCTAssertTrue(addExerciseButton.exists)
        addExerciseButton.tap()
    }
    
    private func navigateToExerciseDetailView() {
        navigateToExerciseSelection()
        
        // Find and tap info button for first exercise
        let exercisesList = app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))
        
        let firstExerciseCell = exercisesList.cells.firstMatch
        XCTAssertTrue(firstExerciseCell.exists)
        
        let infoButton = firstExerciseCell.buttons["info.circle"]
        XCTAssertTrue(infoButton.exists)
        infoButton.tap()
        
        // Wait for detail view to appear
        let exerciseDetailView = app.scrollViews.firstMatch
        XCTAssertTrue(exerciseDetailView.waitForExistence(timeout: 3))
    }
    
    private func setupEquipment(_ equipmentNames: [String]) {
        let workoutButton = app.buttons["Krafttraining"]
        XCTAssertTrue(workoutButton.waitForExistence(timeout: 5))
        workoutButton.tap()
        
        let addEquipmentButton = app.buttons["Add Equipment"]
        if addEquipmentButton.exists {
            addEquipmentButton.tap()
            
            for equipment in equipmentNames {
                let equipmentRow = app.staticTexts[equipment]
                if equipmentRow.exists {
                    equipmentRow.tap()
                }
            }
            
            let doneButton = app.navigationBars.buttons["Done"]
            doneButton.tap()
        }
        
        // Go back to main screen
        app.navigationBars.buttons.firstMatch.tap()
    }
}
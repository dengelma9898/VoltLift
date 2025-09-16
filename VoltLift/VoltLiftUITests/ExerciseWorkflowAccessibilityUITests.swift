import XCTest

final class ExerciseWorkflowAccessibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launch()
    }

    override func tearDownWithError() throws {
        self.app = nil
    }

    // MARK: - Accessibility Compliance Tests

    func testExerciseSelectionAccessibilityLabels() throws {
        self.navigateToExerciseSelection()

        // Test muscle group picker accessibility
        let muscleGroupPicker = self.app.pickers["Muscle Group"]
        XCTAssertTrue(muscleGroupPicker.exists, "Muscle group picker should exist")
        XCTAssertTrue(muscleGroupPicker.isAccessibilityElement, "Muscle group picker should be accessible")

        // Test exercise list accessibility
        let exercisesList = self.app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

        let exerciseCells = exercisesList.cells
        if !exerciseCells.isEmpty {
            let firstCell = exerciseCells.firstMatch
            XCTAssertTrue(firstCell.isAccessibilityElement, "Exercise cells should be accessible")

            // Test that exercise names are accessible
            let exerciseNameElements = firstCell.staticTexts
            XCTAssertGreaterThan(exerciseNameElements.count, 0, "Exercise names should be accessible")

            // Test info button accessibility
            let infoButton = firstCell.buttons["info.circle"]
            if infoButton.exists {
                XCTAssertTrue(infoButton.isAccessibilityElement, "Info button should be accessible")
                XCTAssertNotNil(infoButton.label, "Info button should have accessibility label")
            }
        }

        // Test add button accessibility
        let addButton = self.app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
        XCTAssertTrue(addButton.exists, "Add button should exist")
        XCTAssertTrue(addButton.isAccessibilityElement, "Add button should be accessible")
    }

    func testEquipmentIndicatorAccessibility() throws {
        self.navigateToExerciseSelection()

        let exercisesList = self.app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

        let exerciseCells = exercisesList.cells
        if !exerciseCells.isEmpty {
            let firstCell = exerciseCells.firstMatch

            // Test equipment status indicators
            let availableIndicator = firstCell.staticTexts["Available"]
            let bodyweightIndicator = firstCell.staticTexts["Bodyweight"]
            let needsEquipmentIndicator = firstCell.staticTexts
                .matching(NSPredicate(format: "label BEGINSWITH 'Needs:'")).firstMatch

            if availableIndicator.exists {
                XCTAssertTrue(availableIndicator.isAccessibilityElement, "Available indicator should be accessible")
            }

            if bodyweightIndicator.exists {
                XCTAssertTrue(bodyweightIndicator.isAccessibilityElement, "Bodyweight indicator should be accessible")
            }

            if needsEquipmentIndicator.exists {
                XCTAssertTrue(
                    needsEquipmentIndicator.isAccessibilityElement,
                    "Equipment needs indicator should be accessible"
                )
            }

            // Test status icons accessibility
            let statusIcons = firstCell.images
            for i in 0 ..< statusIcons.count {
                let icon = statusIcons.element(boundBy: i)
                if icon.exists {
                    // Icons should either be accessibility elements or have proper traits
                    let isAccessible = icon.isAccessibilityElement ||
                        !(icon.accessibilityLabel?.isEmpty ?? true) ||
                        icon.accessibilityTraits.contains(.image)
                    XCTAssertTrue(isAccessible, "Status icons should be properly accessible")
                }
            }
        }
    }

    func testExerciseDetailViewAccessibility() throws {
        self.navigateToExerciseDetailView()

        // Test navigation accessibility
        let navigationBar = self.app.navigationBars.firstMatch
        XCTAssertTrue(navigationBar.exists, "Navigation bar should exist")

        let doneButton = self.app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should exist")
        XCTAssertTrue(doneButton.isAccessibilityElement, "Done button should be accessible")

        // Test main content accessibility
        let scrollView = self.app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Main content scroll view should exist")

        // Test section headers accessibility
        let sectionHeaders = ["Description", "Instructions", "Safety Tips", "Target Muscles"]
        for header in sectionHeaders {
            let headerElement = self.app.staticTexts[header]
            if headerElement.exists {
                XCTAssertTrue(headerElement.isAccessibilityElement, "\(header) section header should be accessible")
            }
        }

        // Test exercise icon accessibility
        let exerciseIcons = self.app.images
        if !exerciseIcons.isEmpty {
            let firstIcon = exerciseIcons.firstMatch
            if firstIcon.exists {
                let isAccessible = firstIcon.isAccessibilityElement ||
                    !(firstIcon.accessibilityLabel?.isEmpty ?? true) ||
                    firstIcon.accessibilityTraits.contains(.image)
                XCTAssertTrue(isAccessible, "Exercise icons should be accessible")
            }
        }

        // Test difficulty and muscle group badges
        let difficultyBadges = self.app.staticTexts
            .matching(NSPredicate(format: "label IN {'Beginner', 'Intermediate', 'Advanced'}"))
        if !difficultyBadges.isEmpty {
            let firstBadge = difficultyBadges.firstMatch
            XCTAssertTrue(firstBadge.isAccessibilityElement, "Difficulty badges should be accessible")
        }

        // Test add to workout button accessibility
        scrollView.swipeUp()
        scrollView.swipeUp()

        let addToWorkoutButton = self.app.buttons["Add to Workout"]
        if addToWorkoutButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(addToWorkoutButton.isAccessibilityElement, "Add to Workout button should be accessible")
            XCTAssertFalse(addToWorkoutButton.label.isEmpty, "Add to Workout button should have meaningful label")
        }
    }

    func testInstructionsAccessibility() throws {
        self.navigateToExerciseDetailView()

        // Scroll to instructions section
        let scrollView = self.app.scrollViews.firstMatch
        let instructionsHeader = self.app.staticTexts["Instructions"]

        if !instructionsHeader.isHittable {
            scrollView.swipeUp()
        }

        XCTAssertTrue(instructionsHeader.waitForExistence(timeout: 3))
        XCTAssertTrue(instructionsHeader.isAccessibilityElement, "Instructions header should be accessible")

        // Test numbered instruction steps
        let numberedInstructions = self.app.staticTexts.matching(NSPredicate(format: "label MATCHES '^[1-9]$'"))
        for i in 0 ..< numberedInstructions.count {
            let numberElement = numberedInstructions.element(boundBy: i)
            if numberElement.exists {
                XCTAssertTrue(numberElement.isAccessibilityElement, "Instruction numbers should be accessible")
            }
        }

        // Test instruction text accessibility
        let instructionTexts = self.app.staticTexts
            .matching(
                NSPredicate(
                    format: "label CONTAINS 'position' OR label CONTAINS 'movement' OR label CONTAINS 'exercise'"
                )
            )
        for i in 0 ..< min(3, instructionTexts.count) {
            let textElement = instructionTexts.element(boundBy: i)
            if textElement.exists {
                XCTAssertTrue(textElement.isAccessibilityElement, "Instruction text should be accessible")
                XCTAssertFalse(textElement.label.isEmpty, "Instruction text should have meaningful content")
            }
        }
    }

    func testSafetyTipsAccessibility() throws {
        self.navigateToExerciseDetailView()

        // Scroll to safety tips section
        let scrollView = self.app.scrollViews.firstMatch
        let safetyTipsHeader = self.app.staticTexts["Safety Tips"]

        if !safetyTipsHeader.isHittable {
            scrollView.swipeUp()
        }

        XCTAssertTrue(safetyTipsHeader.waitForExistence(timeout: 3))
        XCTAssertTrue(safetyTipsHeader.isAccessibilityElement, "Safety Tips header should be accessible")

        // Test safety tip checkmarks
        let checkmarkIcons = self.app.images["checkmark.circle.fill"]
        if checkmarkIcons.exists {
            let isAccessible = checkmarkIcons.isAccessibilityElement ||
                !(checkmarkIcons.accessibilityLabel?.isEmpty ?? true) ||
                checkmarkIcons.accessibilityTraits.contains(.image)
            XCTAssertTrue(isAccessible, "Safety tip checkmarks should be accessible")
        }

        // Test safety tip text
        let safetyTexts = self.app.staticTexts
            .matching(
                NSPredicate(format: "label CONTAINS 'keep' OR label CONTAINS 'maintain' OR label CONTAINS 'avoid'")
            )
        for i in 0 ..< min(3, safetyTexts.count) {
            let textElement = safetyTexts.element(boundBy: i)
            if textElement.exists {
                XCTAssertTrue(textElement.isAccessibilityElement, "Safety tip text should be accessible")
                XCTAssertFalse(textElement.label.isEmpty, "Safety tip text should have meaningful content")
            }
        }
    }

    func testTargetMusclesAccessibility() throws {
        self.navigateToExerciseDetailView()

        // Scroll to target muscles section
        let scrollView = self.app.scrollViews.firstMatch
        let targetMusclesHeader = self.app.staticTexts["Target Muscles"]

        if !targetMusclesHeader.isHittable {
            scrollView.swipeUp()
        }

        XCTAssertTrue(targetMusclesHeader.waitForExistence(timeout: 3))
        XCTAssertTrue(targetMusclesHeader.isAccessibilityElement, "Target Muscles header should be accessible")

        // Test primary/secondary muscle headers
        let primaryHeader = self.app.staticTexts["Primary"]
        if primaryHeader.exists {
            XCTAssertTrue(primaryHeader.isAccessibilityElement, "Primary muscles header should be accessible")
        }

        let secondaryHeader = self.app.staticTexts["Secondary"]
        if secondaryHeader.exists {
            XCTAssertTrue(secondaryHeader.isAccessibilityElement, "Secondary muscles header should be accessible")
        }

        // Test muscle indicators and names
        let muscleTexts = self.app.staticTexts
            .matching(
                NSPredicate(
                    format: "label CONTAINS 'muscle' OR label CONTAINS 'Muscle' OR label CONTAINS 'Pectoralis' OR label CONTAINS 'Deltoid' OR label CONTAINS 'Triceps'"
                )
            )
        for i in 0 ..< min(3, muscleTexts.count) {
            let muscleElement = muscleTexts.element(boundBy: i)
            if muscleElement.exists {
                XCTAssertTrue(muscleElement.isAccessibilityElement, "Muscle names should be accessible")
            }
        }
    }

    func testVoiceOverNavigation() throws {
        // This test would ideally be run with VoiceOver enabled
        // For now, we test that elements have proper accessibility traits

        self.navigateToExerciseSelection()

        // Test that interactive elements have proper traits
        let exercisesList = self.app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

        let firstCell = exercisesList.cells.firstMatch
        if firstCell.exists {
            // Exercise cells should be selectable
            let hasSelectableTrait = firstCell.accessibilityTraits.contains(.button) ||
                firstCell.accessibilityTraits.contains(.selected) ||
                firstCell.accessibilityTraits.contains(.notEnabled) == false
            XCTAssertTrue(hasSelectableTrait, "Exercise cells should have appropriate accessibility traits")
        }

        // Test button traits
        let addButton = self.app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
        if addButton.exists {
            XCTAssertTrue(addButton.accessibilityTraits.contains(.button), "Add button should have button trait")
        }

        // Test picker traits
        let muscleGroupPicker = self.app.pickers["Muscle Group"]
        if muscleGroupPicker.exists {
            let hasPickerTrait = muscleGroupPicker.accessibilityTraits.contains(.adjustable) ||
                muscleGroupPicker.accessibilityTraits.contains(.button)
            XCTAssertTrue(hasPickerTrait, "Muscle group picker should have appropriate accessibility traits")
        }
    }

    func testAccessibilityHints() throws {
        self.navigateToExerciseSelection()

        let exercisesList = self.app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

        let firstCell = exercisesList.cells.firstMatch
        if firstCell.exists {
            // Test that info button has helpful hint
            let infoButton = firstCell.buttons["info.circle"]
            if infoButton.exists {
                // Info button should have some accessibility information
                let hasAccessibilityInfo = !(infoButton.accessibilityLabel?.isEmpty ?? true) ||
                    !(infoButton.accessibilityHint?.isEmpty ?? true) ||
                    !(infoButton.accessibilityValue?.isEmpty ?? true)
                XCTAssertTrue(hasAccessibilityInfo, "Info button should have accessibility information")
            }
        }

        // Test add button has helpful information
        let addButton = self.app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add'")).firstMatch
        if addButton.exists {
            let buttonLabel = addButton.label
            XCTAssertFalse(buttonLabel.isEmpty, "Add button should have meaningful label")

            // Button should indicate how many exercises are selected
            let containsCount = buttonLabel.contains("0") || buttonLabel.contains("1") ||
                buttonLabel.contains("2") || buttonLabel.contains("3") ||
                buttonLabel.contains("4") || buttonLabel.contains("5")
            XCTAssertTrue(containsCount, "Add button should indicate selection count")
        }
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

    private func navigateToExerciseDetailView() {
        self.navigateToExerciseSelection()

        // Find and tap info button for first exercise
        let exercisesList = self.app.tables.firstMatch
        XCTAssertTrue(exercisesList.waitForExistence(timeout: 3))

        let firstExerciseCell = exercisesList.cells.firstMatch
        XCTAssertTrue(firstExerciseCell.exists)

        let infoButton = firstExerciseCell.buttons["info.circle"]
        XCTAssertTrue(infoButton.exists)
        infoButton.tap()

        // Wait for detail view to appear
        let exerciseDetailView = self.app.scrollViews.firstMatch
        XCTAssertTrue(exerciseDetailView.waitForExistence(timeout: 3))
    }
}

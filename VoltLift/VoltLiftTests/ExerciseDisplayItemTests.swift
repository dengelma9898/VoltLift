//
//  ExerciseDisplayItemTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

@testable import VoltLift
import XCTest

final class ExerciseDisplayItemTests: XCTestCase {
    // MARK: - ExerciseDisplayItem Initialization Tests

    func testExerciseDisplayItem_WithNoEquipmentRequired_IsAvailable() {
        // Given
        let exercise = Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )
        let availableEquipment: Set<String> = []

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertTrue(displayItem.isAvailable)
        XCTAssertTrue(displayItem.missingEquipment.isEmpty)
        XCTAssertEqual(displayItem.id, exercise.id)
        XCTAssertEqual(displayItem.exercise, exercise)
    }

    func testExerciseDisplayItem_WithAvailableEquipment_IsAvailable() {
        // Given
        let exercise = Exercise(
            name: "Dumbbell Press",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        )
        let availableEquipment: Set<String> = ["Dumbbells", "Adjustable Bench"]

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertTrue(displayItem.isAvailable)
        XCTAssertTrue(displayItem.missingEquipment.isEmpty)
    }

    func testExerciseDisplayItem_WithPartiallyAvailableEquipment_IsNotAvailable() {
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells", "Adjustable Bench"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        )
        let availableEquipment: Set<String> = ["Dumbbells"]

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertFalse(displayItem.isAvailable)
        XCTAssertEqual(displayItem.missingEquipment, ["Adjustable Bench"])
    }

    func testExerciseDisplayItem_WithNoAvailableEquipment_IsNotAvailable() {
        // Given
        let exercise = Exercise(
            name: "Barbell Squat",
            muscleGroup: .legs,
            requiredEquipment: ["Barbell", "Weight Plates"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        )
        let availableEquipment: Set<String> = []

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertFalse(displayItem.isAvailable)
        XCTAssertEqual(displayItem.missingEquipment, ["Barbell", "Weight Plates"])
    }

    func testExerciseDisplayItem_WithComplexEquipmentRequirements_CalculatesCorrectly() {
        // Given
        let exercise = Exercise(
            name: "Cable Fly",
            muscleGroup: .chest,
            requiredEquipment: ["Cable Machine", "Adjustable Bench", "Cable Attachments"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .advanced,
            sfSymbolName: "bolt.horizontal.circle"
        )
        let availableEquipment: Set<String> = ["Cable Machine", "Dumbbells"]

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertFalse(displayItem.isAvailable)
        XCTAssertEqual(displayItem.missingEquipment, ["Adjustable Bench", "Cable Attachments"])
    }

    // MARK: - ExerciseDisplayItem Equality Tests

    func testExerciseDisplayItem_Equality_WithSameExerciseAndEquipment_ReturnsTrue() {
        // Given
        let exercise = Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )
        let availableEquipment: Set<String> = ["Dumbbells"]

        let displayItem1 = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)
        let displayItem2 = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // When & Then
        XCTAssertEqual(displayItem1, displayItem2)
        XCTAssertEqual(displayItem1.hashValue, displayItem2.hashValue)
    }

    func testExerciseDisplayItem_Equality_WithDifferentExercises_ReturnsFalse() {
        // Given
        let exercise1 = Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )

        let exercise2 = Exercise(
            name: "Pull-up",
            muscleGroup: .back,
            requiredEquipment: ["Pull-up Bar"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .advanced,
            sfSymbolName: "figure.climbing"
        )

        let availableEquipment: Set<String> = []

        let displayItem1 = ExerciseDisplayItem(exercise: exercise1, availableEquipment: availableEquipment)
        let displayItem2 = ExerciseDisplayItem(exercise: exercise2, availableEquipment: availableEquipment)

        // When & Then
        XCTAssertNotEqual(displayItem1, displayItem2)
    }

    // MARK: - Equipment Filtering Logic Tests

    func testEquipmentFiltering_WithEmptyEquipmentSet_ShowsOnlyBodyweightExercises() {
        // Given
        let exercises = [
            Exercise(
                name: "Push-up",
                muscleGroup: .chest,
                requiredEquipment: [],
                description: "Test",
                instructions: ["Test"],
                safetyTips: ["Test"],
                targetMuscles: ["Test"],
                difficulty: .beginner,
                sfSymbolName: "figure.strengthtraining.traditional"
            ),
            Exercise(
                name: "Dumbbell Press",
                muscleGroup: .chest,
                requiredEquipment: ["Dumbbells"],
                description: "Test",
                instructions: ["Test"],
                safetyTips: ["Test"],
                targetMuscles: ["Test"],
                difficulty: .intermediate,
                sfSymbolName: "dumbbell"
            )
        ]
        let availableEquipment: Set<String> = []

        // When
        let displayItems = exercises.map { ExerciseDisplayItem(exercise: $0, availableEquipment: availableEquipment) }
        let availableItems = displayItems.filter(\.isAvailable)
        let unavailableItems = displayItems.filter { !$0.isAvailable }

        // Then
        XCTAssertEqual(availableItems.count, 1)
        XCTAssertEqual(unavailableItems.count, 1)
        XCTAssertEqual(availableItems.first?.exercise.name, "Push-up")
        XCTAssertEqual(unavailableItems.first?.exercise.name, "Dumbbell Press")
    }

    func testEquipmentFiltering_WithSpecificEquipment_ShowsCorrectAvailability() {
        // Given
        let exercises = [
            Exercise(
                name: "Push-up",
                muscleGroup: .chest,
                requiredEquipment: [],
                description: "Test",
                instructions: ["Test"],
                safetyTips: ["Test"],
                targetMuscles: ["Test"],
                difficulty: .beginner,
                sfSymbolName: "figure.strengthtraining.traditional"
            ),
            Exercise(
                name: "Dumbbell Press",
                muscleGroup: .chest,
                requiredEquipment: ["Dumbbells"],
                description: "Test",
                instructions: ["Test"],
                safetyTips: ["Test"],
                targetMuscles: ["Test"],
                difficulty: .intermediate,
                sfSymbolName: "dumbbell"
            ),
            Exercise(
                name: "Bench Press",
                muscleGroup: .chest,
                requiredEquipment: ["Dumbbells", "Adjustable Bench"],
                description: "Test",
                instructions: ["Test"],
                safetyTips: ["Test"],
                targetMuscles: ["Test"],
                difficulty: .intermediate,
                sfSymbolName: "dumbbell"
            )
        ]
        let availableEquipment: Set<String> = ["Dumbbells"]

        // When
        let displayItems = exercises.map { ExerciseDisplayItem(exercise: $0, availableEquipment: availableEquipment) }
        let availableItems = displayItems.filter(\.isAvailable)
        let unavailableItems = displayItems.filter { !$0.isAvailable }

        // Then
        XCTAssertEqual(availableItems.count, 2) // Push-up and Dumbbell Press
        XCTAssertEqual(unavailableItems.count, 1) // Bench Press

        let availableNames = Set(availableItems.map(\.exercise.name))
        XCTAssertTrue(availableNames.contains("Push-up"))
        XCTAssertTrue(availableNames.contains("Dumbbell Press"))

        let unavailableNames = Set(unavailableItems.map(\.exercise.name))
        XCTAssertTrue(unavailableNames.contains("Bench Press"))
    }

    // MARK: - Missing Equipment Calculation Tests

    func testMissingEquipmentCalculation_WithSingleMissingItem_ReturnsCorrectSet() {
        // Given
        let exercise = Exercise(
            name: "Bench Press",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells", "Adjustable Bench"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        )
        let availableEquipment: Set<String> = ["Dumbbells"]

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertEqual(displayItem.missingEquipment, ["Adjustable Bench"])
    }

    func testMissingEquipmentCalculation_WithMultipleMissingItems_ReturnsCorrectSet() {
        // Given
        let exercise = Exercise(
            name: "Cable Fly",
            muscleGroup: .chest,
            requiredEquipment: ["Cable Machine", "Adjustable Bench", "Cable Attachments"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .advanced,
            sfSymbolName: "bolt.horizontal.circle"
        )
        let availableEquipment: Set<String> = ["Cable Machine"]

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertEqual(displayItem.missingEquipment, ["Adjustable Bench", "Cable Attachments"])
    }

    func testMissingEquipmentCalculation_WithNoMissingItems_ReturnsEmptySet() {
        // Given
        let exercise = Exercise(
            name: "Dumbbell Press",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        )
        let availableEquipment: Set<String> = ["Dumbbells", "Adjustable Bench", "Pull-up Bar"]

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertTrue(displayItem.missingEquipment.isEmpty)
    }

    // MARK: - Edge Cases Tests

    func testExerciseDisplayItem_WithEmptyRequiredEquipment_AlwaysAvailable() {
        // Given
        let exercise = Exercise(
            name: "Bodyweight Squat",
            muscleGroup: .legs,
            requiredEquipment: [],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )

        let testCases: [Set<String>] = [
            [],
            ["Dumbbells"],
            ["Dumbbells", "Adjustable Bench", "Pull-up Bar"]
        ]

        // When & Then
        for availableEquipment in testCases {
            let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)
            XCTAssertTrue(
                displayItem.isAvailable,
                "Bodyweight exercise should always be available regardless of equipment"
            )
            XCTAssertTrue(
                displayItem.missingEquipment.isEmpty,
                "Bodyweight exercise should have no missing equipment"
            )
        }
    }

    func testExerciseDisplayItem_WithLargeEquipmentSet_HandlesCorrectly() {
        // Given
        let exercise = Exercise(
            name: "Complex Exercise",
            muscleGroup: .fullBody,
            requiredEquipment: ["Dumbbells", "Barbell", "Weight Plates", "Adjustable Bench", "Pull-up Bar"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .advanced,
            sfSymbolName: "dumbbell"
        )
        let availableEquipment: Set<String> = ["Dumbbells", "Pull-up Bar"]

        // When
        let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: availableEquipment)

        // Then
        XCTAssertFalse(displayItem.isAvailable)
        XCTAssertEqual(displayItem.missingEquipment, ["Barbell", "Weight Plates", "Adjustable Bench"])
    }
}

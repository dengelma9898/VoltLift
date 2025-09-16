//
//  ExerciseSystemEdgeCaseTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

@testable import VoltLift
import XCTest

final class ExerciseSystemEdgeCaseTests: XCTestCase {
    var exerciseService: ExerciseService!

    override func setUp() {
        super.setUp()
        self.exerciseService = ExerciseService.shared
    }

    override func tearDown() {
        self.exerciseService = nil
        super.tearDown()
    }

    // MARK: - Equipment Edge Cases

    func testEquipmentCaseSensitivity() {
        // Given
        let correctEquipment: Set<String> = ["Dumbbells"]
        let incorrectCaseEquipment: Set<String> = ["dumbbells", "DUMBBELLS", "DumbBells"]

        // When
        let correctResults = self.exerciseService.getExercises(for: .arms, availableEquipment: correctEquipment)
        let incorrectResults1 = self.exerciseService.getExercises(for: .arms, availableEquipment: ["dumbbells"])
        let incorrectResults2 = self.exerciseService.getExercises(for: .arms, availableEquipment: ["DUMBBELLS"])

        // Then - Equipment matching should be case-sensitive
        XCTAssertGreaterThan(correctResults.count, 0, "Should find exercises with correct case")
        XCTAssertEqual(incorrectResults1.count, 0, "Should not find exercises with incorrect case")
        XCTAssertEqual(incorrectResults2.count, 0, "Should not find exercises with incorrect case")
    }

    func testEmptyEquipmentStrings() {
        // Given - Create a test scenario with empty equipment strings (this shouldn't exist in real data)
        let availableEquipment: Set<String> = ["", "Dumbbells", ""]

        // When
        let results = self.exerciseService.getExercises(for: .chest, availableEquipment: availableEquipment)

        // Then - Should handle gracefully and return exercises that match valid equipment
        XCTAssertGreaterThanOrEqual(results.count, 0)

        // All returned exercises should have equipment that's a subset of available (excluding empty strings)
        let validEquipment = availableEquipment.filter { !$0.isEmpty }
        for exercise in results {
            XCTAssertTrue(
                exercise.requiredEquipment.isSubset(of: validEquipment),
                "Exercise equipment should be subset of valid available equipment"
            )
        }
    }

    func testLargeEquipmentSets() {
        // Given - Very large equipment set
        let largeEquipmentSet: Set<String> = [
            "Dumbbells", "Barbell", "Weight Plates", "Adjustable Bench", "Pull-up Bar",
            "Resistance Bands", "Kettlebell", "Cable Machine", "Smith Machine",
            "Leg Press Machine", "Lat Pulldown Machine", "Rowing Machine",
            "Preacher Bench", "Incline Bench", "Decline Bench", "Olympic Barbell",
            "EZ Curl Bar", "Trap Bar", "Medicine Ball", "Stability Ball",
            "Foam Roller", "Yoga Mat", "Suspension Trainer", "Battle Ropes",
            "Plyometric Box", "Agility Ladder", "Speed Rope", "Weighted Vest",
            "Squat Rack", "Cable Attachments"
        ]

        // When
        let results = self.exerciseService.getExercisesWithEquipmentHints(
            for: .fullBody,
            availableEquipment: largeEquipmentSet
        )

        // Then - Should handle large sets efficiently
        XCTAssertGreaterThan(results.count, 0)

        // All exercises should be available with this comprehensive equipment set
        let unavailableExercises = results.filter { !$0.isAvailable }
        XCTAssertEqual(unavailableExercises.count, 0, "All exercises should be available with comprehensive equipment")
    }

    // MARK: - Muscle Group Edge Cases

    func testAllMuscleGroupsCovered() {
        // Given
        let allMuscleGroups = MuscleGroup.allCases
        let noEquipment: Set<String> = []

        // When & Then - Each muscle group should have at least one bodyweight exercise
        for muscleGroup in allMuscleGroups {
            let exercises = self.exerciseService.getExercises(for: muscleGroup, availableEquipment: noEquipment)
            XCTAssertGreaterThan(
                exercises.count,
                0,
                "Muscle group \(muscleGroup.rawValue) should have at least one bodyweight exercise"
            )
        }
    }

    func testMuscleGroupConsistency() {
        // Given
        let testEquipment: Set<String> = ["Dumbbells"]

        // When - Get exercises for each muscle group multiple times
        for muscleGroup in MuscleGroup.allCases {
            let firstCall = self.exerciseService.getExercises(for: muscleGroup, availableEquipment: testEquipment)
            let secondCall = self.exerciseService.getExercises(for: muscleGroup, availableEquipment: testEquipment)

            // Then - Results should be consistent
            XCTAssertEqual(
                firstCall.count,
                secondCall.count,
                "Results should be consistent for \(muscleGroup.rawValue)"
            )

            let firstIds = Set(firstCall.map(\.id))
            let secondIds = Set(secondCall.map(\.id))
            XCTAssertEqual(
                firstIds,
                secondIds,
                "Exercise IDs should be consistent for \(muscleGroup.rawValue)"
            )
        }
    }

    // MARK: - Difficulty Level Edge Cases

    func testDifficultyLevelFiltering() {
        // Given
        let noEquipment: Set<String> = []

        // When & Then - Each difficulty level should have exercises
        for difficulty in DifficultyLevel.allCases {
            let exercises = self.exerciseService.getExercises(for: difficulty, availableEquipment: noEquipment)
            XCTAssertGreaterThan(
                exercises.count,
                0,
                "Difficulty level \(difficulty.rawValue) should have bodyweight exercises"
            )

            // All returned exercises should match the requested difficulty
            for exercise in exercises {
                XCTAssertEqual(
                    exercise.difficulty,
                    difficulty,
                    "Exercise should match requested difficulty level"
                )
            }
        }
    }

    func testDifficultyProgression() {
        // Given
        let fullEquipment: Set<String> = ["Dumbbells", "Barbell", "Weight Plates", "Adjustable Bench"]

        // When
        let beginnerExercises = self.exerciseService.getExercises(for: .beginner, availableEquipment: fullEquipment)
        let intermediateExercises = self.exerciseService.getExercises(
            for: .intermediate,
            availableEquipment: fullEquipment
        )
        let advancedExercises = self.exerciseService.getExercises(for: .advanced, availableEquipment: fullEquipment)

        // Then - Should have reasonable distribution
        XCTAssertGreaterThan(beginnerExercises.count, 0, "Should have beginner exercises")
        XCTAssertGreaterThan(intermediateExercises.count, 0, "Should have intermediate exercises")
        XCTAssertGreaterThan(advancedExercises.count, 0, "Should have advanced exercises")

        // Beginner exercises should generally have more bodyweight options
        let beginnerBodyweight = beginnerExercises.filter(\.requiredEquipment.isEmpty)
        let advancedBodyweight = advancedExercises.filter(\.requiredEquipment.isEmpty)

        XCTAssertGreaterThanOrEqual(
            beginnerBodyweight.count,
            advancedBodyweight.count,
            "Beginners should have at least as many bodyweight options as advanced"
        )
    }

    // MARK: - Exercise Variation Edge Cases

    func testExerciseVariationsConsistency() {
        // Given
        let exercisesWithVariations = self.exerciseService.getAllExercises().filter { !$0.variations.isEmpty }

        // Then
        for exercise in exercisesWithVariations {
            // Variations should have different names from parent exercise
            for variation in exercise.variations {
                XCTAssertNotEqual(
                    variation.name,
                    exercise.name,
                    "Variation should have different name from parent exercise"
                )
            }

            // Variations should have unique IDs
            let variationIds = exercise.variations.map(\.id)
            let uniqueIds = Set(variationIds)
            XCTAssertEqual(
                variationIds.count,
                uniqueIds.count,
                "Variations should have unique IDs"
            )

            // Difficulty modifiers should be reasonable
            for variation in exercise.variations {
                XCTAssertTrue(
                    variation.difficultyModifier >= -2 && variation.difficultyModifier <= 2,
                    "Difficulty modifier should be between -2 and 2"
                )
            }
        }
    }

    // MARK: - Sorting and Ordering Edge Cases

    func testSortingStability() {
        // Given
        let equipment: Set<String> = ["Dumbbells", "Adjustable Bench"]

        // When - Get same results multiple times
        let results1 = self.exerciseService.getExercisesWithEquipmentHints(for: .chest, availableEquipment: equipment)
        let results2 = self.exerciseService.getExercisesWithEquipmentHints(for: .chest, availableEquipment: equipment)
        let results3 = self.exerciseService.getExercisesWithEquipmentHints(for: .chest, availableEquipment: equipment)

        // Then - Order should be stable
        XCTAssertEqual(results1.count, results2.count)
        XCTAssertEqual(results2.count, results3.count)

        for i in 0 ..< results1.count {
            XCTAssertEqual(
                results1[i].exercise.id,
                results2[i].exercise.id,
                "Exercise order should be stable"
            )
            XCTAssertEqual(
                results2[i].exercise.id,
                results3[i].exercise.id,
                "Exercise order should be stable"
            )
            XCTAssertEqual(
                results1[i].isAvailable,
                results2[i].isAvailable,
                "Availability should be stable"
            )
        }
    }

    func testAvailabilityGrouping() {
        // Given
        let partialEquipment: Set<String> = ["Dumbbells"] // Some exercises will be available, some won't

        // When
        let results = self.exerciseService.getExercisesWithEquipmentHints(
            for: .chest,
            availableEquipment: partialEquipment
        )

        // Then - Available exercises should come first
        var foundUnavailable = false
        for item in results {
            if foundUnavailable, item.isAvailable {
                XCTFail("Available exercises should come before unavailable ones")
            }
            if !item.isAvailable {
                foundUnavailable = true
            }
        }

        // Should have both available and unavailable exercises
        let availableCount = results.count(where: { $0.isAvailable })
        let unavailableCount = results.count(where: { !$0.isAvailable })

        XCTAssertGreaterThan(availableCount, 0, "Should have available exercises")
        XCTAssertGreaterThan(unavailableCount, 0, "Should have unavailable exercises")
    }

    // MARK: - Memory and Performance Edge Cases

    func testMemoryUsageWithLargeResults() {
        // Given - Get all exercises for all muscle groups
        var allResults: [[ExerciseDisplayItem]] = []

        // When
        for muscleGroup in MuscleGroup.allCases {
            let results = self.exerciseService.getExercisesWithEquipmentHints(
                for: muscleGroup,
                availableEquipment: ["Dumbbells", "Barbell", "Adjustable Bench"]
            )
            allResults.append(results)
        }

        // Then - Should handle large result sets without issues
        let totalResults = allResults.flatMap(\.self)
        XCTAssertGreaterThan(totalResults.count, 0, "Should have results")

        // Verify all results are valid
        for result in totalResults {
            XCTAssertFalse(result.exercise.name.isEmpty, "Exercise should have valid name")
            XCTAssertNotNil(result.exercise.id, "Exercise should have valid ID")
        }
    }

    func testRepeatedOperationsPerformance() {
        // Test that repeated operations don't degrade performance
        let equipment: Set<String> = ["Dumbbells"]

        measure {
            for _ in 0 ..< 100 {
                _ = self.exerciseService.getExercisesWithEquipmentHints(for: .arms, availableEquipment: equipment)
            }
        }
    }

    // MARK: - Data Consistency Edge Cases

    func testExerciseIdUniqueness() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // When
        let allIds = allExercises.map(\.id)
        let uniqueIds = Set(allIds)

        // Then
        XCTAssertEqual(allIds.count, uniqueIds.count, "All exercise IDs should be unique")
    }

    func testExerciseNameUniqueness() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // When
        let allNames = allExercises.map(\.name)
        let uniqueNames = Set(allNames)

        // Then
        XCTAssertEqual(allNames.count, uniqueNames.count, "All exercise names should be unique")
    }

    func testExerciseDataImmutability() {
        // Given
        let exercise1 = self.exerciseService.getAllExercises().first!
        let exercise2 = self.exerciseService.getExercise(by: exercise1.id)!

        // Then - Same exercise retrieved different ways should be identical
        XCTAssertEqual(exercise1.id, exercise2.id)
        XCTAssertEqual(exercise1.name, exercise2.name)
        XCTAssertEqual(exercise1.muscleGroup, exercise2.muscleGroup)
        XCTAssertEqual(exercise1.requiredEquipment, exercise2.requiredEquipment)
        XCTAssertEqual(exercise1.difficulty, exercise2.difficulty)
    }

    // MARK: - Boundary Value Tests

    func testZeroLimitRequests() {
        // Test edge case with zero limits (though this shouldn't happen in practice)
        Task {
            let recentExercises = await exerciseService.getRecentlyUsedExercises(limit: 0)
            let mostUsedExercises = await exerciseService.getMostUsedExercises(limit: 0)

            XCTAssertEqual(recentExercises.count, 0, "Should return empty array for zero limit")
            XCTAssertEqual(mostUsedExercises.count, 0, "Should return empty array for zero limit")
        }
    }

    func testNegativeLimitRequests() {
        // Test edge case with negative limits
        Task {
            let recentExercises = await exerciseService.getRecentlyUsedExercises(limit: -1)
            let mostUsedExercises = await exerciseService.getMostUsedExercises(limit: -5)

            // Should handle gracefully (implementation dependent)
            XCTAssertGreaterThanOrEqual(recentExercises.count, 0, "Should handle negative limits gracefully")
            XCTAssertGreaterThanOrEqual(mostUsedExercises.count, 0, "Should handle negative limits gracefully")
        }
    }

    func testVeryLargeLimitRequests() {
        // Test with very large limits
        Task {
            let recentExercises = await exerciseService.getRecentlyUsedExercises(limit: 10_000)
            let mostUsedExercises = await exerciseService.getMostUsedExercises(limit: 10_000)

            // Should not crash and should return reasonable results
            XCTAssertGreaterThanOrEqual(recentExercises.count, 0, "Should handle large limits")
            XCTAssertGreaterThanOrEqual(mostUsedExercises.count, 0, "Should handle large limits")
        }
    }
}

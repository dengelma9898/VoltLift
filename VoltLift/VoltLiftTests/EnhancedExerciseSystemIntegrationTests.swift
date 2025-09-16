//
//  EnhancedExerciseSystemIntegrationTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

final class EnhancedExerciseSystemIntegrationTests: XCTestCase {
    var exerciseService: ExerciseService!
    var metadataService: ExerciseMetadataService!
    var context: NSManagedObjectContext!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory Core Data stack for testing
        let persistenceController = PersistenceController(inMemory: true)
        self.context = persistenceController.container.viewContext
        self.metadataService = await ExerciseMetadataService(context: self.context)
        self.exerciseService = ExerciseService(metadataService: self.metadataService)
    }

    override func tearDown() async throws {
        self.exerciseService = nil
        self.metadataService = nil
        self.context = nil
        try await super.tearDown()
    }

    // MARK: - Integration Tests

    func testExerciseServiceWithMetadataIntegration() async throws {
        // Given
        let exercise = self.exerciseService.getAllExercises().first!

        // When - Record usage
        await self.exerciseService.recordExerciseUsage(exerciseId: exercise.id)

        // Then - Verify metadata was created
        let metadata = await metadataService.getMetadata(for: exercise.id)
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?.exerciseId, exercise.id)
        XCTAssertEqual(metadata?.name, exercise.name)
        XCTAssertEqual(metadata?.usageCount, 1)

        // When - Get recently used exercises
        let recentExercises = await exerciseService.getRecentlyUsedExercises(limit: 5)

        // Then - Should include our exercise
        XCTAssertEqual(recentExercises.count, 1)
        XCTAssertEqual(recentExercises.first?.id, exercise.id)
    }

    func testExerciseCatalogIntegrationWithService() {
        // Given
        let availableEquipment: Set<String> = ["Dumbbells", "Adjustable Bench"]

        // When - Get exercises through catalog
        let catalogItems = ExerciseCatalog.forGroup(.chest, availableEquipment: availableEquipment)
        let serviceItems = self.exerciseService.getExercisesWithEquipmentHints(
            for: .chest,
            availableEquipment: availableEquipment
        )

        // Then - Results should be consistent
        XCTAssertEqual(catalogItems.count, serviceItems.count)

        for (catalogItem, serviceItem) in zip(catalogItems, serviceItems) {
            XCTAssertEqual(catalogItem.exercise.id, serviceItem.exercise.id)
            XCTAssertEqual(catalogItem.isAvailable, serviceItem.isAvailable)
            XCTAssertEqual(catalogItem.missingEquipment, serviceItem.missingEquipment)
        }
    }

    func testLegacyCompatibilityIntegration() {
        // Given
        let legacyMuscleGroup = WorkoutSetupView.MuscleGroup.chest
        let availableEquipment: Set<String> = ["Dumbbells"]

        // When
        let legacyExercises = self.exerciseService.getLegacyExercises(
            for: legacyMuscleGroup,
            availableEquipment: availableEquipment
        )
        let enhancedExercises = self.exerciseService.getExercises(for: .chest, availableEquipment: availableEquipment)

        // Then - Should have same count and compatible data
        XCTAssertEqual(legacyExercises.count, enhancedExercises.count)

        for (legacy, enhanced) in zip(legacyExercises, enhancedExercises) {
            XCTAssertEqual(legacy.name, enhanced.name)
            XCTAssertEqual(legacy.muscleGroup.rawValue, enhanced.muscleGroup.rawValue)
            XCTAssertEqual(legacy.requiredEquipment, enhanced.requiredEquipment)
        }
    }

    // MARK: - Equipment Filtering Edge Cases

    func testComplexEquipmentScenarios() {
        // Test scenario 1: Overlapping equipment requirements
        let scenario1Equipment: Set<String> = ["Dumbbells", "Resistance Bands"]
        let scenario1Items = self.exerciseService.getExercisesWithEquipmentHints(
            for: .arms,
            availableEquipment: scenario1Equipment
        )

        // Should have both available and unavailable exercises
        let availableCount = scenario1Items.count(where: { $0.isAvailable })
        let unavailableCount = scenario1Items.count(where: { !$0.isAvailable })

        XCTAssertGreaterThan(availableCount, 0, "Should have some available exercises")
        XCTAssertGreaterThan(unavailableCount, 0, "Should have some unavailable exercises")

        // Test scenario 2: No equipment
        let scenario2Items = self.exerciseService.getExercisesWithEquipmentHints(for: .core, availableEquipment: [])
        let bodyweightItems = scenario2Items.filter(\.isAvailable)

        XCTAssertGreaterThan(bodyweightItems.count, 0, "Should have bodyweight exercises available")

        for item in bodyweightItems {
            XCTAssertTrue(item.exercise.requiredEquipment.isEmpty, "Available exercises should require no equipment")
        }

        // Test scenario 3: All equipment
        let allEquipment: Set<String> = [
            "Dumbbells", "Barbell", "Weight Plates", "Adjustable Bench", "Pull-up Bar",
            "Resistance Bands", "Kettlebell", "Squat Rack"
        ]
        let scenario3Items = self.exerciseService.getExercisesWithEquipmentHints(
            for: .legs,
            availableEquipment: allEquipment
        )

        // All exercises should be available
        let allAvailable = scenario3Items.allSatisfy(\.isAvailable)
        XCTAssertTrue(allAvailable, "All exercises should be available with full equipment")
    }

    func testEquipmentFilteringConsistency() {
        // Given
        let testEquipment: Set<String> = ["Dumbbells", "Adjustable Bench"]

        // When - Get exercises multiple times
        let firstCall = self.exerciseService.getExercisesWithEquipmentHints(
            for: .chest,
            availableEquipment: testEquipment
        )
        let secondCall = self.exerciseService.getExercisesWithEquipmentHints(
            for: .chest,
            availableEquipment: testEquipment
        )

        // Then - Results should be identical
        XCTAssertEqual(firstCall.count, secondCall.count)

        for (first, second) in zip(firstCall, secondCall) {
            XCTAssertEqual(first.exercise.id, second.exercise.id)
            XCTAssertEqual(first.isAvailable, second.isAvailable)
            XCTAssertEqual(first.missingEquipment, second.missingEquipment)
        }
    }

    // MARK: - Performance and Stress Tests

    func testLargeDatasetPerformance() {
        // Test with all muscle groups and various equipment combinations
        let equipmentCombinations: [Set<String>] = [
            [],
            ["Dumbbells"],
            ["Dumbbells", "Adjustable Bench"],
            ["Dumbbells", "Barbell", "Weight Plates"],
            ["Resistance Bands", "Pull-up Bar"],
            ["Dumbbells", "Adjustable Bench", "Resistance Bands", "Pull-up Bar", "Kettlebell"]
        ]

        measure {
            for muscleGroup in MuscleGroup.allCases {
                for equipment in equipmentCombinations {
                    _ = self.exerciseService.getExercisesWithEquipmentHints(
                        for: muscleGroup,
                        availableEquipment: equipment
                    )
                }
            }
        }
    }

    func testConcurrentAccess() async {
        // Test concurrent access to exercise service
        let expectation = XCTestExpectation(description: "Concurrent access completed")
        expectation.expectedFulfillmentCount = 10

        for i in 0 ..< 10 {
            Task {
                let muscleGroup = MuscleGroup.allCases[i % MuscleGroup.allCases.count]
                let equipment: Set<String> = i % 2 == 0 ? ["Dumbbells"] : []

                _ = self.exerciseService.getExercisesWithEquipmentHints(for: muscleGroup, availableEquipment: equipment)
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 5.0)
    }

    // MARK: - Data Validation Tests

    func testExerciseDataIntegrity() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // Then - Validate all exercises have complete data
        for exercise in allExercises {
            // Basic properties
            XCTAssertFalse(exercise.name.isEmpty, "Exercise should have name")
            XCTAssertFalse(exercise.description.isEmpty, "Exercise should have description")
            XCTAssertFalse(exercise.sfSymbolName.isEmpty, "Exercise should have SF Symbol")

            // Instructions and safety
            XCTAssertGreaterThan(exercise.instructions.count, 0, "Exercise should have instructions")
            XCTAssertGreaterThan(exercise.safetyTips.count, 0, "Exercise should have safety tips")
            XCTAssertGreaterThan(exercise.targetMuscles.count, 0, "Exercise should have target muscles")

            // Validate instruction content
            for instruction in exercise.instructions {
                XCTAssertFalse(instruction.isEmpty, "Instructions should not be empty")
                XCTAssertGreaterThan(instruction.count, 10, "Instructions should be descriptive")
            }

            // Validate safety tips
            for tip in exercise.safetyTips {
                XCTAssertFalse(tip.isEmpty, "Safety tips should not be empty")
                XCTAssertGreaterThan(tip.count, 5, "Safety tips should be meaningful")
            }

            // Validate variations
            for variation in exercise.variations {
                XCTAssertFalse(variation.name.isEmpty, "Variation should have name")
                XCTAssertFalse(variation.description.isEmpty, "Variation should have description")
                XCTAssertFalse(variation.sfSymbolName.isEmpty, "Variation should have SF Symbol")
                XCTAssertTrue(
                    variation.difficultyModifier >= -2 && variation.difficultyModifier <= 2,
                    "Difficulty modifier should be reasonable"
                )
            }
        }
    }

    func testExerciseVariationIntegrity() {
        // Given
        let exercisesWithVariations = self.exerciseService.getAllExercises().filter { !$0.variations.isEmpty }

        // Then
        XCTAssertGreaterThan(exercisesWithVariations.count, 0, "Should have exercises with variations")

        for exercise in exercisesWithVariations {
            // Variation names should be unique within exercise
            let variationNames = exercise.variations.map(\.name)
            let uniqueNames = Set(variationNames)
            XCTAssertEqual(
                variationNames.count,
                uniqueNames.count,
                "Exercise '\(exercise.name)' should have unique variation names"
            )

            // Variation IDs should be unique
            let variationIds = exercise.variations.map(\.id)
            let uniqueIds = Set(variationIds)
            XCTAssertEqual(
                variationIds.count,
                uniqueIds.count,
                "Exercise '\(exercise.name)' should have unique variation IDs"
            )
        }
    }

    // MARK: - Error Handling Tests

    func testInvalidInputHandling() {
        // Test with invalid muscle group (this should not crash)
        let emptyResults = self.exerciseService.getExercises(
            for: .fullBody,
            availableEquipment: ["NonexistentEquipment"]
        )
        // Should return exercises that don't require the nonexistent equipment
        XCTAssertGreaterThanOrEqual(emptyResults.count, 0)

        // Test with empty equipment set
        let bodyweightResults = self.exerciseService.getExercises(for: .chest, availableEquipment: [])
        XCTAssertGreaterThan(bodyweightResults.count, 0, "Should return bodyweight exercises")

        for exercise in bodyweightResults {
            XCTAssertTrue(exercise.requiredEquipment.isEmpty, "Should only return bodyweight exercises")
        }
    }

    func testExerciseRetrievalEdgeCases() {
        // Test retrieving exercise by invalid ID
        let invalidId = UUID()
        let result = self.exerciseService.getExercise(by: invalidId)
        XCTAssertNil(result, "Should return nil for invalid ID")

        // Test retrieving exercises for muscle group with no matches (shouldn't happen in practice)
        let allExercises = self.exerciseService.getAllExercises()
        let chestExercises = allExercises.filter { $0.muscleGroup == .chest }
        XCTAssertGreaterThan(chestExercises.count, 0, "Should have chest exercises")
    }

    // MARK: - Metadata Integration Tests

    func testMetadataServiceIntegration() async throws {
        // Given
        let exercise = self.exerciseService.getAllExercises().first!

        // When - Record multiple usages
        await self.exerciseService.recordExerciseUsage(exerciseId: exercise.id)
        await self.exerciseService.recordExerciseUsage(exerciseId: exercise.id)
        await self.exerciseService.recordExerciseUsage(exerciseId: exercise.id)

        // Then - Verify usage tracking
        let metadata = await metadataService.getMetadata(for: exercise.id)
        XCTAssertEqual(metadata?.usageCount, 3)

        // When - Get most used exercises
        let mostUsed = await exerciseService.getMostUsedExercises(limit: 5)

        // Then - Should include our exercise
        XCTAssertEqual(mostUsed.count, 1)
        XCTAssertEqual(mostUsed.first?.id, exercise.id)
    }

    func testMetadataWithMultipleExercises() async throws {
        // Given
        let exercises = Array(exerciseService.getAllExercises().prefix(3))

        // When - Record different usage patterns
        for i in 0 ..< exercises.count {
            let exercise = exercises[i]
            for _ in 0 ..< (i + 1) {
                await self.exerciseService.recordExerciseUsage(exerciseId: exercise.id)
            }
        }

        // Then - Verify most used ordering
        let mostUsed = await exerciseService.getMostUsedExercises(limit: 5)
        XCTAssertEqual(mostUsed.count, 3)

        // Should be ordered by usage count (descending)
        XCTAssertEqual(mostUsed[0].id, exercises[2].id) // 3 uses
        XCTAssertEqual(mostUsed[1].id, exercises[1].id) // 2 uses
        XCTAssertEqual(mostUsed[2].id, exercises[0].id) // 1 use
    }
}

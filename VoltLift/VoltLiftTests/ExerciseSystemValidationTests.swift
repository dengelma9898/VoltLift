//
//  ExerciseSystemValidationTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

@testable import VoltLift
import XCTest

final class ExerciseSystemValidationTests: XCTestCase {
    var exerciseService: ExerciseService!

    override func setUp() {
        super.setUp()
        self.exerciseService = ExerciseService.shared
    }

    override func tearDown() {
        self.exerciseService = nil
        super.tearDown()
    }

    // MARK: - Data Validation Tests

    func testAllExercises_HaveValidSFSymbolNames() {
        // Test that all exercises have valid SF Symbol names
        let allExercises = self.exerciseService.getAllExercises()
        let validSFSymbolPatterns = [
            "figure.strengthtraining.traditional",
            "dumbbell",
            "figure.climbing",
            "bolt.horizontal.circle",
            "circle",
            "rectangle.portrait",
            "diamond"
        ]

        for exercise in allExercises {
            XCTAssertFalse(
                exercise.sfSymbolName.isEmpty,
                "Exercise '\(exercise.name)' should have SF Symbol name"
            )

            // Check if it's a known valid symbol or follows SF Symbol naming convention
            let isValidSymbol = validSFSymbolPatterns.contains(exercise.sfSymbolName) ||
                exercise.sfSymbolName.contains(".") ||
                exercise.sfSymbolName.allSatisfy(\.isLetter)

            XCTAssertTrue(
                isValidSymbol,
                "Exercise '\(exercise.name)' has potentially invalid SF Symbol: '\(exercise.sfSymbolName)'"
            )
        }
    }

    func testAllExercises_HaveReasonableInstructionLength() {
        // Test that all exercises have reasonable instruction lengths
        let allExercises = self.exerciseService.getAllExercises()

        for exercise in allExercises {
            XCTAssertGreaterThan(
                exercise.instructions.count,
                0,
                "Exercise '\(exercise.name)' should have at least one instruction"
            )
            XCTAssertLessThan(
                exercise.instructions.count,
                20,
                "Exercise '\(exercise.name)' should not have excessive instructions"
            )

            for instruction in exercise.instructions {
                XCTAssertGreaterThan(
                    instruction.count,
                    5,
                    "Instruction should be descriptive: '\(instruction)'"
                )
                XCTAssertLessThan(
                    instruction.count,
                    200,
                    "Instruction should be concise: '\(instruction)'"
                )
            }
        }
    }

    func testAllExercises_HaveValidTargetMuscles() {
        // Test that all exercises have valid target muscle specifications
        let allExercises = self.exerciseService.getAllExercises()
        let commonMuscles = [
            "Pectoralis Major", "Latissimus Dorsi", "Deltoid", "Biceps", "Triceps",
            "Quadriceps", "Hamstrings", "Gluteus Maximus", "Core", "Calves",
            "Rhomboids", "Trapezius", "Serratus Anterior", "Erector Spinae"
        ]

        for exercise in allExercises {
            XCTAssertGreaterThan(
                exercise.targetMuscles.count,
                0,
                "Exercise '\(exercise.name)' should have target muscles"
            )
            XCTAssertLessThan(
                exercise.targetMuscles.count,
                10,
                "Exercise '\(exercise.name)' should not target too many muscles"
            )

            for muscle in exercise.targetMuscles {
                XCTAssertFalse(
                    muscle.isEmpty,
                    "Target muscle should not be empty for '\(exercise.name)'"
                )
                XCTAssertGreaterThan(
                    muscle.count,
                    3,
                    "Target muscle name should be descriptive: '\(muscle)'"
                )
            }
        }
    }

    func testAllExercises_HaveConsistentDifficultyProgression() {
        // Test that exercises with variations have logical difficulty progression
        let allExercises = self.exerciseService.getAllExercises()
        let exercisesWithVariations = allExercises.filter { !$0.variations.isEmpty }

        for exercise in exercisesWithVariations {
            for variation in exercise.variations {
                XCTAssertTrue(
                    variation.difficultyModifier >= -2 && variation.difficultyModifier <= 2,
                    "Variation '\(variation.name)' has unreasonable difficulty modifier: \(variation.difficultyModifier)"
                )

                XCTAssertNotEqual(
                    variation.name,
                    exercise.name,
                    "Variation should have different name from parent exercise"
                )

                XCTAssertFalse(
                    variation.description.isEmpty,
                    "Variation '\(variation.name)' should have description"
                )
            }
        }
    }

    // MARK: - Equipment Validation Tests

    func testAllExercises_HaveValidEquipmentRequirements() {
        // Test that all equipment requirements are from a valid set
        let allExercises = self.exerciseService.getAllExercises()
        let validEquipment = Set([
            "Dumbbells", "Barbell", "Weight Plates", "Adjustable Bench", "Pull-up Bar",
            "Resistance Bands", "Kettlebell", "Cable Machine", "Smith Machine",
            "Leg Press Machine", "Lat Pulldown Machine", "Rowing Machine",
            "Preacher Bench", "Incline Bench", "Decline Bench", "Olympic Barbell",
            "EZ Curl Bar", "Trap Bar", "Medicine Ball", "Stability Ball",
            "Foam Roller", "Yoga Mat", "Suspension Trainer", "Battle Ropes",
            "Plyometric Box", "Agility Ladder", "Speed Rope", "Weighted Vest",
            "Squat Rack", "Cable Attachments"
        ])

        for exercise in allExercises {
            for equipment in exercise.requiredEquipment {
                XCTAssertTrue(
                    validEquipment.contains(equipment),
                    "Exercise '\(exercise.name)' requires invalid equipment: '\(equipment)'"
                )
            }
        }
    }

    func testBodyweightExercises_RequireNoEquipment() {
        // Test that bodyweight exercises truly require no equipment
        let bodyweightExercises = self.exerciseService.getBodyweightExercises()

        XCTAssertGreaterThan(bodyweightExercises.count, 0, "Should have bodyweight exercises")

        for exercise in bodyweightExercises {
            XCTAssertTrue(
                exercise.requiredEquipment.isEmpty,
                "Bodyweight exercise '\(exercise.name)' should require no equipment"
            )
        }
    }

    // MARK: - Muscle Group Coverage Tests

    func testMuscleGroupCoverage_IsComprehensive() {
        // Test that each muscle group has adequate exercise coverage
        let allExercises = self.exerciseService.getAllExercises()

        for muscleGroup in MuscleGroup.allCases {
            let exercisesForGroup = allExercises.filter { $0.muscleGroup == muscleGroup }

            XCTAssertGreaterThan(
                exercisesForGroup.count,
                0,
                "Muscle group '\(muscleGroup.rawValue)' should have exercises"
            )

            // Each muscle group should have at least one bodyweight option
            let bodyweightForGroup = exercisesForGroup.filter(\.requiredEquipment.isEmpty)
            if muscleGroup != .fullBody { // Full body exercises might require equipment
                XCTAssertGreaterThan(
                    bodyweightForGroup.count,
                    0,
                    "Muscle group '\(muscleGroup.rawValue)' should have bodyweight options"
                )
            }
        }
    }

    func testDifficultyLevelCoverage_IsBalanced() {
        // Test that each difficulty level has adequate coverage
        let allExercises = self.exerciseService.getAllExercises()

        for difficulty in DifficultyLevel.allCases {
            let exercisesForDifficulty = allExercises.filter { $0.difficulty == difficulty }

            XCTAssertGreaterThan(
                exercisesForDifficulty.count,
                0,
                "Difficulty level '\(difficulty.rawValue)' should have exercises"
            )

            // Beginner exercises should have more bodyweight options
            if difficulty == .beginner {
                let beginnerBodyweight = exercisesForDifficulty.filter(\.requiredEquipment.isEmpty)
                XCTAssertGreaterThan(
                    beginnerBodyweight.count,
                    0,
                    "Beginner difficulty should have bodyweight exercises"
                )
            }
        }
    }

    // MARK: - Data Consistency Tests

    func testExerciseIds_AreUnique() {
        // Test that all exercise IDs are unique
        let allExercises = self.exerciseService.getAllExercises()
        let exerciseIds = allExercises.map(\.id)
        let uniqueIds = Set(exerciseIds)

        XCTAssertEqual(
            exerciseIds.count,
            uniqueIds.count,
            "All exercise IDs should be unique"
        )
    }

    func testExerciseNames_AreUnique() {
        // Test that all exercise names are unique
        let allExercises = self.exerciseService.getAllExercises()
        let exerciseNames = allExercises.map(\.name)
        let uniqueNames = Set(exerciseNames)

        XCTAssertEqual(
            exerciseNames.count,
            uniqueNames.count,
            "All exercise names should be unique"
        )
    }

    func testExerciseVariationIds_AreUnique() {
        // Test that all variation IDs are unique across all exercises
        let allExercises = self.exerciseService.getAllExercises()
        var allVariationIds: [UUID] = []

        for exercise in allExercises {
            allVariationIds.append(contentsOf: exercise.variations.map(\.id))
        }

        let uniqueVariationIds = Set(allVariationIds)
        XCTAssertEqual(
            allVariationIds.count,
            uniqueVariationIds.count,
            "All variation IDs should be unique"
        )
    }

    // MARK: - Integration Validation Tests

    func testExerciseService_IntegratesCorrectlyWithCatalog() {
        // Test that ExerciseService correctly integrates with EnhancedExerciseCatalog
        let serviceExercises = self.exerciseService.getAllExercises()
        let catalogExercises = EnhancedExerciseCatalog.allExercises

        XCTAssertEqual(
            serviceExercises.count,
            catalogExercises.count,
            "Service should return same count as catalog"
        )

        let serviceIds = Set(serviceExercises.map(\.id))
        let catalogIds = Set(catalogExercises.map(\.id))

        XCTAssertEqual(
            serviceIds,
            catalogIds,
            "Service should return same exercises as catalog"
        )
    }

    func testExerciseDisplayItem_CalculatesAvailabilityCorrectly() {
        // Test that ExerciseDisplayItem correctly calculates equipment availability
        let allExercises = self.exerciseService.getAllExercises()
        let testEquipment: Set<String> = ["Dumbbells", "Adjustable Bench"]

        for exercise in allExercises {
            let displayItem = ExerciseDisplayItem(exercise: exercise, availableEquipment: testEquipment)

            let expectedAvailability = exercise.requiredEquipment.isSubset(of: testEquipment)
            XCTAssertEqual(
                displayItem.isAvailable,
                expectedAvailability,
                "Display item availability should match equipment requirements for '\(exercise.name)'"
            )

            let expectedMissing = exercise.requiredEquipment.subtracting(testEquipment)
            XCTAssertEqual(
                displayItem.missingEquipment,
                expectedMissing,
                "Missing equipment should be calculated correctly for '\(exercise.name)'"
            )
        }
    }

    // MARK: - Requirements Validation Tests

    func testRequirement1_1_AllExercisesDisplayedRegardlessOfEquipment() {
        // Test that all exercises are shown regardless of equipment availability
        let noEquipment: Set<String> = []
        let displayItems = self.exerciseService.getExercisesWithEquipmentHints(
            for: .chest,
            availableEquipment: noEquipment
        )

        XCTAssertGreaterThan(displayItems.count, 0, "Should show exercises even with no equipment")

        // Should have both available and unavailable exercises
        let availableItems = displayItems.filter(\.isAvailable)
        let unavailableItems = displayItems.filter { !$0.isAvailable }

        XCTAssertGreaterThan(availableItems.count, 0, "Should have available (bodyweight) exercises")
        XCTAssertGreaterThan(unavailableItems.count, 0, "Should have unavailable (equipment) exercises")
    }

    func testRequirement2_1_ExercisesHaveComprehensiveDescriptions() {
        // Test that exercises have detailed descriptions and guidance
        let allExercises = self.exerciseService.getAllExercises()

        for exercise in allExercises {
            XCTAssertFalse(
                exercise.description.isEmpty,
                "Exercise '\(exercise.name)' should have description"
            )
            XCTAssertGreaterThan(
                exercise.description.count,
                20,
                "Exercise '\(exercise.name)' should have detailed description"
            )

            XCTAssertGreaterThan(
                exercise.instructions.count,
                0,
                "Exercise '\(exercise.name)' should have instructions"
            )
            XCTAssertGreaterThan(
                exercise.safetyTips.count,
                0,
                "Exercise '\(exercise.name)' should have safety tips"
            )
            XCTAssertGreaterThan(
                exercise.targetMuscles.count,
                0,
                "Exercise '\(exercise.name)' should have target muscles"
            )
        }
    }

    func testRequirement3_1_ExpandedExerciseDatabase() {
        // Test that we have an expanded exercise database (40+ exercises)
        let allExercises = self.exerciseService.getAllExercises()

        XCTAssertGreaterThanOrEqual(
            allExercises.count,
            40,
            "Should have at least 40 exercises as per requirements"
        )

        // Should have exercises for all muscle groups
        for muscleGroup in MuscleGroup.allCases {
            let exercisesForGroup = allExercises.filter { $0.muscleGroup == muscleGroup }
            XCTAssertGreaterThan(
                exercisesForGroup.count,
                0,
                "Should have exercises for \(muscleGroup.rawValue)"
            )
        }
    }

    func testRequirement4_1_HealthKitCompatibility() {
        // Test that exercise data maintains HealthKit compatibility
        let allExercises = self.exerciseService.getAllExercises()

        for exercise in allExercises {
            // Verify exercise has all required properties for HealthKit integration
            XCTAssertFalse(exercise.name.isEmpty, "Exercise should have name for HealthKit")
            XCTAssertNotNil(exercise.muscleGroup, "Exercise should have muscle group for HealthKit")

            // Verify exercise can be converted to legacy format if needed
            let legacyExercise = exercise.legacyExercise
            XCTAssertEqual(
                legacyExercise.name,
                exercise.name,
                "Legacy conversion should preserve name"
            )
            XCTAssertEqual(
                legacyExercise.muscleGroup.rawValue,
                exercise.muscleGroup.rawValue,
                "Legacy conversion should preserve muscle group"
            )
        }
    }
}

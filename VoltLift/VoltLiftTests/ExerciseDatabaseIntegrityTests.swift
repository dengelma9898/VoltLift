//
//  ExerciseDatabaseIntegrityTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

@testable import VoltLift
import XCTest

final class ExerciseDatabaseIntegrityTests: XCTestCase {
    var exerciseService: ExerciseService!

    override func setUp() {
        super.setUp()
        self.exerciseService = ExerciseService.shared
    }

    override func tearDown() {
        self.exerciseService = nil
        super.tearDown()
    }

    // MARK: - Database Completeness Tests

    func testExerciseDatabase_HasMinimumRequiredExercises() {
        // Given
        let minimumExpectedCount = 40 // Based on requirements for 40+ exercises

        // When
        let allExercises = self.exerciseService.getAllExercises()

        // Then
        XCTAssertGreaterThanOrEqual(
            allExercises.count,
            minimumExpectedCount,
            "Database should contain at least \(minimumExpectedCount) exercises"
        )
    }

    func testExerciseDatabase_HasExercisesForAllMuscleGroups() {
        // Given
        let allMuscleGroups = MuscleGroup.allCases
        let allExercises = self.exerciseService.getAllExercises()

        // When
        let representedMuscleGroups = Set(allExercises.map(\.muscleGroup))

        // Then
        for muscleGroup in allMuscleGroups {
            XCTAssertTrue(
                representedMuscleGroups.contains(muscleGroup),
                "Database should contain exercises for \(muscleGroup.rawValue)"
            )
        }
    }

    func testExerciseDatabase_HasBodyweightExercisesForAllMuscleGroups() {
        // Given
        let primaryMuscleGroups: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .legs, .core]

        // When
        let bodyweightExercises = self.exerciseService.getBodyweightExercises()
        let bodyweightMuscleGroups = Set(bodyweightExercises.map(\.muscleGroup))

        // Then
        for muscleGroup in primaryMuscleGroups {
            XCTAssertTrue(
                bodyweightMuscleGroups.contains(muscleGroup),
                "Database should contain bodyweight exercises for \(muscleGroup.rawValue)"
            )
        }
    }

    func testExerciseDatabase_HasExercisesForAllDifficultyLevels() {
        // Given
        let allDifficultyLevels = DifficultyLevel.allCases
        let allExercises = self.exerciseService.getAllExercises()

        // When
        let representedDifficulties = Set(allExercises.map(\.difficulty))

        // Then
        for difficulty in allDifficultyLevels {
            XCTAssertTrue(
                representedDifficulties.contains(difficulty),
                "Database should contain exercises for \(difficulty.rawValue) level"
            )
        }
    }

    // MARK: - Exercise Data Integrity Tests

    func testAllExercises_HaveUniqueIds() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // When
        let exerciseIds = allExercises.map(\.id)
        let uniqueIds = Set(exerciseIds)

        // Then
        XCTAssertEqual(
            exerciseIds.count,
            uniqueIds.count,
            "All exercises should have unique IDs"
        )
    }

    func testAllExercises_HaveUniqueNames() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // When
        let exerciseNames = allExercises.map(\.name)
        let uniqueNames = Set(exerciseNames)

        // Then
        XCTAssertEqual(
            exerciseNames.count,
            uniqueNames.count,
            "All exercises should have unique names"
        )
    }

    func testAllExercises_HaveRequiredProperties() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // Then
        for exercise in allExercises {
            XCTAssertFalse(
                exercise.name.isEmpty,
                "Exercise '\(exercise.name)' should have non-empty name"
            )
            XCTAssertFalse(
                exercise.description.isEmpty,
                "Exercise '\(exercise.name)' should have non-empty description"
            )
            XCTAssertFalse(
                exercise.instructions.isEmpty,
                "Exercise '\(exercise.name)' should have instructions"
            )
            XCTAssertFalse(
                exercise.safetyTips.isEmpty,
                "Exercise '\(exercise.name)' should have safety tips"
            )
            XCTAssertFalse(
                exercise.targetMuscles.isEmpty,
                "Exercise '\(exercise.name)' should have target muscles"
            )
            XCTAssertFalse(
                exercise.sfSymbolName.isEmpty,
                "Exercise '\(exercise.name)' should have SF Symbol name"
            )
        }
    }

    func testAllExercises_HaveValidInstructions() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // Then
        for exercise in allExercises {
            XCTAssertGreaterThan(
                exercise.instructions.count,
                0,
                "Exercise '\(exercise.name)' should have at least one instruction"
            )

            for instruction in exercise.instructions {
                XCTAssertFalse(
                    instruction.isEmpty,
                    "Exercise '\(exercise.name)' should not have empty instructions"
                )
            }
        }
    }

    func testAllExercises_HaveValidSafetyTips() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // Then
        for exercise in allExercises {
            XCTAssertGreaterThan(
                exercise.safetyTips.count,
                0,
                "Exercise '\(exercise.name)' should have at least one safety tip"
            )

            for safetyTip in exercise.safetyTips {
                XCTAssertFalse(
                    safetyTip.isEmpty,
                    "Exercise '\(exercise.name)' should not have empty safety tips"
                )
            }
        }
    }

    func testAllExercises_HaveValidTargetMuscles() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // Then
        for exercise in allExercises {
            XCTAssertGreaterThan(
                exercise.targetMuscles.count,
                0,
                "Exercise '\(exercise.name)' should have at least one target muscle"
            )

            for muscle in exercise.targetMuscles {
                XCTAssertFalse(
                    muscle.isEmpty,
                    "Exercise '\(exercise.name)' should not have empty target muscles"
                )
            }
        }
    }

    // MARK: - Equipment Validation Tests

    func testAllExercises_HaveValidEquipmentRequirements() {
        // Given
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

        // Then
        for exercise in allExercises {
            for equipment in exercise.requiredEquipment {
                XCTAssertFalse(
                    equipment.isEmpty,
                    "Exercise '\(exercise.name)' should not have empty equipment requirements"
                )
                XCTAssertTrue(
                    validEquipment.contains(equipment),
                    "Exercise '\(exercise.name)' has invalid equipment: '\(equipment)'"
                )
            }
        }
    }

    func testBodyweightExercises_RequireNoEquipment() {
        // Given
        let bodyweightExercises = self.exerciseService.getBodyweightExercises()

        // Then
        for exercise in bodyweightExercises {
            XCTAssertTrue(
                exercise.requiredEquipment.isEmpty,
                "Bodyweight exercise '\(exercise.name)' should require no equipment"
            )
        }
    }

    // MARK: - Exercise Variations Tests

    func testExerciseVariations_HaveValidProperties() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // Then
        for exercise in allExercises {
            for variation in exercise.variations {
                XCTAssertFalse(
                    variation.name.isEmpty,
                    "Variation for '\(exercise.name)' should have non-empty name"
                )
                XCTAssertFalse(
                    variation.description.isEmpty,
                    "Variation for '\(exercise.name)' should have non-empty description"
                )
                XCTAssertFalse(
                    variation.sfSymbolName.isEmpty,
                    "Variation for '\(exercise.name)' should have SF Symbol name"
                )
                XCTAssertTrue(
                    variation.difficultyModifier >= -2 && variation.difficultyModifier <= 2,
                    "Variation difficulty modifier should be between -2 and 2"
                )
            }
        }
    }

    func testExerciseVariations_HaveUniqueNames() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // Then
        for exercise in allExercises {
            let variationNames = exercise.variations.map(\.name)
            let uniqueNames = Set(variationNames)

            XCTAssertEqual(
                variationNames.count,
                uniqueNames.count,
                "Exercise '\(exercise.name)' should have unique variation names"
            )
        }
    }

    // MARK: - SF Symbol Validation Tests

    func testAllExercises_HaveValidSFSymbolNames() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()
        let commonSFSymbols = Set([
            "figure.strengthtraining.traditional", "dumbbell", "figure.climbing",
            "bolt.horizontal.circle", "circle", "rectangle.portrait", "diamond",
            "figure.walk", "figure.run", "heart.fill", "lungs.fill"
        ])

        // Then
        for exercise in allExercises {
            XCTAssertFalse(
                exercise.sfSymbolName.isEmpty,
                "Exercise '\(exercise.name)' should have SF Symbol name"
            )

            // Check if it's a common symbol or follows SF Symbol naming convention
            let isCommonSymbol = commonSFSymbols.contains(exercise.sfSymbolName)
            let followsNamingConvention = exercise.sfSymbolName.contains(".") ||
                exercise.sfSymbolName.allSatisfy { $0.isLetter || $0 == "." }

            XCTAssertTrue(
                isCommonSymbol || followsNamingConvention,
                "Exercise '\(exercise.name)' has invalid SF Symbol: '\(exercise.sfSymbolName)'"
            )
        }
    }

    // MARK: - Muscle Group Distribution Tests

    func testExerciseDistribution_IsBalancedAcrossMuscleGroups() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()
        let primaryMuscleGroups: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .legs, .core]

        // When
        var muscleGroupCounts: [MuscleGroup: Int] = [:]
        for exercise in allExercises {
            muscleGroupCounts[exercise.muscleGroup, default: 0] += 1
        }

        // Then
        for muscleGroup in primaryMuscleGroups {
            let count = muscleGroupCounts[muscleGroup] ?? 0
            XCTAssertGreaterThanOrEqual(
                count,
                3,
                "Should have at least 3 exercises for \(muscleGroup.rawValue)"
            )
        }
    }

    func testDifficultyDistribution_HasBeginnerFriendlyOptions() {
        // Given
        let allExercises = self.exerciseService.getAllExercises()

        // When
        let beginnerExercises = allExercises.filter { $0.difficulty == .beginner }
        let beginnerMuscleGroups = Set(beginnerExercises.map(\.muscleGroup))

        // Then
        let primaryMuscleGroups: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .legs, .core]
        for muscleGroup in primaryMuscleGroups {
            XCTAssertTrue(
                beginnerMuscleGroups.contains(muscleGroup),
                "Should have beginner exercises for \(muscleGroup.rawValue)"
            )
        }
    }

    // MARK: - Performance Tests

    func testExerciseRetrieval_PerformanceIsAcceptable() {
        // Given
        let iterations = 1_000

        // When & Then
        measure {
            for _ in 0 ..< iterations {
                _ = self.exerciseService.getAllExercises()
            }
        }
    }

    func testExerciseFiltering_PerformanceIsAcceptable() {
        // Given
        let iterations = 100
        let availableEquipment: Set<String> = ["Dumbbells", "Adjustable Bench"]

        // When & Then
        measure {
            for _ in 0 ..< iterations {
                for muscleGroup in MuscleGroup.allCases {
                    _ = self.exerciseService.getExercises(for: muscleGroup, availableEquipment: availableEquipment)
                }
            }
        }
    }

    // MARK: - Consistency Tests

    func testExerciseDatabase_IsConsistentAcrossMultipleCalls() {
        // Given
        let firstCall = self.exerciseService.getAllExercises()

        // When
        let secondCall = self.exerciseService.getAllExercises()
        let thirdCall = self.exerciseService.getAllExercises()

        // Then
        XCTAssertEqual(firstCall.count, secondCall.count)
        XCTAssertEqual(secondCall.count, thirdCall.count)

        let firstIds = Set(firstCall.map(\.id))
        let secondIds = Set(secondCall.map(\.id))
        let thirdIds = Set(thirdCall.map(\.id))

        XCTAssertEqual(firstIds, secondIds)
        XCTAssertEqual(secondIds, thirdIds)
    }
}

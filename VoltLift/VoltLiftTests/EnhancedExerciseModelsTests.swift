@testable import VoltLift
import XCTest

final class EnhancedExerciseModelsTests: XCTestCase {
    // MARK: - SetType Tests

    func testSetTypeDisplayNames() {
        XCTAssertEqual(SetType.warmUp.displayName, "Warm-up")
        XCTAssertEqual(SetType.normal.displayName, "Working Set")
        XCTAssertEqual(SetType.coolDown.displayName, "Cool-down")
    }

    func testSetTypeIcons() {
        XCTAssertEqual(SetType.warmUp.icon, "thermometer.low")
        XCTAssertEqual(SetType.normal.icon, "dumbbell.fill")
        XCTAssertEqual(SetType.coolDown.icon, "leaf.fill")
    }

    func testSetTypeDescriptions() {
        XCTAssertEqual(SetType.warmUp.description, "Preparation set with lighter weight")
        XCTAssertEqual(SetType.normal.description, "Main working set at target intensity")
        XCTAssertEqual(SetType.coolDown.description, "Recovery set with reduced intensity")
    }

    func testSetTypeCodable() throws {
        let warmUp = SetType.warmUp
        let encoded = try JSONEncoder().encode(warmUp)
        let decoded = try JSONDecoder().decode(SetType.self, from: encoded)
        XCTAssertEqual(warmUp, decoded)
    }

    func testSetTypeRawValues() {
        XCTAssertEqual(SetType.warmUp.rawValue, "warm_up")
        XCTAssertEqual(SetType.normal.rawValue, "normal")
        XCTAssertEqual(SetType.coolDown.rawValue, "cool_down")
    }

    func testSetTypeCaseIterable() {
        let allCases = SetType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.warmUp))
        XCTAssertTrue(allCases.contains(.normal))
        XCTAssertTrue(allCases.contains(.coolDown))
    }

    // MARK: - ExerciseSet Tests

    func testExerciseSetDefaultInitialization() {
        let set = ExerciseSet(setNumber: 1)

        XCTAssertEqual(set.setNumber, 1)
        XCTAssertEqual(set.reps, 10)
        XCTAssertEqual(set.weight, 0.0)
        XCTAssertEqual(set.setType, .normal)
        XCTAssertFalse(set.isCompleted)
        XCTAssertNil(set.completedAt)
        XCTAssertNotNil(set.id)
    }

    func testExerciseSetCustomInitialization() {
        let set = ExerciseSet(setNumber: 2, reps: 12, weight: 50.0, setType: .warmUp)

        XCTAssertEqual(set.setNumber, 2)
        XCTAssertEqual(set.reps, 12)
        XCTAssertEqual(set.weight, 50.0)
        XCTAssertEqual(set.setType, .warmUp)
        XCTAssertFalse(set.isCompleted)
        XCTAssertNil(set.completedAt)
    }

    func testExerciseSetCompletedInitialization() {
        let completionDate = Date()
        let set = ExerciseSet(setNumber: 1, reps: 10, weight: 100.0, setType: .normal, completedAt: completionDate)

        XCTAssertEqual(set.setNumber, 1)
        XCTAssertEqual(set.reps, 10)
        XCTAssertEqual(set.weight, 100.0)
        XCTAssertEqual(set.setType, .normal)
        XCTAssertTrue(set.isCompleted)
        XCTAssertEqual(set.completedAt, completionDate)
    }

    func testExerciseSetWithCompletion() {
        let originalSet = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal)
        let completionDate = Date()

        let completedSet = originalSet.withCompletion(isCompleted: true, completedAt: completionDate)

        XCTAssertEqual(completedSet.id, originalSet.id)
        XCTAssertEqual(completedSet.setNumber, originalSet.setNumber)
        XCTAssertEqual(completedSet.reps, originalSet.reps)
        XCTAssertEqual(completedSet.weight, originalSet.weight)
        XCTAssertEqual(completedSet.setType, originalSet.setType)
        XCTAssertTrue(completedSet.isCompleted)
        XCTAssertEqual(completedSet.completedAt, completionDate)
    }

    func testExerciseSetWithCompletionDefaultDate() {
        let originalSet = ExerciseSet(setNumber: 1)
        let completedSet = originalSet.withCompletion(isCompleted: true)

        XCTAssertTrue(completedSet.isCompleted)
        XCTAssertNotNil(completedSet.completedAt)
        XCTAssertTrue(abs(completedSet.completedAt!.timeIntervalSinceNow) < 1.0) // Within 1 second
    }

    func testExerciseSetWithCompletionFalse() {
        let completedSet = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal, completedAt: Date())
        let uncompletedSet = completedSet.withCompletion(isCompleted: false)

        XCTAssertFalse(uncompletedSet.isCompleted)
        XCTAssertNil(uncompletedSet.completedAt)
    }

    func testExerciseSetWithUpdatedParameters() {
        let originalSet = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal)

        let updatedSet = originalSet.withUpdatedParameters(reps: 12, weight: 60.0, setType: .warmUp)

        XCTAssertEqual(updatedSet.id, originalSet.id)
        XCTAssertEqual(updatedSet.setNumber, originalSet.setNumber)
        XCTAssertEqual(updatedSet.reps, 12)
        XCTAssertEqual(updatedSet.weight, 60.0)
        XCTAssertEqual(updatedSet.setType, .warmUp)
        XCTAssertEqual(updatedSet.isCompleted, originalSet.isCompleted)
        XCTAssertEqual(updatedSet.completedAt, originalSet.completedAt)
    }

    func testExerciseSetWithPartialUpdatedParameters() {
        let originalSet = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal)

        let updatedSet = originalSet.withUpdatedParameters(reps: 15)

        XCTAssertEqual(updatedSet.reps, 15)
        XCTAssertEqual(updatedSet.weight, originalSet.weight)
        XCTAssertEqual(updatedSet.setType, originalSet.setType)
    }

    func testExerciseSetEquality() {
        let set1 = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal)
        let set2 = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal)

        // Different IDs should make them unequal
        XCTAssertNotEqual(set1, set2)

        // Same set should be equal to itself
        XCTAssertEqual(set1, set1)
    }

    func testExerciseSetCodable() throws {
        let originalSet = ExerciseSet(setNumber: 1, reps: 12, weight: 75.5, setType: .warmUp)

        let encoded = try JSONEncoder().encode(originalSet)
        let decodedSet = try JSONDecoder().decode(ExerciseSet.self, from: encoded)

        XCTAssertEqual(decodedSet.id, originalSet.id)
        XCTAssertEqual(decodedSet.setNumber, originalSet.setNumber)
        XCTAssertEqual(decodedSet.reps, originalSet.reps)
        XCTAssertEqual(decodedSet.weight, originalSet.weight)
        XCTAssertEqual(decodedSet.setType, originalSet.setType)
        XCTAssertEqual(decodedSet.isCompleted, originalSet.isCompleted)
        XCTAssertEqual(decodedSet.completedAt, originalSet.completedAt)
    }

    // MARK: - ExerciseData Tests

    func testExerciseDataWithSetsInitialization() {
        let sets = [
            ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .warmUp),
            ExerciseSet(setNumber: 2, reps: 12, weight: 60.0, setType: .normal),
            ExerciseSet(setNumber: 3, reps: 8, weight: 55.0, setType: .coolDown)
        ]

        let exercise = ExerciseData(name: "Bench Press", sets: sets, restTime: 90)

        XCTAssertEqual(exercise.name, "Bench Press")
        XCTAssertEqual(exercise.sets.count, 3)
        XCTAssertEqual(exercise.restTime, 90)
        XCTAssertEqual(exercise.orderIndex, 0)
        XCTAssertNotNil(exercise.id)
    }

    func testExerciseDataBackwardCompatibilityInitialization() {
        let exercise = ExerciseData(name: "Squat", sets: 3, reps: 10, weight: 100.0, restTime: 120, orderIndex: 1)

        XCTAssertEqual(exercise.name, "Squat")
        XCTAssertEqual(exercise.sets.count, 3)
        XCTAssertEqual(exercise.restTime, 120)
        XCTAssertEqual(exercise.orderIndex, 1)

        // Check that all sets are created correctly
        for (index, set) in exercise.sets.enumerated() {
            XCTAssertEqual(set.setNumber, index + 1)
            XCTAssertEqual(set.reps, 10)
            XCTAssertEqual(set.weight, 100.0)
            XCTAssertEqual(set.setType, .normal)
            XCTAssertFalse(set.isCompleted)
        }
    }

    func testExerciseDataComputedProperties() {
        let sets = [
            ExerciseSet(setNumber: 1, reps: 8, weight: 50.0, setType: .warmUp),
            ExerciseSet(setNumber: 2, reps: 10, weight: 60.0, setType: .normal),
            ExerciseSet(setNumber: 3, reps: 12, weight: 70.0, setType: .normal),
            ExerciseSet(setNumber: 4, reps: 6, weight: 40.0, setType: .coolDown)
        ]

        let exercise = ExerciseData(name: "Test Exercise", sets: sets, restTime: 60)

        XCTAssertEqual(exercise.totalSets, 4)
        XCTAssertEqual(exercise.averageReps, 9) // (8 + 10 + 12 + 6) / 4 = 9
        XCTAssertEqual(exercise.averageWeight, 55.0) // (50 + 60 + 70 + 40) / 4 = 55
        XCTAssertEqual(exercise.completedSets, 0)
        XCTAssertEqual(exercise.progressPercentage, 0.0)
        XCTAssertFalse(exercise.isCompleted)
    }

    func testExerciseDataProgressTracking() {
        let completedSet1 = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal, completedAt: Date())
        let completedSet2 = ExerciseSet(setNumber: 2, reps: 10, weight: 50.0, setType: .normal, completedAt: Date())
        let incompleteSet = ExerciseSet(setNumber: 3, reps: 10, weight: 50.0, setType: .normal)

        let exercise = ExerciseData(
            name: "Test Exercise",
            sets: [completedSet1, completedSet2, incompleteSet],
            restTime: 60
        )

        XCTAssertEqual(exercise.completedSets, 2)
        XCTAssertEqual(exercise.progressPercentage, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertFalse(exercise.isCompleted)
    }

    func testExerciseDataFullyCompleted() {
        let completedSet1 = ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal, completedAt: Date())
        let completedSet2 = ExerciseSet(setNumber: 2, reps: 10, weight: 50.0, setType: .normal, completedAt: Date())

        let exercise = ExerciseData(name: "Test Exercise", sets: [completedSet1, completedSet2], restTime: 60)

        XCTAssertEqual(exercise.completedSets, 2)
        XCTAssertEqual(exercise.progressPercentage, 1.0)
        XCTAssertTrue(exercise.isCompleted)
    }

    func testExerciseDataEmptySetsComputedProperties() {
        let exercise = ExerciseData(name: "Empty Exercise", sets: [], restTime: 60)

        XCTAssertEqual(exercise.totalSets, 0)
        XCTAssertEqual(exercise.averageReps, 0)
        XCTAssertEqual(exercise.averageWeight, 0.0)
        XCTAssertEqual(exercise.completedSets, 0)
        XCTAssertEqual(exercise.progressPercentage, 0.0)
        XCTAssertFalse(exercise.isCompleted)
    }

    func testExerciseDataWithUpdatedSets() {
        let originalSets = [
            ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal)
        ]
        let exercise = ExerciseData(name: "Test Exercise", sets: originalSets, restTime: 60)

        let newSets = [
            ExerciseSet(setNumber: 1, reps: 12, weight: 60.0, setType: .warmUp),
            ExerciseSet(setNumber: 2, reps: 10, weight: 70.0, setType: .normal)
        ]

        let updatedExercise = exercise.withUpdatedSets(newSets)

        XCTAssertEqual(updatedExercise.id, exercise.id)
        XCTAssertEqual(updatedExercise.name, exercise.name)
        XCTAssertEqual(updatedExercise.restTime, exercise.restTime)
        XCTAssertEqual(updatedExercise.orderIndex, exercise.orderIndex)
        XCTAssertEqual(updatedExercise.sets.count, 2)
        XCTAssertEqual(updatedExercise.sets[0].reps, 12)
        XCTAssertEqual(updatedExercise.sets[1].weight, 70.0)
    }

    func testExerciseDataSetsByType() {
        let sets = [
            ExerciseSet(setNumber: 1, reps: 8, weight: 40.0, setType: .warmUp),
            ExerciseSet(setNumber: 2, reps: 10, weight: 60.0, setType: .normal),
            ExerciseSet(setNumber: 3, reps: 12, weight: 65.0, setType: .normal),
            ExerciseSet(setNumber: 4, reps: 6, weight: 30.0, setType: .coolDown)
        ]

        let exercise = ExerciseData(name: "Test Exercise", sets: sets, restTime: 60)
        let setsByType = exercise.setsByType

        XCTAssertEqual(setsByType[.warmUp]?.count, 1)
        XCTAssertEqual(setsByType[.normal]?.count, 2)
        XCTAssertEqual(setsByType[.coolDown]?.count, 1)

        XCTAssertEqual(setsByType[.warmUp]?.first?.reps, 8)
        XCTAssertEqual(setsByType[.normal]?.first?.reps, 10)
        XCTAssertEqual(setsByType[.coolDown]?.first?.reps, 6)
    }

    func testExerciseDataSetsInExecutionOrder() {
        let sets = [
            ExerciseSet(setNumber: 3, reps: 12, weight: 65.0, setType: .normal),
            ExerciseSet(setNumber: 1, reps: 8, weight: 40.0, setType: .warmUp),
            ExerciseSet(setNumber: 4, reps: 6, weight: 30.0, setType: .coolDown),
            ExerciseSet(setNumber: 2, reps: 10, weight: 60.0, setType: .normal)
        ]

        let exercise = ExerciseData(name: "Test Exercise", sets: sets, restTime: 60)
        let orderedSets = exercise.setsInExecutionOrder

        XCTAssertEqual(orderedSets.count, 4)

        // Should be: warmUp (1), normal (2, 3), coolDown (4)
        XCTAssertEqual(orderedSets[0].setType, .warmUp)
        XCTAssertEqual(orderedSets[0].setNumber, 1)

        XCTAssertEqual(orderedSets[1].setType, .normal)
        XCTAssertEqual(orderedSets[1].setNumber, 2)

        XCTAssertEqual(orderedSets[2].setType, .normal)
        XCTAssertEqual(orderedSets[2].setNumber, 3)

        XCTAssertEqual(orderedSets[3].setType, .coolDown)
        XCTAssertEqual(orderedSets[3].setNumber, 4)
    }

    func testExerciseDataCodable() throws {
        let sets = [
            ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .warmUp),
            ExerciseSet(setNumber: 2, reps: 12, weight: 60.0, setType: .normal)
        ]

        let originalExercise = ExerciseData(name: "Bench Press", sets: sets, restTime: 90, orderIndex: 1)

        let encoded = try JSONEncoder().encode(originalExercise)
        let decodedExercise = try JSONDecoder().decode(ExerciseData.self, from: encoded)

        XCTAssertEqual(decodedExercise.id, originalExercise.id)
        XCTAssertEqual(decodedExercise.name, originalExercise.name)
        XCTAssertEqual(decodedExercise.sets.count, originalExercise.sets.count)
        XCTAssertEqual(decodedExercise.restTime, originalExercise.restTime)
        XCTAssertEqual(decodedExercise.orderIndex, originalExercise.orderIndex)

        for (original, decoded) in zip(originalExercise.sets, decodedExercise.sets) {
            XCTAssertEqual(decoded.id, original.id)
            XCTAssertEqual(decoded.setNumber, original.setNumber)
            XCTAssertEqual(decoded.reps, original.reps)
            XCTAssertEqual(decoded.weight, original.weight)
            XCTAssertEqual(decoded.setType, original.setType)
            XCTAssertEqual(decoded.isCompleted, original.isCompleted)
            XCTAssertEqual(decoded.completedAt, original.completedAt)
        }
    }

    func testExerciseDataEquality() {
        let sets1 = [ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal)]
        let sets2 = [ExerciseSet(setNumber: 1, reps: 10, weight: 50.0, setType: .normal)]

        let exercise1 = ExerciseData(name: "Test", sets: sets1, restTime: 60)
        let exercise2 = ExerciseData(name: "Test", sets: sets2, restTime: 60)

        // Different IDs should make them unequal
        XCTAssertNotEqual(exercise1, exercise2)

        // Same exercise should be equal to itself
        XCTAssertEqual(exercise1, exercise1)
    }
}

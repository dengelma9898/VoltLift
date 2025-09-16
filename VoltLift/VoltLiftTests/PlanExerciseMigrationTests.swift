//
//  PlanExerciseMigrationTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 16.9.2025.
//

import XCTest
import CoreData
@testable import VoltLift

/// Tests for PlanExercise migration from legacy format to new set-based format
final class PlanExerciseMigrationTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDown() {
        context = nil
        persistenceController = nil
        super.tearDown()
    }
    
    // MARK: - Migration Tests
    
    func testMigrateSinglePlanExerciseFromLegacyFormat() throws {
        // Given: A PlanExercise with legacy format data
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Push-up"
        exercise.sets = 3
        exercise.reps = 12
        exercise.weight = 0.0
        exercise.restTime = 60
        exercise.orderIndex = 0
        exercise.setsData = nil // No new format data
        
        try context.save()
        
        // When: Migration is performed
        try persistenceController.migratePlanExerciseData()
        
        // Then: Exercise should have setsData populated
        XCTAssertNotNil(exercise.setsData, "setsData should be populated after migration")
        XCTAssertEqual(exercise.totalSets, 3, "totalSets should be updated")
        XCTAssertEqual(exercise.averageWeight, 0.0, "averageWeight should be updated")
        
        // Verify the sets data is correct
        let setsData = try XCTUnwrap(exercise.setsData)
        let sets = try JSONDecoder().decode([ExerciseSet].self, from: setsData)
        
        XCTAssertEqual(sets.count, 3, "Should have 3 sets")
        
        for (index, set) in sets.enumerated() {
            XCTAssertEqual(set.setNumber, index + 1, "Set number should be sequential")
            XCTAssertEqual(set.reps, 12, "Reps should match legacy value")
            XCTAssertEqual(set.weight, 0.0, "Weight should match legacy value")
            XCTAssertEqual(set.setType, .normal, "Set type should default to normal")
            XCTAssertFalse(set.isCompleted, "Set should not be completed initially")
            XCTAssertNil(set.completedAt, "Completion date should be nil")
        }
    }
    
    func testMigrationSkipsAlreadyMigratedExercises() throws {
        // Given: A PlanExercise that already has setsData
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Squat"
        exercise.sets = 4
        exercise.reps = 10
        exercise.weight = 100.0
        exercise.restTime = 90
        exercise.orderIndex = 1
        
        // Pre-populate with setsData
        let existingSets = [
            ExerciseSet(setNumber: 1, reps: 8, weight: 80.0, setType: .warmUp),
            ExerciseSet(setNumber: 2, reps: 10, weight: 100.0, setType: .normal),
            ExerciseSet(setNumber: 3, reps: 10, weight: 100.0, setType: .normal),
            ExerciseSet(setNumber: 4, reps: 12, weight: 90.0, setType: .coolDown)
        ]
        exercise.setsData = try JSONEncoder().encode(existingSets)
        exercise.totalSets = 4
        exercise.averageWeight = 92.5
        
        try context.save()
        
        // When: Migration is performed
        try persistenceController.migratePlanExerciseData()
        
        // Then: Exercise data should remain unchanged
        let setsData = try XCTUnwrap(exercise.setsData)
        let sets = try JSONDecoder().decode([ExerciseSet].self, from: setsData)
        
        XCTAssertEqual(sets.count, 4, "Should still have 4 sets")
        XCTAssertEqual(sets[0].setType, .warmUp, "First set should still be warm-up")
        XCTAssertEqual(sets[0].weight, 80.0, "First set weight should be unchanged")
        XCTAssertEqual(sets[3].setType, .coolDown, "Last set should still be cool-down")
    }
    
    func testMigrationHandlesMultipleExercises() throws {
        // Given: Multiple PlanExercises with legacy format
        let exercises = [
            ("Push-up", 3, 12, 0.0),
            ("Squat", 4, 10, 100.0),
            ("Bench Press", 5, 8, 80.0)
        ]
        
        for (index, (name, sets, reps, weight)) in exercises.enumerated() {
            let exercise = PlanExercise(context: context)
            exercise.exerciseId = UUID()
            exercise.name = name
            exercise.sets = Int32(sets)
            exercise.reps = Int32(reps)
            exercise.weight = weight
            exercise.restTime = 60
            exercise.orderIndex = Int32(index)
            exercise.setsData = nil
        }
        
        try context.save()
        
        // When: Migration is performed
        try persistenceController.migratePlanExerciseData()
        
        // Then: All exercises should be migrated
        let request: NSFetchRequest<PlanExercise> = PlanExercise.fetchRequest()
        let migratedExercises = try context.fetch(request)
        
        XCTAssertEqual(migratedExercises.count, 3, "Should have 3 exercises")
        
        for exercise in migratedExercises {
            XCTAssertNotNil(exercise.setsData, "All exercises should have setsData")
            
            let setsData = try XCTUnwrap(exercise.setsData)
            let sets = try JSONDecoder().decode([ExerciseSet].self, from: setsData)
            
            XCTAssertFalse(sets.isEmpty, "Sets array should not be empty")
            XCTAssertEqual(sets.count, Int(exercise.totalSets), "Sets count should match totalSets")
        }
    }
    
    func testMigrationValidatesLegacyData() throws {
        // Given: A PlanExercise with invalid legacy data
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Invalid Exercise"
        exercise.sets = 0 // Invalid: zero sets
        exercise.reps = 12
        exercise.weight = 50.0
        exercise.restTime = 60
        exercise.orderIndex = 0
        exercise.setsData = nil
        
        try context.save()
        
        // When/Then: Migration should throw validation error
        XCTAssertThrowsError(try persistenceController.migratePlanExerciseData()) { error in
            guard let migrationError = error as? PersistenceController.MigrationError else {
                XCTFail("Expected MigrationError, got \(type(of: error))")
                return
            }
            
            if case .validationFailed(let message) = migrationError {
                XCTAssertTrue(message.contains("Invalid legacy values"), "Error message should mention invalid legacy values")
            } else {
                XCTFail("Expected validationFailed error, got \(migrationError)")
            }
        }
    }
    
    func testMigrationHandlesNegativeWeight() throws {
        // Given: A PlanExercise with negative weight (invalid)
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Invalid Weight Exercise"
        exercise.sets = 3
        exercise.reps = 10
        exercise.weight = -50.0 // Invalid: negative weight
        exercise.restTime = 60
        exercise.orderIndex = 0
        exercise.setsData = nil
        
        try context.save()
        
        // When/Then: Migration should throw validation error
        XCTAssertThrowsError(try persistenceController.migratePlanExerciseData()) { error in
            guard let migrationError = error as? PersistenceController.MigrationError else {
                XCTFail("Expected MigrationError, got \(type(of: error))")
                return
            }
            
            if case .validationFailed = migrationError {
                // Expected validation failure
            } else {
                XCTFail("Expected validationFailed error, got \(migrationError)")
            }
        }
    }
    
    // MARK: - Data Integrity Tests
    
    func testMigratedDataIntegrity() throws {
        // Given: A PlanExercise with specific legacy values
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Deadlift"
        exercise.sets = 5
        exercise.reps = 5
        exercise.weight = 150.0
        exercise.restTime = 180
        exercise.orderIndex = 0
        exercise.setsData = nil
        
        try context.save()
        
        // When: Migration is performed
        try persistenceController.migratePlanExerciseData()
        
        // Then: Verify data integrity
        let setsData = try XCTUnwrap(exercise.setsData)
        let sets = try JSONDecoder().decode([ExerciseSet].self, from: setsData)
        
        // Check that all sets have unique IDs
        let setIds = sets.map(\.id)
        let uniqueIds = Set(setIds)
        XCTAssertEqual(setIds.count, uniqueIds.count, "All sets should have unique IDs")
        
        // Check that set numbers are sequential
        let setNumbers = sets.map(\.setNumber).sorted()
        XCTAssertEqual(setNumbers, Array(1...5), "Set numbers should be sequential from 1 to 5")
        
        // Check that all sets have consistent values
        for set in sets {
            XCTAssertEqual(set.reps, 5, "All sets should have 5 reps")
            XCTAssertEqual(set.weight, 150.0, "All sets should have 150.0 weight")
            XCTAssertEqual(set.setType, .normal, "All sets should be normal type")
        }
        
        // Check computed attributes
        XCTAssertEqual(exercise.totalSets, 5, "totalSets should be 5")
        XCTAssertEqual(exercise.averageWeight, 150.0, "averageWeight should be 150.0")
    }
    
    func testValidationAfterMigration() throws {
        // Given: A valid PlanExercise with legacy format
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Pull-up"
        exercise.sets = 3
        exercise.reps = 8
        exercise.weight = 0.0
        exercise.restTime = 90
        exercise.orderIndex = 0
        exercise.setsData = nil
        
        try context.save()
        
        // When: Migration is performed
        try persistenceController.migratePlanExerciseData()
        
        // Then: Validation should pass
        XCTAssertNoThrow(try persistenceController.validateDataIntegrity())
    }
    
    // MARK: - Edge Cases
    
    func testMigrationWithZeroWeight() throws {
        // Given: A PlanExercise with zero weight (valid for bodyweight exercises)
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Bodyweight Squat"
        exercise.sets = 3
        exercise.reps = 15
        exercise.weight = 0.0 // Valid: bodyweight exercise
        exercise.restTime = 45
        exercise.orderIndex = 0
        exercise.setsData = nil
        
        try context.save()
        
        // When: Migration is performed
        XCTAssertNoThrow(try persistenceController.migratePlanExerciseData())
        
        // Then: Exercise should be migrated successfully
        XCTAssertNotNil(exercise.setsData)
        
        let setsData = try XCTUnwrap(exercise.setsData)
        let sets = try JSONDecoder().decode([ExerciseSet].self, from: setsData)
        
        XCTAssertEqual(sets.count, 3)
        for set in sets {
            XCTAssertEqual(set.weight, 0.0, "Weight should remain 0.0 for bodyweight exercises")
        }
    }
    
    func testMigrationWithSingleSet() throws {
        // Given: A PlanExercise with only one set
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Max Plank"
        exercise.sets = 1
        exercise.reps = 1
        exercise.weight = 0.0
        exercise.restTime = 0
        exercise.orderIndex = 0
        exercise.setsData = nil
        
        try context.save()
        
        // When: Migration is performed
        XCTAssertNoThrow(try persistenceController.migratePlanExerciseData())
        
        // Then: Exercise should be migrated successfully
        XCTAssertNotNil(exercise.setsData)
        XCTAssertEqual(exercise.totalSets, 1)
        
        let setsData = try XCTUnwrap(exercise.setsData)
        let sets = try JSONDecoder().decode([ExerciseSet].self, from: setsData)
        
        XCTAssertEqual(sets.count, 1)
        XCTAssertEqual(sets[0].setNumber, 1)
    }
}

// MARK: - Helper Extensions

private extension PersistenceController {
    /// Exposes the migration method for testing
    func migratePlanExerciseData() throws {
        let context = container.viewContext
        let request: NSFetchRequest<PlanExercise> = PlanExercise.fetchRequest()
        
        do {
            let exercises = try context.fetch(request)
            var migratedCount = 0
            
            for exercise in exercises {
                // Check if this exercise needs migration (has legacy data but no setsData)
                if exercise.setsData == nil && exercise.sets > 0 {
                    try migrateSinglePlanExercise(exercise)
                    migratedCount += 1
                }
            }
            
            if migratedCount > 0 {
                try context.save()
                print("Successfully migrated \(migratedCount) PlanExercise entities to new format")
            }
            
        } catch {
            throw MigrationError.migrationFailed(underlying: error)
        }
    }
    
    /// Exposes the single exercise migration method for testing
    func migrateSinglePlanExercise(_ exercise: PlanExercise) throws {
        // Extract legacy values
        let legacySets = Int(exercise.sets)
        let legacyReps = Int(exercise.reps)
        let legacyWeight = exercise.weight
        
        // Validate legacy values
        guard legacySets > 0, legacyReps > 0, legacyWeight >= 0 else {
            throw MigrationError.validationFailed("Invalid legacy values for PlanExercise: \(exercise.name ?? "unknown")")
        }
        
        // Create ExerciseSet array from legacy data
        let exerciseSets = (1...legacySets).map { setNumber in
            ExerciseSet(setNumber: setNumber, reps: legacyReps, weight: legacyWeight, setType: .normal)
        }
        
        // Serialize to JSON
        do {
            let setsData = try JSONEncoder().encode(exerciseSets)
            exercise.setsData = setsData
            
            // Update computed attributes
            exercise.totalSets = Int32(exerciseSets.count)
            exercise.averageWeight = legacyWeight
            
            print("Migrated PlanExercise '\(exercise.name ?? "unknown")': \(legacySets) sets, \(legacyReps) reps, \(legacyWeight) weight")
            
        } catch {
            throw MigrationError.migrationFailed(underlying: error)
        }
    }
}
//
//  PersistenceControllerMigrationTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

final class PersistenceControllerMigrationTests: XCTestCase {
    var testPersistenceController: PersistenceController!
    var testStoreURL: URL!

    override func setUp() {
        super.setUp()

        // Create temporary store URL for testing
        let tempDirectory = FileManager.default.temporaryDirectory
        self.testStoreURL = tempDirectory.appendingPathComponent("TestStore_\(UUID().uuidString).sqlite")

        // Create test persistence controller with in-memory store
        self.testPersistenceController = PersistenceController(inMemory: true)
    }

    override func tearDown() {
        // Clean up test files
        if let testStoreURL {
            try? FileManager.default.removeItem(at: testStoreURL)
            try? FileManager.default.removeItem(at: testStoreURL.appendingPathExtension("backup"))
        }

        self.testPersistenceController = nil
        testStoreURL = nil
        super.tearDown()
    }

    // MARK: - Migration Detection Tests

    func testNeedsMigration_WithInMemoryStore_ReturnsFalse() {
        // Given: In-memory store
        let controller = PersistenceController(inMemory: true)

        // When: Checking if migration is needed
        let needsMigration = controller.needsMigration

        // Then: Should return false for in-memory stores
        XCTAssertFalse(needsMigration, "In-memory stores should not need migration")
    }

    func testNeedsMigration_WithCurrentModel_ReturnsFalse() {
        // Given: Current model version
        let controller = self.testPersistenceController!

        // When: Checking if migration is needed
        let needsMigration = controller.needsMigration

        // Then: Should return false for current model
        XCTAssertFalse(needsMigration, "Current model should not need migration")
    }

    // MARK: - Migration Performance Tests

    func testPerformMigrationIfNeeded_WithCurrentModel_ReturnsFalse() throws {
        // Given: Current model that doesn't need migration
        let controller = self.testPersistenceController!

        // When: Attempting migration
        let migrationPerformed = try controller.performMigrationIfNeeded()

        // Then: Should return false (no migration needed)
        XCTAssertFalse(migrationPerformed, "Should return false when no migration is needed")
    }

    // MARK: - Data Validation Tests

    func testValidateDataIntegrity_WithValidData_Succeeds() throws {
        // Given: Valid test data
        let context = self.testPersistenceController.container.viewContext
        self.createValidTestData(context: context)
        try context.save()

        // When: Validating data integrity
        // Then: Should not throw
        XCTAssertNoThrow(try self.testPersistenceController.validateDataIntegrity())
    }

    func testValidateUserEquipment_WithInvalidEquipmentId_ThrowsError() throws {
        // Given: UserEquipment with empty equipmentId
        let context = self.testPersistenceController.container.viewContext
        let equipment = UserEquipment(context: context)
        equipment.equipmentId = "" // Invalid
        equipment.name = "Test Equipment"
        equipment.isSelected = true
        equipment.dateAdded = Date()
        try context.save()

        // When: Validating data integrity
        // Then: Should throw validation error
        XCTAssertThrowsError(try self.testPersistenceController.validateDataIntegrity()) { error in
            guard let migrationError = error as? PersistenceController.MigrationError,
                  case let .validationFailed(message) = migrationError
            else {
                XCTFail("Expected MigrationError.validationFailed")
                return
            }
            XCTAssertTrue(message.contains("UserEquipment"), "Error message should mention UserEquipment")
        }
    }

    func testValidateUserEquipment_WithFutureDateAdded_ThrowsError() throws {
        // Given: UserEquipment with future dateAdded
        let context = self.testPersistenceController.container.viewContext
        let equipment = UserEquipment(context: context)
        equipment.equipmentId = "test-id"
        equipment.name = "Test Equipment"
        equipment.isSelected = true
        equipment.dateAdded = Date().addingTimeInterval(86_400) // Tomorrow
        try context.save()

        // When: Validating data integrity
        // Then: Should throw validation error
        XCTAssertThrowsError(try self.testPersistenceController.validateDataIntegrity()) { error in
            guard let migrationError = error as? PersistenceController.MigrationError,
                  case let .validationFailed(message) = migrationError
            else {
                XCTFail("Expected MigrationError.validationFailed")
                return
            }
            XCTAssertTrue(message.contains("future dateAdded"), "Error message should mention future dateAdded")
        }
    }

    func testValidateWorkoutPlan_WithEmptyName_ThrowsError() throws {
        // Given: WorkoutPlan with empty name
        let context = self.testPersistenceController.container.viewContext
        let plan = WorkoutPlan(context: context)
        plan.planId = UUID()
        plan.name = "" // Invalid
        plan.createdDate = Date()
        plan.exerciseCount = 1
        plan.planData = try JSONSerialization.data(withJSONObject: ["test": "data"])
        try context.save()

        // When: Validating data integrity
        // Then: Should throw validation error
        XCTAssertThrowsError(try self.testPersistenceController.validateDataIntegrity()) { error in
            guard let migrationError = error as? PersistenceController.MigrationError,
                  case let .validationFailed(message) = migrationError
            else {
                XCTFail("Expected MigrationError.validationFailed")
                return
            }
            XCTAssertTrue(message.contains("empty name"), "Error message should mention empty name")
        }
    }

    func testValidateWorkoutPlan_WithInvalidJSON_ThrowsError() throws {
        // Given: WorkoutPlan with invalid JSON data
        let context = self.testPersistenceController.container.viewContext
        let plan = WorkoutPlan(context: context)
        plan.planId = UUID()
        plan.name = "Test Plan"
        plan.createdDate = Date()
        plan.exerciseCount = 1
        plan.planData = "invalid json".data(using: .utf8)! // Invalid JSON
        try context.save()

        // When: Validating data integrity
        // Then: Should throw validation error
        XCTAssertThrowsError(try self.testPersistenceController.validateDataIntegrity()) { error in
            guard let migrationError = error as? PersistenceController.MigrationError,
                  case let .validationFailed(message) = migrationError
            else {
                XCTFail("Expected MigrationError.validationFailed")
                return
            }
            XCTAssertTrue(message.contains("invalid planData JSON"), "Error message should mention invalid JSON")
        }
    }

    func testValidatePlanExercise_WithNegativeValues_ThrowsError() throws {
        // Given: PlanExercise with negative values
        let context = self.testPersistenceController.container.viewContext
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Test Exercise"
        exercise.sets = -1 // Invalid
        exercise.reps = 10
        exercise.weight = 50.0
        exercise.restTime = 60
        exercise.orderIndex = 0
        try context.save()

        // When: Validating data integrity
        // Then: Should throw validation error
        XCTAssertThrowsError(try self.testPersistenceController.validateDataIntegrity()) { error in
            guard let migrationError = error as? PersistenceController.MigrationError,
                  case let .validationFailed(message) = migrationError
            else {
                XCTFail("Expected MigrationError.validationFailed")
                return
            }
            XCTAssertTrue(
                message.contains("invalid numeric values"),
                "Error message should mention invalid numeric values"
            )
        }
    }

    func testValidateExerciseMetadata_WithFutureLastUsed_ThrowsError() throws {
        // Given: ExerciseMetadata with future lastUsed date
        let context = self.testPersistenceController.container.viewContext
        let metadata = ExerciseMetadata(context: context)
        metadata.exerciseId = UUID()
        metadata.name = "Test Exercise"
        metadata.lastUsed = Date().addingTimeInterval(86_400) // Tomorrow
        metadata.usageCount = 5
        metadata.customWeight = 50.0
        try context.save()

        // When: Validating data integrity
        // Then: Should throw validation error
        XCTAssertThrowsError(try self.testPersistenceController.validateDataIntegrity()) { error in
            guard let migrationError = error as? PersistenceController.MigrationError,
                  case let .validationFailed(message) = migrationError
            else {
                XCTFail("Expected MigrationError.validationFailed")
                return
            }
            XCTAssertTrue(message.contains("future lastUsed date"), "Error message should mention future lastUsed date")
        }
    }

    // MARK: - Corruption Detection and Handling Tests

    func testDetectAndHandleCorruption_WithValidData_ReturnsFalse() {
        // Given: Valid test data
        let context = self.testPersistenceController.container.viewContext
        self.createValidTestData(context: context)
        try? context.save()

        // When: Detecting corruption
        let hasCorruption = self.testPersistenceController.detectAndHandleCorruption()

        // Then: Should return false (no corruption)
        XCTAssertFalse(hasCorruption, "Should return false when no corruption is detected")
    }

    func testDetectAndHandleCorruption_WithCorruptedData_ReturnsTrue() {
        // Given: Corrupted test data
        let context = self.testPersistenceController.container.viewContext
        self.createCorruptedTestData(context: context)
        try? context.save()

        // When: Detecting and handling corruption
        let hasCorruption = self.testPersistenceController.detectAndHandleCorruption()

        // Then: Should return true (corruption detected and handled)
        XCTAssertTrue(hasCorruption, "Should return true when corruption is detected and handled")
    }

    func testDetectAndHandleCorruption_CleansUpCorruptedEntities() {
        // Given: Mix of valid and corrupted data
        let context = self.testPersistenceController.container.viewContext

        // Valid equipment
        let validEquipment = UserEquipment(context: context)
        validEquipment.equipmentId = "valid-id"
        validEquipment.name = "Valid Equipment"
        validEquipment.isSelected = true
        validEquipment.dateAdded = Date()

        // Corrupted equipment
        let corruptedEquipment = UserEquipment(context: context)
        corruptedEquipment.equipmentId = "" // Invalid
        corruptedEquipment.name = "Corrupted Equipment"
        corruptedEquipment.isSelected = true
        corruptedEquipment.dateAdded = Date()

        try? context.save()

        // When: Handling corruption
        let hasCorruption = self.testPersistenceController.detectAndHandleCorruption()

        // Then: Should clean up corrupted entities but keep valid ones
        XCTAssertTrue(hasCorruption, "Should detect corruption")

        let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
        let remainingEquipment = try? context.fetch(request)

        XCTAssertEqual(remainingEquipment?.count, 1, "Should have only valid equipment remaining")
        XCTAssertEqual(remainingEquipment?.first?.equipmentId, "valid-id", "Should keep valid equipment")
    }

    // MARK: - Error Handling Tests

    func testMigrationError_LocalizedDescription() {
        let errors: [PersistenceController.MigrationError] = [
            .storeNotFound,
            .migrationFailed(underlying: NSError(domain: "test", code: 1)),
            .dataCorruption,
            .backupFailed,
            .validationFailed("test message")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "All migration errors should have descriptions")
            XCTAssertFalse(error.errorDescription!.isEmpty, "Error descriptions should not be empty")
        }
    }

    // MARK: - Performance Tests

    func testValidateDataIntegrity_Performance() {
        // Given: Large dataset
        let context = self.testPersistenceController.container.viewContext
        self.createLargeValidDataset(context: context)
        try? context.save()

        // When: Measuring validation performance
        measure {
            try? self.testPersistenceController.validateDataIntegrity()
        }
    }

    func testDetectAndHandleCorruption_Performance() {
        // Given: Large dataset with some corruption
        let context = self.testPersistenceController.container.viewContext
        self.createLargeDatasetWithCorruption(context: context)
        try? context.save()

        // When: Measuring corruption handling performance
        measure {
            _ = self.testPersistenceController.detectAndHandleCorruption()
        }
    }

    // MARK: - Helper Methods

    private func createValidTestData(context: NSManagedObjectContext) {
        // Create valid UserEquipment
        let equipment = UserEquipment(context: context)
        equipment.equipmentId = "test-equipment-1"
        equipment.name = "Test Equipment"
        equipment.isSelected = true
        equipment.dateAdded = Date()
        equipment.category = "Weights"

        // Create valid WorkoutPlan
        let plan = WorkoutPlan(context: context)
        plan.planId = UUID()
        plan.name = "Test Plan"
        plan.createdDate = Date()
        plan.exerciseCount = 1
        plan.planData = try! JSONSerialization.data(withJSONObject: ["exercises": []])

        // Create valid PlanExercise
        let exercise = PlanExercise(context: context)
        exercise.exerciseId = UUID()
        exercise.name = "Test Exercise"
        exercise.sets = 3
        exercise.reps = 10
        exercise.weight = 50.0
        exercise.restTime = 60
        exercise.orderIndex = 0

        // Create valid ExerciseMetadata
        let metadata = ExerciseMetadata(context: context)
        metadata.exerciseId = UUID()
        metadata.name = "Test Exercise Metadata"
        metadata.lastUsed = Date()
        metadata.usageCount = 5
        metadata.customWeight = 50.0
    }

    private func createCorruptedTestData(context: NSManagedObjectContext) {
        // Create corrupted UserEquipment
        let equipment = UserEquipment(context: context)
        equipment.equipmentId = "" // Invalid
        equipment.name = "Corrupted Equipment"
        equipment.isSelected = true
        equipment.dateAdded = Date()

        // Create corrupted WorkoutPlan
        let plan = WorkoutPlan(context: context)
        plan.planId = UUID()
        plan.name = "" // Invalid
        plan.createdDate = Date()
        plan.exerciseCount = 1
        plan.planData = "invalid json".data(using: .utf8)! // Invalid JSON
    }

    private func createLargeValidDataset(context: NSManagedObjectContext) {
        for i in 0 ..< 100 {
            let equipment = UserEquipment(context: context)
            equipment.equipmentId = "equipment-\(i)"
            equipment.name = "Equipment \(i)"
            equipment.isSelected = i % 2 == 0
            equipment.dateAdded = Date()

            let plan = WorkoutPlan(context: context)
            plan.planId = UUID()
            plan.name = "Plan \(i)"
            plan.createdDate = Date()
            plan.exerciseCount = Int32(i % 10 + 1)
            plan.planData = try! JSONSerialization.data(withJSONObject: ["exercises": []])
        }
    }

    private func createLargeDatasetWithCorruption(context: NSManagedObjectContext) {
        for i in 0 ..< 100 {
            let equipment = UserEquipment(context: context)
            equipment.equipmentId = i % 10 == 0 ? "" : "equipment-\(i)" // 10% corrupted
            equipment.name = "Equipment \(i)"
            equipment.isSelected = i % 2 == 0
            equipment.dateAdded = Date()
        }
    }
}

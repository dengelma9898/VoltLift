//
//  PersistenceTestUtilities.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

/// Utilities for persistence system testing
/// Provides common test setup, cleanup, and verification functions
@MainActor
class PersistenceTestUtilities {
    // MARK: - Test Environment Setup

    /// Creates a clean in-memory persistence controller for testing
    static func createTestPersistenceController() -> PersistenceController {
        PersistenceController(inMemory: true)
    }

    /// Creates a test UserPreferencesService with clean state
    static func createTestUserPreferencesService() async -> (UserPreferencesService, PersistenceController) {
        let persistenceController = self.createTestPersistenceController()
        let service = UserPreferencesService(persistenceController: persistenceController)
        return (service, persistenceController)
    }

    /// Sets up test environment with predefined data
    static func setupTestEnvironment(
        withEquipment equipment: [EquipmentItem]? = nil,
        withPlans plans: [WorkoutPlanData]? = nil
    ) async throws -> (UserPreferencesService, PersistenceController, TestDataFactory) {
        let (service, controller) = await createTestUserPreferencesService()
        let factory = TestDataFactory()

        // Setup equipment if provided
        if let equipment {
            try await service.saveEquipmentSelection(equipment)
        }

        // Setup plans if provided
        if let plans {
            for plan in plans {
                try await service.savePlan(plan)
            }
        }

        return (service, controller, factory)
    }

    // MARK: - Data Verification Utilities

    /// Verifies that Core Data contains expected equipment data
    static func verifyEquipmentInCoreData(
        _ persistenceController: PersistenceController,
        expectedCount: Int,
        selectedCount: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
        let savedEquipment = try context.fetch(request)

        XCTAssertEqual(
            savedEquipment.count,
            expectedCount,
            "Expected \(expectedCount) equipment items in Core Data",
            file: file,
            line: line
        )

        if let selectedCount {
            let actualSelectedCount = savedEquipment.count(where: { $0.isSelected })
            XCTAssertEqual(
                actualSelectedCount,
                selectedCount,
                "Expected \(selectedCount) selected equipment items",
                file: file,
                line: line
            )
        }
    }

    /// Verifies that Core Data contains expected workout plan data
    static func verifyPlansInCoreData(
        _ persistenceController: PersistenceController,
        expectedCount: Int,
        usedCount: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        let savedPlans = try context.fetch(request)

        XCTAssertEqual(
            savedPlans.count,
            expectedCount,
            "Expected \(expectedCount) workout plans in Core Data",
            file: file,
            line: line
        )

        if let usedCount {
            let actualUsedCount = savedPlans.count(where: { $0.lastUsedDate != nil })
            XCTAssertEqual(
                actualUsedCount,
                usedCount,
                "Expected \(usedCount) used workout plans",
                file: file,
                line: line
            )
        }
    }

    /// Verifies data consistency between service and Core Data
    static func verifyDataConsistency(
        service: UserPreferencesService,
        persistenceController: PersistenceController,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        // Load data from service
        try await service.loadSelectedEquipment()
        try await service.loadSavedPlans()

        // Verify equipment consistency
        let serviceEquipmentCount = service.selectedEquipment.count
        let context = persistenceController.container.viewContext

        let equipmentRequest: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
        let coreDataEquipmentCount = try context.fetch(equipmentRequest).count

        XCTAssertEqual(
            serviceEquipmentCount,
            coreDataEquipmentCount,
            "Service and Core Data equipment counts should match",
            file: file,
            line: line
        )

        // Verify plan consistency
        let servicePlansCount = service.savedPlans.count

        let plansRequest: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        let coreDataPlansCount = try context.fetch(plansRequest).count

        XCTAssertEqual(
            servicePlansCount,
            coreDataPlansCount,
            "Service and Core Data plans counts should match",
            file: file,
            line: line
        )
    }

    // MARK: - Performance Measurement Utilities

    /// Measures execution time of an async operation
    static func measureAsyncTime<T>(
        operation: () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows -> (result: T, time: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        let executionTime = endTime - startTime

        return (result: result, time: executionTime)
    }

    /// Measures and asserts execution time is within expected bounds
    static func measureAndAssertTime<T>(
        maxTime: TimeInterval,
        operation: () async throws -> T,
        description: String = "Operation",
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows -> T {
        let (result, time) = try await measureAsyncTime(operation: operation)

        XCTAssertLessThan(
            time,
            maxTime,
            "\(description) should complete within \(maxTime) seconds, took \(String(format: "%.3f", time))s",
            file: file,
            line: line
        )

        return result
    }

    /// Measures memory usage before and after an operation
    static func measureMemoryUsage<T>(
        operation: () async throws -> T
    ) async rethrows -> (result: T, memoryDelta: Int64) {
        let initialMemory = self.getMemoryUsage()
        let result = try await operation()
        let finalMemory = self.getMemoryUsage()
        let memoryDelta = finalMemory - initialMemory

        return (result: result, memoryDelta: memoryDelta)
    }

    // MARK: - Concurrency Testing Utilities

    /// Executes multiple async operations concurrently and collects results
    static func executeConcurrentOperations<T>(
        operations: [() async throws -> T],
        maxConcurrency: Int? = nil
    ) async throws -> [T] {
        let concurrency = maxConcurrency ?? operations.count
        var results: [T] = []
        results.reserveCapacity(operations.count)

        for chunk in operations.chunked(into: concurrency) {
            let chunkResults = try await withThrowingTaskGroup(of: T.self) { group in
                for operation in chunk {
                    group.addTask {
                        try await operation()
                    }
                }

                var chunkResults: [T] = []
                for try await result in group {
                    chunkResults.append(result)
                }
                return chunkResults
            }
            results.append(contentsOf: chunkResults)
        }

        return results
    }

    /// Tests concurrent read operations for thread safety
    static func testConcurrentReads(
        service: UserPreferencesService,
        operationCount: Int = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let operations = (0 ..< operationCount).map { _ in
            {
                try await service.loadSelectedEquipment()
                try await service.loadSavedPlans()
            }
        }

        let (_, time) = try await measureAsyncTime {
            try await self.executeConcurrentOperations(operations: operations)
        }

        // Concurrent reads should complete reasonably quickly
        XCTAssertLessThan(
            time,
            10.0,
            "Concurrent reads should complete within 10 seconds",
            file: file,
            line: line
        )
    }

    /// Tests concurrent write operations for data integrity
    static func testConcurrentWrites(
        service: UserPreferencesService,
        testDataFactory: TestDataFactory,
        operationCount: Int = 5,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let operations = (0 ..< operationCount).map { index in
            {
                let plan = testDataFactory.createWorkoutPlan(name: "Concurrent Plan \(index)")
                try await service.savePlan(plan)
            }
        }

        try await self.executeConcurrentOperations(operations: operations)

        // Verify all plans were saved
        try await service.loadSavedPlans()
        let concurrentPlans = service.savedPlans.filter { $0.name.contains("Concurrent Plan") }

        XCTAssertEqual(
            concurrentPlans.count,
            operationCount,
            "All concurrent writes should succeed",
            file: file,
            line: line
        )
    }

    // MARK: - Error Testing Utilities

    /// Tests error handling for invalid operations
    static func testErrorHandling(
        service: UserPreferencesService,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        let nonExistentPlanId = UUID()

        // Test marking non-existent plan as used
        do {
            try await service.markPlanAsUsed(nonExistentPlanId)
            XCTFail("Should throw error for non-existent plan", file: file, line: line)
        } catch let error as UserPreferencesError {
            if case let .planNotFound(id) = error {
                XCTAssertEqual(id, nonExistentPlanId, file: file, line: line)
            } else {
                XCTFail("Expected planNotFound error, got \(error)", file: file, line: line)
            }
        } catch {
            XCTFail("Expected UserPreferencesError, got \(error)", file: file, line: line)
        }

        // Test renaming non-existent plan
        do {
            try await service.renamePlan(nonExistentPlanId, newName: "New Name")
            XCTFail("Should throw error for non-existent plan", file: file, line: line)
        } catch is UserPreferencesError {
            // Expected error
        } catch {
            XCTFail("Expected UserPreferencesError, got \(error)", file: file, line: line)
        }

        // Test deleting non-existent plan
        do {
            try await service.deletePlan(nonExistentPlanId)
            XCTFail("Should throw error for non-existent plan", file: file, line: line)
        } catch is UserPreferencesError {
            // Expected error
        } catch {
            XCTFail("Expected UserPreferencesError, got \(error)", file: file, line: line)
        }
    }

    // MARK: - Data Cleanup Utilities

    /// Clears all equipment data from Core Data
    static func clearAllEquipment(_ persistenceController: PersistenceController) throws {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<NSFetchRequestResult> = UserEquipment.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        try context.execute(deleteRequest)
        try context.save()
    }

    /// Clears all workout plan data from Core Data
    static func clearAllPlans(_ persistenceController: PersistenceController) throws {
        let context = persistenceController.container.viewContext

        // Clear workout plans
        let plansRequest: NSFetchRequest<NSFetchRequestResult> = WorkoutPlan.fetchRequest()
        let deletePlansRequest = NSBatchDeleteRequest(fetchRequest: plansRequest)
        try context.execute(deletePlansRequest)

        // Clear plan exercises
        let exercisesRequest: NSFetchRequest<NSFetchRequestResult> = PlanExercise.fetchRequest()
        let deleteExercisesRequest = NSBatchDeleteRequest(fetchRequest: exercisesRequest)
        try context.execute(deleteExercisesRequest)

        try context.save()
    }

    /// Clears all test data from Core Data
    static func clearAllTestData(_ persistenceController: PersistenceController) throws {
        try self.clearAllEquipment(persistenceController)
        try self.clearAllPlans(persistenceController)
    }

    // MARK: - Validation Utilities

    /// Validates Core Data model integrity
    static func validateCoreDataIntegrity(
        _ persistenceController: PersistenceController,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let context = persistenceController.container.viewContext

        // Validate equipment entities
        let equipmentRequest: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
        let equipment = try context.fetch(equipmentRequest)

        for item in equipment {
            XCTAssertNotNil(item.equipmentId, "Equipment ID should not be nil", file: file, line: line)
            XCTAssertNotNil(item.name, "Equipment name should not be nil", file: file, line: line)
            XCTAssertNotNil(item.dateAdded, "Equipment date added should not be nil", file: file, line: line)
        }

        // Validate workout plan entities
        let plansRequest: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        let plans = try context.fetch(plansRequest)

        for plan in plans {
            XCTAssertNotNil(plan.planId, "Plan ID should not be nil", file: file, line: line)
            XCTAssertNotNil(plan.name, "Plan name should not be nil", file: file, line: line)
            XCTAssertNotNil(plan.createdDate, "Plan created date should not be nil", file: file, line: line)
            XCTAssertNotNil(plan.planData, "Plan data should not be nil", file: file, line: line)
            XCTAssertGreaterThanOrEqual(
                plan.exerciseCount,
                0,
                "Exercise count should be non-negative",
                file: file,
                line: line
            )
        }

        // Validate plan exercise entities
        let exercisesRequest: NSFetchRequest<PlanExercise> = PlanExercise.fetchRequest()
        let exercises = try context.fetch(exercisesRequest)

        for exercise in exercises {
            XCTAssertNotNil(exercise.exerciseId, "Exercise ID should not be nil", file: file, line: line)
            XCTAssertNotNil(exercise.name, "Exercise name should not be nil", file: file, line: line)
            XCTAssertGreaterThan(exercise.sets, 0, "Exercise sets should be positive", file: file, line: line)
            XCTAssertGreaterThan(exercise.reps, 0, "Exercise reps should be positive", file: file, line: line)
            XCTAssertGreaterThanOrEqual(
                exercise.weight,
                0,
                "Exercise weight should be non-negative",
                file: file,
                line: line
            )
            XCTAssertGreaterThanOrEqual(
                exercise.restTime,
                0,
                "Exercise rest time should be non-negative",
                file: file,
                line: line
            )
        }
    }

    /// Validates service state consistency
    static func validateServiceState(
        _ service: UserPreferencesService,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        // Validate equipment state
        for equipment in service.selectedEquipment {
            XCTAssertFalse(equipment.id.isEmpty, "Equipment ID should not be empty", file: file, line: line)
            XCTAssertFalse(equipment.name.isEmpty, "Equipment name should not be empty", file: file, line: line)
            XCTAssertFalse(equipment.category.isEmpty, "Equipment category should not be empty", file: file, line: line)
        }

        // Validate plans state
        for plan in service.savedPlans {
            XCTAssertFalse(plan.name.isEmpty, "Plan name should not be empty", file: file, line: line)
            XCTAssertFalse(plan.exercises.isEmpty, "Plan should have exercises", file: file, line: line)

            // Validate exercise order
            let sortedExercises = plan.exercises.sorted { $0.orderIndex < $1.orderIndex }
            XCTAssertEqual(
                plan.exercises,
                sortedExercises,
                "Exercises should be in correct order",
                file: file,
                line: line
            )

            // Validate exercise data
            for exercise in plan.exercises {
                XCTAssertFalse(exercise.name.isEmpty, "Exercise name should not be empty", file: file, line: line)
                XCTAssertGreaterThan(exercise.sets.count, 0, "Exercise should have sets", file: file, line: line)
                XCTAssertGreaterThan(
                    exercise.averageReps,
                    0,
                    "Exercise average reps should be positive",
                    file: file,
                    line: line
                )
                XCTAssertGreaterThanOrEqual(
                    exercise.averageWeight,
                    0,
                    "Exercise average weight should be non-negative",
                    file: file,
                    line: line
                )
                XCTAssertGreaterThanOrEqual(
                    exercise.restTime,
                    0,
                    "Exercise rest time should be non-negative",
                    file: file,
                    line: line
                )
            }
        }
    }

    // MARK: - Private Helper Methods

    private static func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Test Assertion Helpers

/// Custom assertion for async operations with timeout
func XCTAssertAsyncNoThrow(
    _ expression: @autoclosure () async throws -> some Any,
    timeout: TimeInterval = 5.0,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line
) async {
    do {
        _ = try await withTimeout(timeout) {
            try await expression()
        }
    } catch {
        XCTFail("Async operation threw error: \(error). \(message())", file: file, line: line)
    }
}

/// Custom assertion for async operations that should throw
func XCTAssertAsyncThrowsError(
    _ expression: @autoclosure () async throws -> some Any,
    timeout: TimeInterval = 5.0,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #file,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    do {
        _ = try await withTimeout(timeout) {
            try await expression()
        }
        XCTFail("Async operation should have thrown an error. \(message())", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}

/// Executes async operation with timeout
func withTimeout<T>(
    _ timeout: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }

        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            throw TimeoutError()
        }

        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    let message = "Operation timed out"
}

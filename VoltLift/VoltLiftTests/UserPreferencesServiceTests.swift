//
//  UserPreferencesServiceTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

@MainActor
final class UserPreferencesServiceTests: XCTestCase {
    // MARK: - Properties

    var service: UserPreferencesService!
    var testPersistenceController: PersistenceController!
    var testContext: NSManagedObjectContext!

    // MARK: - Test Data

    let sampleEquipment = [
        EquipmentItem(id: "barbell", name: "Barbell", category: "Free Weights", isSelected: true),
        EquipmentItem(id: "dumbbell", name: "Dumbbell", category: "Free Weights", isSelected: true),
        EquipmentItem(id: "bench", name: "Bench", category: "Equipment", isSelected: false),
        EquipmentItem(id: "pullup-bar", name: "Pull-up Bar", category: "Equipment", isSelected: true)
    ]

    let sampleExercises = [
        ExerciseData(id: UUID(), name: "Bench Press", sets: 3, reps: 10, weight: 135.0, restTime: 120, orderIndex: 0),
        ExerciseData(id: UUID(), name: "Squats", sets: 3, reps: 12, weight: 185.0, restTime: 180, orderIndex: 1),
        ExerciseData(id: UUID(), name: "Deadlifts", sets: 3, reps: 8, weight: 225.0, restTime: 240, orderIndex: 2)
    ]

    var sampleWorkoutPlan: WorkoutPlanData {
        WorkoutPlanData(
            id: UUID(),
            name: "Upper Body Strength",
            exercises: self.sampleExercises,
            createdDate: Date(),
            lastUsedDate: nil
        )
    }

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory persistence controller for testing
        self.testPersistenceController = PersistenceController(inMemory: true)
        self.testContext = self.testPersistenceController.container.viewContext

        // Initialize service with test persistence controller
        self.service = UserPreferencesService(persistenceController: self.testPersistenceController)
    }

    override func tearDown() async throws {
        self.service = nil
        self.testPersistenceController = nil
        self.testContext = nil
        try await super.tearDown()
    }

    // MARK: - Equipment Loading Tests

    func testLoadSelectedEquipment_EmptyDatabase_ReturnsEmptyArray() async throws {
        // When
        try await self.service.loadSelectedEquipment()

        // Then
        XCTAssertTrue(self.service.selectedEquipment.isEmpty)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)
    }

    func testLoadSelectedEquipment_WithData_ReturnsCorrectEquipment() async throws {
        // Given
        try await populateTestEquipment()

        // When
        try await self.service.loadSelectedEquipment()

        // Then
        XCTAssertEqual(self.service.selectedEquipment.count, 4)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        // Verify equipment is sorted by category then name
        let firstItem = self.service.selectedEquipment.first!
        XCTAssertEqual(firstItem.category, "Equipment")
        XCTAssertEqual(firstItem.name, "Bench")
    }

    func testLoadSelectedEquipment_WithCorruptedData_HandlesGracefully() async throws {
        // Given - Create corrupted equipment (missing required fields)
        let corruptedEquipment = UserEquipment(context: testContext)
        corruptedEquipment.equipmentId = nil // Missing required field
        corruptedEquipment.name = "Test"
        corruptedEquipment.isSelected = true
        corruptedEquipment.dateAdded = Date()

        // Also add valid equipment to ensure filtering works
        let validEquipment = UserEquipment(context: testContext)
        validEquipment.equipmentId = "valid-id"
        validEquipment.name = "Valid Equipment"
        validEquipment.isSelected = true
        validEquipment.dateAdded = Date()
        validEquipment.category = "Test"

        try self.testContext.save()

        // When
        try await self.service.loadSelectedEquipment()

        // Then - Should filter out corrupted data but keep valid data
        XCTAssertEqual(self.service.selectedEquipment.count, 1)
        XCTAssertEqual(self.service.selectedEquipment.first?.id, "valid-id")
        XCTAssertFalse(self.service.isLoading)
    }

    // MARK: - Equipment Saving Tests

    func testSaveEquipmentSelection_NewEquipment_SavesSuccessfully() async throws {
        // When
        try await self.service.saveEquipmentSelection(self.sampleEquipment)

        // Then
        XCTAssertEqual(self.service.selectedEquipment.count, 4)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        // Verify data was saved to Core Data
        let savedEquipment = try await fetchAllEquipmentFromCoreData()
        XCTAssertEqual(savedEquipment.count, 4)

        let barbellEquipment = savedEquipment.first { $0.equipmentId == "barbell" }
        XCTAssertNotNil(barbellEquipment)
        XCTAssertEqual(barbellEquipment?.name, "Barbell")
        XCTAssertEqual(barbellEquipment?.category, "Free Weights")
        XCTAssertTrue(barbellEquipment?.isSelected ?? false)
    }

    func testSaveEquipmentSelection_OverwritesExistingData() async throws {
        // Given - Save initial equipment
        try await self.service.saveEquipmentSelection(self.sampleEquipment)

        // When - Save different equipment
        let newEquipment = [
            EquipmentItem(id: "kettlebell", name: "Kettlebell", category: "Free Weights", isSelected: true)
        ]
        try await service.saveEquipmentSelection(newEquipment)

        // Then
        XCTAssertEqual(self.service.selectedEquipment.count, 1)
        XCTAssertEqual(self.service.selectedEquipment.first?.id, "kettlebell")

        // Verify old data was cleared
        let savedEquipment = try await fetchAllEquipmentFromCoreData()
        XCTAssertEqual(savedEquipment.count, 1)
        XCTAssertNil(savedEquipment.first { $0.equipmentId == "barbell" })
    }

    func testSaveEquipmentSelection_EmptyArray_ClearsAllData() async throws {
        // Given - Save initial equipment
        try await self.service.saveEquipmentSelection(self.sampleEquipment)

        // When - Save empty array
        try await self.service.saveEquipmentSelection([])

        // Then
        XCTAssertTrue(self.service.selectedEquipment.isEmpty)

        // Verify data was cleared from Core Data
        let savedEquipment = try await fetchAllEquipmentFromCoreData()
        XCTAssertTrue(savedEquipment.isEmpty)
    }

    // MARK: - Equipment Update Tests

    func testUpdateEquipmentSelection_ExistingEquipment_UpdatesSuccessfully() async throws {
        // Given
        try await self.service.saveEquipmentSelection(self.sampleEquipment)
        let benchEquipment = self.sampleEquipment.first { $0.id == "bench" }!

        // When - Update bench from unselected to selected
        try await self.service.updateEquipmentSelection(benchEquipment, isSelected: true)

        // Then
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        let updatedBench = self.service.selectedEquipment.first { $0.id == "bench" }
        XCTAssertNotNil(updatedBench)
        XCTAssertTrue(updatedBench?.isSelected ?? false)

        // Verify update was saved to Core Data
        let savedEquipment = try await fetchAllEquipmentFromCoreData()
        let savedBench = savedEquipment.first { $0.equipmentId == "bench" }
        XCTAssertTrue(savedBench?.isSelected ?? false)
    }

    func testUpdateEquipmentSelection_NonExistentEquipment_CreatesNewEntry() async throws {
        // Given - Empty database
        let newEquipment = EquipmentItem(id: "new-item", name: "New Item", category: "Test", isSelected: true)

        // When
        try await service.updateEquipmentSelection(newEquipment, isSelected: true)

        // Then
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        // Verify new equipment was created in Core Data
        let savedEquipment = try await fetchAllEquipmentFromCoreData()
        XCTAssertEqual(savedEquipment.count, 1)

        let savedItem = savedEquipment.first
        XCTAssertEqual(savedItem?.equipmentId, "new-item")
        XCTAssertEqual(savedItem?.name, "New Item")
        XCTAssertTrue(savedItem?.isSelected ?? false)
    }

    // MARK: - Setup Completion Tests

    func testCheckSetupCompletion_NoEquipment_ReturnsFalse() async throws {
        // When
        let isComplete = try await service.checkSetupCompletion()

        // Then
        XCTAssertFalse(isComplete)
        XCTAssertFalse(self.service.hasCompletedSetup)
        XCTAssertNil(self.service.lastError)
    }

    func testCheckSetupCompletion_WithSelectedEquipment_ReturnsTrue() async throws {
        // Given
        try await self.service.saveEquipmentSelection(self.sampleEquipment)

        // When
        let isComplete = try await service.checkSetupCompletion()

        // Then
        XCTAssertTrue(isComplete)
        XCTAssertTrue(self.service.hasCompletedSetup)
        XCTAssertNil(self.service.lastError)
    }

    func testCheckSetupCompletion_WithUnselectedEquipment_ReturnsFalse() async throws {
        // Given - Equipment exists but none are selected
        let unselectedEquipment = self.sampleEquipment.map {
            EquipmentItem(id: $0.id, name: $0.name, category: $0.category, isSelected: false)
        }
        try await self.service.saveEquipmentSelection(unselectedEquipment)

        // When
        let isComplete = try await service.checkSetupCompletion()

        // Then
        XCTAssertFalse(isComplete)
        XCTAssertFalse(self.service.hasCompletedSetup)
    }

    func testMarkSetupComplete_WithSelectedEquipment_Succeeds() async throws {
        // Given
        try await self.service.saveEquipmentSelection(self.sampleEquipment)

        // When
        try await self.service.markSetupComplete()

        // Then
        XCTAssertTrue(self.service.hasCompletedSetup)
        XCTAssertNil(self.service.lastError)
    }

    func testMarkSetupComplete_WithoutSelectedEquipment_ThrowsError() async throws {
        // When & Then
        do {
            try await self.service.markSetupComplete()
            XCTFail("Expected error to be thrown")
        } catch let error as UserPreferencesError {
            XCTAssertEqual(error, .invalidData(field: "equipment selection"))
            XCTAssertFalse(service.hasCompletedSetup)
        }
    }

    // MARK: - Workout Plan Loading Tests

    func testLoadSavedPlans_EmptyDatabase_ReturnsEmptyArray() async throws {
        // When
        try await self.service.loadSavedPlans()

        // Then
        XCTAssertTrue(self.service.savedPlans.isEmpty)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)
    }

    func testLoadSavedPlans_WithData_ReturnsCorrectPlans() async throws {
        // Given
        let plan1 = self.sampleWorkoutPlan
        let plan2 = WorkoutPlanData(
            id: UUID(),
            name: "Lower Body Power",
            exercises: [sampleExercises[1]], // Just squats
            createdDate: Date().addingTimeInterval(-86_400), // Yesterday
            lastUsedDate: Date().addingTimeInterval(-3_600) // 1 hour ago
        )

        try await self.service.savePlan(plan1)
        try await self.service.savePlan(plan2)

        // When
        try await self.service.loadSavedPlans()

        // Then
        XCTAssertEqual(self.service.savedPlans.count, 2)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        // Verify plans are sorted by last used date (most recent first), then created date
        let firstPlan = self.service.savedPlans.first!
        XCTAssertEqual(firstPlan.name, "Lower Body Power") // Has lastUsedDate, should be first
    }

    func testLoadSavedPlans_WithCorruptedData_HandlesGracefully() async throws {
        // Given - Create corrupted plan (invalid JSON data)
        let corruptedPlan = WorkoutPlan(context: testContext)
        corruptedPlan.planId = UUID()
        corruptedPlan.name = "Corrupted Plan"
        corruptedPlan.createdDate = Date()
        corruptedPlan.exerciseCount = 1
        corruptedPlan.planData = "invalid json".data(using: .utf8)! // Invalid JSON

        // Also add valid plan to ensure filtering works
        let validPlan = self.sampleWorkoutPlan
        try await self.service.savePlan(validPlan)

        try self.testContext.save()

        // When & Then - Should handle corrupted data gracefully
        do {
            try await self.service.loadSavedPlans()
            // Should have filtered out corrupted data but kept valid data
            XCTAssertEqual(self.service.savedPlans.count, 1)
            XCTAssertEqual(self.service.savedPlans.first?.name, validPlan.name)
        } catch {
            // If it throws, it should be a data corruption error
            XCTAssertTrue(error is UserPreferencesError)
        }
    }

    // MARK: - Workout Plan Saving Tests

    func testSavePlan_NewPlan_SavesSuccessfully() async throws {
        // Given
        let plan = self.sampleWorkoutPlan

        // When
        try await self.service.savePlan(plan)

        // Then
        XCTAssertEqual(self.service.savedPlans.count, 1)
        XCTAssertEqual(self.service.savedPlans.first?.id, plan.id)
        XCTAssertEqual(self.service.savedPlans.first?.name, plan.name)
        XCTAssertEqual(self.service.savedPlans.first?.exercises.count, 3)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        // Verify data was saved to Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.count, 1)

        let savedPlan = savedPlans.first!
        XCTAssertEqual(savedPlan.planId, plan.id)
        XCTAssertEqual(savedPlan.name, plan.name)
        XCTAssertEqual(savedPlan.exerciseCount, Int32(plan.exercises.count))
        XCTAssertNotNil(savedPlan.planData)
    }

    func testSavePlan_WithCustomName_UsesCustomName() async throws {
        // Given
        let plan = self.sampleWorkoutPlan
        let customName = "Custom Plan Name"

        // When
        try await service.savePlan(plan, name: customName)

        // Then
        XCTAssertEqual(self.service.savedPlans.first?.name, customName)

        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.first?.name, customName)
    }

    func testSavePlan_ExistingPlan_UpdatesSuccessfully() async throws {
        // Given - Save initial plan
        let originalPlan = self.sampleWorkoutPlan
        try await self.service.savePlan(originalPlan)

        // When - Update the plan
        let updatedPlan = WorkoutPlanData(
            id: originalPlan.id, // Same ID
            name: "Updated Plan Name",
            exercises: [self.sampleExercises[0]], // Fewer exercises
            createdDate: originalPlan.createdDate,
            lastUsedDate: Date()
        )
        try await self.service.savePlan(updatedPlan)

        // Then
        XCTAssertEqual(self.service.savedPlans.count, 1) // Still only one plan
        XCTAssertEqual(self.service.savedPlans.first?.name, "Updated Plan Name")
        XCTAssertEqual(self.service.savedPlans.first?.exercises.count, 1)
        XCTAssertNotNil(self.service.savedPlans.first?.lastUsedDate)

        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.count, 1)
        XCTAssertEqual(savedPlans.first?.name, "Updated Plan Name")
    }

    func testSavePlan_JSONSerialization_WorksCorrectly() async throws {
        // Given
        let plan = self.sampleWorkoutPlan

        // When
        try await self.service.savePlan(plan)

        // Then - Verify JSON serialization by loading and comparing
        try await self.service.loadSavedPlans()
        let loadedPlan = self.service.savedPlans.first!

        XCTAssertEqual(loadedPlan.exercises.count, plan.exercises.count)

        for (original, loaded) in zip(plan.exercises, loadedPlan.exercises) {
            XCTAssertEqual(loaded.name, original.name)
            XCTAssertEqual(loaded.sets, original.sets)
            XCTAssertEqual(loaded.reps, original.reps)
            XCTAssertEqual(loaded.weight, original.weight, accuracy: 0.01)
            XCTAssertEqual(loaded.restTime, original.restTime)
            XCTAssertEqual(loaded.orderIndex, original.orderIndex)
        }
    }

    // MARK: - Workout Plan Management Tests

    func testDeletePlan_ExistingPlan_DeletesSuccessfully() async throws {
        // Given
        let plan = self.sampleWorkoutPlan
        try await self.service.savePlan(plan)

        // When
        try await self.service.deletePlan(plan.id)

        // Then
        XCTAssertTrue(self.service.savedPlans.isEmpty)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        // Verify deletion in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertTrue(savedPlans.isEmpty)
    }

    func testDeletePlan_NonExistentPlan_ThrowsError() async throws {
        // Given
        let nonExistentId = UUID()

        // When & Then
        do {
            try await self.service.deletePlan(nonExistentId)
            XCTFail("Expected error to be thrown")
        } catch let error as UserPreferencesError {
            XCTAssertEqual(error, .planNotFound(id: nonExistentId))
        }
    }

    func testDeletePlan_MultiplePlans_DeletesOnlySpecified() async throws {
        // Given
        let plan1 = self.sampleWorkoutPlan
        let plan2 = WorkoutPlanData(
            id: UUID(),
            name: "Plan 2",
            exercises: [sampleExercises[0]],
            createdDate: Date()
        )

        try await service.savePlan(plan1)
        try await self.service.savePlan(plan2)

        // When
        try await self.service.deletePlan(plan1.id)

        // Then
        XCTAssertEqual(self.service.savedPlans.count, 1)
        XCTAssertEqual(self.service.savedPlans.first?.id, plan2.id)

        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.count, 1)
        XCTAssertEqual(savedPlans.first?.planId, plan2.id)
    }

    func testRenamePlan_ExistingPlan_RenamesSuccessfully() async throws {
        // Given
        let plan = self.sampleWorkoutPlan
        try await self.service.savePlan(plan)
        let newName = "Renamed Plan"

        // When
        try await service.renamePlan(plan.id, newName: newName)

        // Then
        XCTAssertEqual(self.service.savedPlans.first?.name, newName)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.first?.name, newName)
    }

    func testRenamePlan_NonExistentPlan_ThrowsError() async throws {
        // Given
        let nonExistentId = UUID()

        // When & Then
        do {
            try await self.service.renamePlan(nonExistentId, newName: "New Name")
            XCTFail("Expected error to be thrown")
        } catch let error as UserPreferencesError {
            XCTAssertEqual(error, .planNotFound(id: nonExistentId))
        }
    }

    func testMarkPlanAsUsed_ExistingPlan_UpdatesLastUsedDate() async throws {
        // Given
        let plan = self.sampleWorkoutPlan
        try await self.service.savePlan(plan)
        let beforeTime = Date()

        // When
        try await service.markPlanAsUsed(plan.id)

        // Then
        let afterTime = Date()
        let updatedPlan = self.service.savedPlans.first!

        XCTAssertNotNil(updatedPlan.lastUsedDate)
        XCTAssertGreaterThanOrEqual(updatedPlan.lastUsedDate!, beforeTime)
        XCTAssertLessThanOrEqual(updatedPlan.lastUsedDate!, afterTime)
        XCTAssertFalse(self.service.isLoading)
        XCTAssertNil(self.service.lastError)

        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        let savedPlan = savedPlans.first!
        XCTAssertNotNil(savedPlan.lastUsedDate)
        XCTAssertGreaterThanOrEqual(savedPlan.lastUsedDate!, beforeTime)
        XCTAssertLessThanOrEqual(savedPlan.lastUsedDate!, afterTime)
    }

    func testMarkPlanAsUsed_NonExistentPlan_ThrowsError() async throws {
        // Given
        let nonExistentId = UUID()

        // When & Then
        do {
            try await self.service.markPlanAsUsed(nonExistentId)
            XCTFail("Expected error to be thrown")
        } catch let error as UserPreferencesError {
            XCTAssertEqual(error, .planNotFound(id: nonExistentId))
        }
    }

    func testMarkPlanAsUsed_MultipleTimes_UpdatesEachTime() async throws {
        // Given
        let plan = self.sampleWorkoutPlan
        try await self.service.savePlan(plan)

        // When - Mark as used twice with delay
        try await self.service.markPlanAsUsed(plan.id)
        let firstUsedDate = self.service.savedPlans.first?.lastUsedDate

        // Small delay to ensure different timestamps
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms

        try await self.service.markPlanAsUsed(plan.id)
        let secondUsedDate = self.service.savedPlans.first?.lastUsedDate

        // Then
        XCTAssertNotNil(firstUsedDate)
        XCTAssertNotNil(secondUsedDate)
        XCTAssertGreaterThan(secondUsedDate!, firstUsedDate!)
    }

    // MARK: - Workout Plan Integration Tests

    func testPlanManagement_CompleteWorkflow_WorksCorrectly() async throws {
        // Given - Create and save multiple plans
        let plan1 = self.sampleWorkoutPlan
        let plan2 = WorkoutPlanData(
            id: UUID(),
            name: "Cardio Plan",
            exercises: [sampleExercises[1]],
            createdDate: Date().addingTimeInterval(-3_600)
        )

        // When - Save plans
        try await self.service.savePlan(plan1)
        try await self.service.savePlan(plan2)

        // Then - Load and verify
        try await self.service.loadSavedPlans()
        XCTAssertEqual(self.service.savedPlans.count, 2)

        // When - Mark one as used
        try await self.service.markPlanAsUsed(plan2.id)

        // Then - Reload and verify sorting (used plan should be first)
        try await self.service.loadSavedPlans()
        XCTAssertEqual(self.service.savedPlans.first?.id, plan2.id)

        // When - Rename a plan
        try await self.service.renamePlan(plan1.id, newName: "Renamed Strength Plan")

        // Then - Verify rename
        let renamedPlan = self.service.savedPlans.first { $0.id == plan1.id }
        XCTAssertEqual(renamedPlan?.name, "Renamed Strength Plan")

        // When - Delete a plan
        try await self.service.deletePlan(plan1.id)

        // Then - Verify deletion
        XCTAssertEqual(self.service.savedPlans.count, 1)
        XCTAssertEqual(self.service.savedPlans.first?.id, plan2.id)
    }

    func testPlanManagement_ConcurrentOperations_HandledSafely() async throws {
        // Given
        let plans = (0 ..< 5).map { index in
            WorkoutPlanData(
                id: UUID(),
                name: "Plan \(index)",
                exercises: [self.sampleExercises[0]],
                createdDate: Date()
            )
        }

        // When - Save all plans concurrently
        await withTaskGroup(of: Void.self) { group in
            for plan in plans {
                group.addTask {
                    do {
                        try await self.service.savePlan(plan)
                    } catch {
                        XCTFail("Concurrent save failed: \(error)")
                    }
                }
            }
        }

        // Then - Verify all plans were saved
        try await self.service.loadSavedPlans()
        XCTAssertEqual(self.service.savedPlans.count, 5)

        // When - Perform concurrent operations on different plans
        await withTaskGroup(of: Void.self) { group in
            for (index, plan) in plans.enumerated() {
                group.addTask {
                    do {
                        if index % 2 == 0 {
                            try await self.service.markPlanAsUsed(plan.id)
                        } else {
                            try await self.service.renamePlan(plan.id, newName: "Updated Plan \(index)")
                        }
                    } catch {
                        XCTFail("Concurrent operation failed: \(error)")
                    }
                }
            }
        }

        // Then - Verify operations completed successfully
        try await self.service.loadSavedPlans()
        XCTAssertEqual(self.service.savedPlans.count, 5)
        XCTAssertFalse(self.service.isLoading)
    }

    // MARK: - Error Handling Tests

    func testErrorHandling_SetsLastErrorOnFailure() async throws {
        // Given - Create a service with a corrupted persistence controller
        let corruptedController = PersistenceController(inMemory: true)
        let corruptedService = UserPreferencesService(persistenceController: corruptedController)

        // Simulate corruption by removing the store after service creation
        try corruptedController.container.persistentStoreCoordinator.remove(
            corruptedController.container.persistentStoreCoordinator.persistentStores.first!
        )

        // When & Then
        do {
            try await corruptedService.loadSelectedEquipment()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(corruptedService.lastError)
            XCTAssertFalse(corruptedService.isLoading)
        }
    }

    func testLoadingState_SetCorrectlyDuringOperations() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Loading state observed")
        var loadingStates: [Bool] = []

        // Observe loading state changes
        let cancellable = self.service.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }

        // When
        try await self.service.loadSelectedEquipment()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(loadingStates.contains(true)) // Was loading at some point
        XCTAssertFalse(self.service.isLoading) // Not loading at the end

        cancellable.cancel()
    }

    // MARK: - Performance Tests

    func testPerformance_LoadLargeEquipmentSet() async throws {
        // Given - Create large equipment set
        let largeEquipmentSet = (0 ..< 1_000).map { index in
            EquipmentItem(
                id: "equipment-\(index)",
                name: "Equipment \(index)",
                category: "Category \(index % 10)",
                isSelected: index % 2 == 0
            )
        }

        try await self.service.saveEquipmentSelection(largeEquipmentSet)

        // When & Then - Measure performance
        measure {
            Task {
                try await self.service.loadSelectedEquipment()
            }
        }
    }

    func testPerformance_SaveLargeEquipmentSet() async throws {
        // Given - Create large equipment set
        let largeEquipmentSet = (0 ..< 1_000).map { index in
            EquipmentItem(
                id: "equipment-\(index)",
                name: "Equipment \(index)",
                category: "Category \(index % 10)",
                isSelected: index % 2 == 0
            )
        }

        // When & Then - Measure performance
        measure {
            Task {
                try await self.service.saveEquipmentSelection(largeEquipmentSet)
            }
        }
    }

    // MARK: - Concurrent Access Tests

    func testConcurrentAccess_MultipleOperations_HandledSafely() async throws {
        // Given
        let operationCount = 10
        let expectations = (0 ..< operationCount).map { index in
            XCTestExpectation(description: "Operation \(index) completed")
        }

        // When - Perform multiple concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for index in 0 ..< operationCount {
                group.addTask {
                    do {
                        let equipment = [
                            EquipmentItem(
                                id: "concurrent-\(index)",
                                name: "Concurrent \(index)",
                                category: "Test",
                                isSelected: true
                            )
                        ]
                        try await self.service.saveEquipmentSelection(equipment)
                        expectations[index].fulfill()
                    } catch {
                        XCTFail("Concurrent operation \(index) failed: \(error)")
                    }
                }
            }
        }

        // Then
        await fulfillment(of: expectations, timeout: 5.0)
        XCTAssertFalse(self.service.isLoading)
    }
}

// MARK: - Test Helpers

private extension UserPreferencesServiceTests {
    /// Populates test database with sample equipment
    func populateTestEquipment() async throws {
        for equipment in self.sampleEquipment {
            let entity = UserEquipment(context: testContext)
            entity.equipmentId = equipment.id
            entity.name = equipment.name
            entity.category = equipment.category
            entity.isSelected = equipment.isSelected
            entity.dateAdded = Date()
        }

        try self.testContext.save()
    }

    /// Fetches all equipment from Core Data for verification
    func fetchAllEquipmentFromCoreData() async throws -> [UserEquipment] {
        try await withCheckedThrowingContinuation { continuation in
            self.testContext.perform {
                do {
                    let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
                    let equipment = try self.testContext.fetch(request)
                    continuation.resume(returning: equipment)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Fetches all workout plans from Core Data for verification
    func fetchAllPlansFromCoreData() async throws -> [WorkoutPlan] {
        try await withCheckedThrowingContinuation { continuation in
            self.testContext.perform {
                do {
                    let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
                    let plans = try self.testContext.fetch(request)
                    continuation.resume(returning: plans)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Mock Classes for Testing

/// Mock persistence controller that can simulate failures
/// Note: Since PersistenceController is a struct, we use composition instead of inheritance
class MockPersistenceController {
    let persistenceController: PersistenceController
    var shouldFailOnSave = false
    var shouldFailOnFetch = false

    init(inMemory: Bool = true) {
        self.persistenceController = PersistenceController(inMemory: inMemory)
    }

    var container: NSPersistentContainer {
        self.persistenceController.container
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        self.persistenceController.newBackgroundContext()
    }

    func save() {
        if self.shouldFailOnSave {
            fatalError("Simulated save failure")
        }
        self.persistenceController.save()
    }
}

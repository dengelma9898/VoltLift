//
//  UserPreferencesServiceTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import XCTest
import CoreData
@testable import VoltLift

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
            exercises: sampleExercises,
            createdDate: Date(),
            lastUsedDate: nil
        )
    }
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller for testing
        testPersistenceController = PersistenceController(inMemory: true)
        testContext = testPersistenceController.container.viewContext
        
        // Initialize service with test persistence controller
        service = UserPreferencesService(persistenceController: testPersistenceController)
    }
    
    override func tearDown() async throws {
        service = nil
        testPersistenceController = nil
        testContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Equipment Loading Tests
    
    func testLoadSelectedEquipment_EmptyDatabase_ReturnsEmptyArray() async throws {
        // When
        try await service.loadSelectedEquipment()
        
        // Then
        XCTAssertTrue(service.selectedEquipment.isEmpty)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
    }
    
    func testLoadSelectedEquipment_WithData_ReturnsCorrectEquipment() async throws {
        // Given
        try await populateTestEquipment()
        
        // When
        try await service.loadSelectedEquipment()
        
        // Then
        XCTAssertEqual(service.selectedEquipment.count, 4)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
        // Verify equipment is sorted by category then name
        let firstItem = service.selectedEquipment.first!
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
        
        try testContext.save()
        
        // When
        try await service.loadSelectedEquipment()
        
        // Then - Should filter out corrupted data but keep valid data
        XCTAssertEqual(service.selectedEquipment.count, 1)
        XCTAssertEqual(service.selectedEquipment.first?.id, "valid-id")
        XCTAssertFalse(service.isLoading)
    }
    
    // MARK: - Equipment Saving Tests
    
    func testSaveEquipmentSelection_NewEquipment_SavesSuccessfully() async throws {
        // When
        try await service.saveEquipmentSelection(sampleEquipment)
        
        // Then
        XCTAssertEqual(service.selectedEquipment.count, 4)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
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
        try await service.saveEquipmentSelection(sampleEquipment)
        
        // When - Save different equipment
        let newEquipment = [
            EquipmentItem(id: "kettlebell", name: "Kettlebell", category: "Free Weights", isSelected: true)
        ]
        try await service.saveEquipmentSelection(newEquipment)
        
        // Then
        XCTAssertEqual(service.selectedEquipment.count, 1)
        XCTAssertEqual(service.selectedEquipment.first?.id, "kettlebell")
        
        // Verify old data was cleared
        let savedEquipment = try await fetchAllEquipmentFromCoreData()
        XCTAssertEqual(savedEquipment.count, 1)
        XCTAssertNil(savedEquipment.first { $0.equipmentId == "barbell" })
    }
    
    func testSaveEquipmentSelection_EmptyArray_ClearsAllData() async throws {
        // Given - Save initial equipment
        try await service.saveEquipmentSelection(sampleEquipment)
        
        // When - Save empty array
        try await service.saveEquipmentSelection([])
        
        // Then
        XCTAssertTrue(service.selectedEquipment.isEmpty)
        
        // Verify data was cleared from Core Data
        let savedEquipment = try await fetchAllEquipmentFromCoreData()
        XCTAssertTrue(savedEquipment.isEmpty)
    }
    
    // MARK: - Equipment Update Tests
    
    func testUpdateEquipmentSelection_ExistingEquipment_UpdatesSuccessfully() async throws {
        // Given
        try await service.saveEquipmentSelection(sampleEquipment)
        let benchEquipment = sampleEquipment.first { $0.id == "bench" }!
        
        // When - Update bench from unselected to selected
        try await service.updateEquipmentSelection(benchEquipment, isSelected: true)
        
        // Then
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
        let updatedBench = service.selectedEquipment.first { $0.id == "bench" }
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
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
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
        XCTAssertFalse(service.hasCompletedSetup)
        XCTAssertNil(service.lastError)
    }
    
    func testCheckSetupCompletion_WithSelectedEquipment_ReturnsTrue() async throws {
        // Given
        try await service.saveEquipmentSelection(sampleEquipment)
        
        // When
        let isComplete = try await service.checkSetupCompletion()
        
        // Then
        XCTAssertTrue(isComplete)
        XCTAssertTrue(service.hasCompletedSetup)
        XCTAssertNil(service.lastError)
    }
    
    func testCheckSetupCompletion_WithUnselectedEquipment_ReturnsFalse() async throws {
        // Given - Equipment exists but none are selected
        let unselectedEquipment = sampleEquipment.map { 
            EquipmentItem(id: $0.id, name: $0.name, category: $0.category, isSelected: false)
        }
        try await service.saveEquipmentSelection(unselectedEquipment)
        
        // When
        let isComplete = try await service.checkSetupCompletion()
        
        // Then
        XCTAssertFalse(isComplete)
        XCTAssertFalse(service.hasCompletedSetup)
    }
    
    func testMarkSetupComplete_WithSelectedEquipment_Succeeds() async throws {
        // Given
        try await service.saveEquipmentSelection(sampleEquipment)
        
        // When
        try await service.markSetupComplete()
        
        // Then
        XCTAssertTrue(service.hasCompletedSetup)
        XCTAssertNil(service.lastError)
    }
    
    func testMarkSetupComplete_WithoutSelectedEquipment_ThrowsError() async throws {
        // When & Then
        do {
            try await service.markSetupComplete()
            XCTFail("Expected error to be thrown")
        } catch let error as UserPreferencesError {
            XCTAssertEqual(error, .invalidData(field: "equipment selection"))
            XCTAssertFalse(service.hasCompletedSetup)
        }
    }
    
    // MARK: - Workout Plan Loading Tests
    
    func testLoadSavedPlans_EmptyDatabase_ReturnsEmptyArray() async throws {
        // When
        try await service.loadSavedPlans()
        
        // Then
        XCTAssertTrue(service.savedPlans.isEmpty)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
    }
    
    func testLoadSavedPlans_WithData_ReturnsCorrectPlans() async throws {
        // Given
        let plan1 = sampleWorkoutPlan
        let plan2 = WorkoutPlanData(
            id: UUID(),
            name: "Lower Body Power",
            exercises: [sampleExercises[1]], // Just squats
            createdDate: Date().addingTimeInterval(-86400), // Yesterday
            lastUsedDate: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        try await service.savePlan(plan1)
        try await service.savePlan(plan2)
        
        // When
        try await service.loadSavedPlans()
        
        // Then
        XCTAssertEqual(service.savedPlans.count, 2)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
        // Verify plans are sorted by last used date (most recent first), then created date
        let firstPlan = service.savedPlans.first!
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
        let validPlan = sampleWorkoutPlan
        try await service.savePlan(validPlan)
        
        try testContext.save()
        
        // When & Then - Should handle corrupted data gracefully
        do {
            try await service.loadSavedPlans()
            // Should have filtered out corrupted data but kept valid data
            XCTAssertEqual(service.savedPlans.count, 1)
            XCTAssertEqual(service.savedPlans.first?.name, validPlan.name)
        } catch {
            // If it throws, it should be a data corruption error
            XCTAssertTrue(error is UserPreferencesError)
        }
    }
    
    // MARK: - Workout Plan Saving Tests
    
    func testSavePlan_NewPlan_SavesSuccessfully() async throws {
        // Given
        let plan = sampleWorkoutPlan
        
        // When
        try await service.savePlan(plan)
        
        // Then
        XCTAssertEqual(service.savedPlans.count, 1)
        XCTAssertEqual(service.savedPlans.first?.id, plan.id)
        XCTAssertEqual(service.savedPlans.first?.name, plan.name)
        XCTAssertEqual(service.savedPlans.first?.exercises.count, 3)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
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
        let plan = sampleWorkoutPlan
        let customName = "Custom Plan Name"
        
        // When
        try await service.savePlan(plan, name: customName)
        
        // Then
        XCTAssertEqual(service.savedPlans.first?.name, customName)
        
        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.first?.name, customName)
    }
    
    func testSavePlan_ExistingPlan_UpdatesSuccessfully() async throws {
        // Given - Save initial plan
        let originalPlan = sampleWorkoutPlan
        try await service.savePlan(originalPlan)
        
        // When - Update the plan
        let updatedPlan = WorkoutPlanData(
            id: originalPlan.id, // Same ID
            name: "Updated Plan Name",
            exercises: [sampleExercises[0]], // Fewer exercises
            createdDate: originalPlan.createdDate,
            lastUsedDate: Date()
        )
        try await service.savePlan(updatedPlan)
        
        // Then
        XCTAssertEqual(service.savedPlans.count, 1) // Still only one plan
        XCTAssertEqual(service.savedPlans.first?.name, "Updated Plan Name")
        XCTAssertEqual(service.savedPlans.first?.exercises.count, 1)
        XCTAssertNotNil(service.savedPlans.first?.lastUsedDate)
        
        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.count, 1)
        XCTAssertEqual(savedPlans.first?.name, "Updated Plan Name")
    }
    
    func testSavePlan_JSONSerialization_WorksCorrectly() async throws {
        // Given
        let plan = sampleWorkoutPlan
        
        // When
        try await service.savePlan(plan)
        
        // Then - Verify JSON serialization by loading and comparing
        try await service.loadSavedPlans()
        let loadedPlan = service.savedPlans.first!
        
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
        let plan = sampleWorkoutPlan
        try await service.savePlan(plan)
        
        // When
        try await service.deletePlan(plan.id)
        
        // Then
        XCTAssertTrue(service.savedPlans.isEmpty)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
        // Verify deletion in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertTrue(savedPlans.isEmpty)
    }
    
    func testDeletePlan_NonExistentPlan_ThrowsError() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When & Then
        do {
            try await service.deletePlan(nonExistentId)
            XCTFail("Expected error to be thrown")
        } catch let error as UserPreferencesError {
            XCTAssertEqual(error, .planNotFound(id: nonExistentId))
        }
    }
    
    func testDeletePlan_MultiplePlans_DeletesOnlySpecified() async throws {
        // Given
        let plan1 = sampleWorkoutPlan
        let plan2 = WorkoutPlanData(
            id: UUID(),
            name: "Plan 2",
            exercises: [sampleExercises[0]],
            createdDate: Date()
        )
        
        try await service.savePlan(plan1)
        try await service.savePlan(plan2)
        
        // When
        try await service.deletePlan(plan1.id)
        
        // Then
        XCTAssertEqual(service.savedPlans.count, 1)
        XCTAssertEqual(service.savedPlans.first?.id, plan2.id)
        
        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.count, 1)
        XCTAssertEqual(savedPlans.first?.planId, plan2.id)
    }
    
    func testRenamePlan_ExistingPlan_RenamesSuccessfully() async throws {
        // Given
        let plan = sampleWorkoutPlan
        try await service.savePlan(plan)
        let newName = "Renamed Plan"
        
        // When
        try await service.renamePlan(plan.id, newName: newName)
        
        // Then
        XCTAssertEqual(service.savedPlans.first?.name, newName)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
        // Verify in Core Data
        let savedPlans = try await fetchAllPlansFromCoreData()
        XCTAssertEqual(savedPlans.first?.name, newName)
    }
    
    func testRenamePlan_NonExistentPlan_ThrowsError() async throws {
        // Given
        let nonExistentId = UUID()
        
        // When & Then
        do {
            try await service.renamePlan(nonExistentId, newName: "New Name")
            XCTFail("Expected error to be thrown")
        } catch let error as UserPreferencesError {
            XCTAssertEqual(error, .planNotFound(id: nonExistentId))
        }
    }
    
    func testMarkPlanAsUsed_ExistingPlan_UpdatesLastUsedDate() async throws {
        // Given
        let plan = sampleWorkoutPlan
        try await service.savePlan(plan)
        let beforeTime = Date()
        
        // When
        try await service.markPlanAsUsed(plan.id)
        
        // Then
        let afterTime = Date()
        let updatedPlan = service.savedPlans.first!
        
        XCTAssertNotNil(updatedPlan.lastUsedDate)
        XCTAssertGreaterThanOrEqual(updatedPlan.lastUsedDate!, beforeTime)
        XCTAssertLessThanOrEqual(updatedPlan.lastUsedDate!, afterTime)
        XCTAssertFalse(service.isLoading)
        XCTAssertNil(service.lastError)
        
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
            try await service.markPlanAsUsed(nonExistentId)
            XCTFail("Expected error to be thrown")
        } catch let error as UserPreferencesError {
            XCTAssertEqual(error, .planNotFound(id: nonExistentId))
        }
    }
    
    func testMarkPlanAsUsed_MultipleTimes_UpdatesEachTime() async throws {
        // Given
        let plan = sampleWorkoutPlan
        try await service.savePlan(plan)
        
        // When - Mark as used twice with delay
        try await service.markPlanAsUsed(plan.id)
        let firstUsedDate = service.savedPlans.first?.lastUsedDate
        
        // Small delay to ensure different timestamps
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        try await service.markPlanAsUsed(plan.id)
        let secondUsedDate = service.savedPlans.first?.lastUsedDate
        
        // Then
        XCTAssertNotNil(firstUsedDate)
        XCTAssertNotNil(secondUsedDate)
        XCTAssertGreaterThan(secondUsedDate!, firstUsedDate!)
    }
    
    // MARK: - Workout Plan Integration Tests
    
    func testPlanManagement_CompleteWorkflow_WorksCorrectly() async throws {
        // Given - Create and save multiple plans
        let plan1 = sampleWorkoutPlan
        let plan2 = WorkoutPlanData(
            id: UUID(),
            name: "Cardio Plan",
            exercises: [sampleExercises[1]],
            createdDate: Date().addingTimeInterval(-3600)
        )
        
        // When - Save plans
        try await service.savePlan(plan1)
        try await service.savePlan(plan2)
        
        // Then - Load and verify
        try await service.loadSavedPlans()
        XCTAssertEqual(service.savedPlans.count, 2)
        
        // When - Mark one as used
        try await service.markPlanAsUsed(plan2.id)
        
        // Then - Reload and verify sorting (used plan should be first)
        try await service.loadSavedPlans()
        XCTAssertEqual(service.savedPlans.first?.id, plan2.id)
        
        // When - Rename a plan
        try await service.renamePlan(plan1.id, newName: "Renamed Strength Plan")
        
        // Then - Verify rename
        let renamedPlan = service.savedPlans.first { $0.id == plan1.id }
        XCTAssertEqual(renamedPlan?.name, "Renamed Strength Plan")
        
        // When - Delete a plan
        try await service.deletePlan(plan1.id)
        
        // Then - Verify deletion
        XCTAssertEqual(service.savedPlans.count, 1)
        XCTAssertEqual(service.savedPlans.first?.id, plan2.id)
    }
    
    func testPlanManagement_ConcurrentOperations_HandledSafely() async throws {
        // Given
        let plans = (0..<5).map { index in
            WorkoutPlanData(
                id: UUID(),
                name: "Plan \(index)",
                exercises: [sampleExercises[0]],
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
        try await service.loadSavedPlans()
        XCTAssertEqual(service.savedPlans.count, 5)
        
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
        try await service.loadSavedPlans()
        XCTAssertEqual(service.savedPlans.count, 5)
        XCTAssertFalse(service.isLoading)
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
        let cancellable = service.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 2 {
                    expectation.fulfill()
                }
            }
        
        // When
        try await service.loadSelectedEquipment()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(loadingStates.contains(true)) // Was loading at some point
        XCTAssertFalse(service.isLoading) // Not loading at the end
        
        cancellable.cancel()
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_LoadLargeEquipmentSet() async throws {
        // Given - Create large equipment set
        let largeEquipmentSet = (0..<1000).map { index in
            EquipmentItem(
                id: "equipment-\(index)",
                name: "Equipment \(index)",
                category: "Category \(index % 10)",
                isSelected: index % 2 == 0
            )
        }
        
        try await service.saveEquipmentSelection(largeEquipmentSet)
        
        // When & Then - Measure performance
        measure {
            Task {
                try await service.loadSelectedEquipment()
            }
        }
    }
    
    func testPerformance_SaveLargeEquipmentSet() async throws {
        // Given - Create large equipment set
        let largeEquipmentSet = (0..<1000).map { index in
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
                try await service.saveEquipmentSelection(largeEquipmentSet)
            }
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentAccess_MultipleOperations_HandledSafely() async throws {
        // Given
        let operationCount = 10
        let expectations = (0..<operationCount).map { index in
            XCTestExpectation(description: "Operation \(index) completed")
        }
        
        // When - Perform multiple concurrent operations
        await withTaskGroup(of: Void.self) { group in
            for index in 0..<operationCount {
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
        XCTAssertFalse(service.isLoading)
    }
}

// MARK: - Test Helpers

private extension UserPreferencesServiceTests {
    
    /// Populates test database with sample equipment
    func populateTestEquipment() async throws {
        for equipment in sampleEquipment {
            let entity = UserEquipment(context: testContext)
            entity.equipmentId = equipment.id
            entity.name = equipment.name
            entity.category = equipment.category
            entity.isSelected = equipment.isSelected
            entity.dateAdded = Date()
        }
        
        try testContext.save()
    }
    
    /// Fetches all equipment from Core Data for verification
    func fetchAllEquipmentFromCoreData() async throws -> [UserEquipment] {
        return try await withCheckedThrowingContinuation { continuation in
            testContext.perform {
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
        return try await withCheckedThrowingContinuation { continuation in
            testContext.perform {
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
        return persistenceController.container
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        return persistenceController.newBackgroundContext()
    }
    
    func save() {
        if shouldFailOnSave {
            fatalError("Simulated save failure")
        }
        persistenceController.save()
    }
}
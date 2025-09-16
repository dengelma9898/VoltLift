//
//  PersistenceSystemIntegrationTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

/// Comprehensive integration tests for the complete persistence system
/// Tests end-to-end workflows combining equipment selection and workout plan management
@MainActor
final class PersistenceSystemIntegrationTests: XCTestCase {
    // MARK: - Properties

    private var userPreferencesService: UserPreferencesService!
    private var persistenceController: PersistenceController!
    private var testDataFactory: TestDataFactory!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory persistence controller for testing
        self.persistenceController = PersistenceController(inMemory: true)
        self.userPreferencesService = UserPreferencesService(persistenceController: self.persistenceController)
        self.testDataFactory = TestDataFactory()
    }

    override func tearDown() async throws {
        await self.testDataFactory.cleanup()
        self.userPreferencesService = nil
        self.persistenceController = nil
        self.testDataFactory = nil
        try await super.tearDown()
    }

    // MARK: - Complete User Journey Tests

    /// Tests the complete user journey from first app launch to workout plan usage
    func testCompleteUserJourney() async throws {
        // Given: New user launches app for first time
        let isSetupComplete = try await userPreferencesService.checkSetupCompletion()
        XCTAssertFalse(isSetupComplete, "Setup should not be complete for new user")

        // When: User selects equipment during onboarding
        let selectedEquipment = self.testDataFactory.createEquipmentSelection()
        try await self.userPreferencesService.saveEquipmentSelection(selectedEquipment)

        // Then: Setup should be marked as complete
        let isSetupCompleteAfterEquipment = try await userPreferencesService.checkSetupCompletion()
        XCTAssertTrue(isSetupCompleteAfterEquipment, "Setup should be complete after equipment selection")

        // When: User creates their first workout plan
        let firstPlan = self.testDataFactory.createWorkoutPlan(name: "My First Workout")
        try await self.userPreferencesService.savePlan(firstPlan)

        // Then: Plan should be saved and available
        try await self.userPreferencesService.loadSavedPlans()
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, 1)
        XCTAssertEqual(self.userPreferencesService.savedPlans.first?.name, "My First Workout")

        // When: User starts a workout using the saved plan
        try await self.userPreferencesService.markPlanAsUsed(firstPlan.id)

        // Then: Plan usage should be tracked
        try await self.userPreferencesService.loadSavedPlans()
        let usedPlan = self.userPreferencesService.savedPlans.first!
        XCTAssertNotNil(usedPlan.lastUsedDate, "Plan should have last used date")

        // When: User creates additional plans
        let additionalPlans = self.testDataFactory.createMultipleWorkoutPlans(count: 3)
        for plan in additionalPlans {
            try await self.userPreferencesService.savePlan(plan)
        }

        // Then: All plans should be available and properly ordered
        try await self.userPreferencesService.loadSavedPlans()
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, 4)

        // Most recently used plan should be first
        XCTAssertEqual(self.userPreferencesService.savedPlans.first?.name, "My First Workout")
        XCTAssertNotNil(self.userPreferencesService.savedPlans.first?.lastUsedDate)
    }

    /// Tests equipment modification workflow after initial setup
    func testEquipmentModificationWorkflow() async throws {
        // Given: User has completed initial setup
        let initialEquipment = self.testDataFactory.createEquipmentSelection()
        try await self.userPreferencesService.saveEquipmentSelection(initialEquipment)

        // And: User has created workout plans based on initial equipment
        let plansBasedOnEquipment = self.testDataFactory.createWorkoutPlansForEquipment(initialEquipment)
        for plan in plansBasedOnEquipment {
            try await self.userPreferencesService.savePlan(plan)
        }

        // When: User modifies their equipment selection
        let modifiedEquipment = self.testDataFactory.modifyEquipmentSelection(initialEquipment)
        try await self.userPreferencesService.saveEquipmentSelection(modifiedEquipment)

        // Then: Equipment changes should be persisted
        try await self.userPreferencesService.loadSelectedEquipment()
        let loadedEquipment = self.userPreferencesService.selectedEquipment

        let selectedCount = loadedEquipment.count(where: { $0.isSelected })
        let expectedSelectedCount = modifiedEquipment.count(where: { $0.isSelected })
        XCTAssertEqual(selectedCount, expectedSelectedCount, "Modified equipment selection should be persisted")

        // And: Existing workout plans should remain intact
        try await self.userPreferencesService.loadSavedPlans()
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, plansBasedOnEquipment.count)

        // When: User creates new plans with modified equipment
        let newPlansWithModifiedEquipment = self.testDataFactory.createWorkoutPlansForEquipment(modifiedEquipment)
        for plan in newPlansWithModifiedEquipment {
            try await self.userPreferencesService.savePlan(plan)
        }

        // Then: All plans should coexist
        try await self.userPreferencesService.loadSavedPlans()
        let totalExpectedPlans = plansBasedOnEquipment.count + newPlansWithModifiedEquipment.count
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, totalExpectedPlans)
    }

    /// Tests plan management workflow with various operations
    func testPlanManagementWorkflow() async throws {
        // Given: User has equipment set up
        let equipment = self.testDataFactory.createEquipmentSelection()
        try await self.userPreferencesService.saveEquipmentSelection(equipment)

        // And: User has created multiple workout plans
        let originalPlans = self.testDataFactory.createMultipleWorkoutPlans(count: 5)
        for plan in originalPlans {
            try await self.userPreferencesService.savePlan(plan)
        }

        // When: User renames a plan
        let planToRename = originalPlans[0]
        let newName = "Renamed Workout Plan"
        try await userPreferencesService.renamePlan(planToRename.id, newName: newName)

        // Then: Plan should be renamed while preserving other data
        try await self.userPreferencesService.loadSavedPlans()
        let renamedPlan = self.userPreferencesService.savedPlans.first { $0.id == planToRename.id }
        XCTAssertNotNil(renamedPlan, "Renamed plan should still exist")
        XCTAssertEqual(renamedPlan?.name, newName, "Plan should have new name")
        XCTAssertEqual(renamedPlan?.exercises.count, planToRename.exercises.count, "Exercises should be preserved")

        // When: User uses several plans
        let plansToUse = Array(originalPlans.prefix(3))
        for plan in plansToUse {
            try await self.userPreferencesService.markPlanAsUsed(plan.id)
            // Add small delay to ensure different timestamps
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        // Then: Plans should be ordered by usage
        try await self.userPreferencesService.loadSavedPlans()
        let usedPlans = self.userPreferencesService.savedPlans.filter { $0.lastUsedDate != nil }
        XCTAssertEqual(usedPlans.count, 3, "Three plans should have usage dates")

        // Most recently used should be first
        let sortedByUsage = usedPlans.sorted {
            ($0.lastUsedDate ?? Date.distantPast) > ($1.lastUsedDate ?? Date.distantPast)
        }
        XCTAssertEqual(usedPlans, sortedByUsage, "Plans should be ordered by usage date")

        // When: User deletes some plans
        let plansToDelete = Array(originalPlans.suffix(2))
        for plan in plansToDelete {
            try await self.userPreferencesService.deletePlan(plan.id)
        }

        // Then: Deleted plans should be removed
        try await self.userPreferencesService.loadSavedPlans()
        let remainingPlanIds = Set(userPreferencesService.savedPlans.map(\.id))
        let deletedPlanIds = Set(plansToDelete.map(\.id))

        XCTAssertTrue(remainingPlanIds.isDisjoint(with: deletedPlanIds), "Deleted plans should not exist")
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, 3, "Should have 3 remaining plans")
    }

    // MARK: - Cross-Session Persistence Tests

    /// Tests that data persists correctly across simulated app sessions
    func testCrossSessionPersistence() async throws {
        // Session 1: Initial setup and data creation
        let session1Equipment = self.testDataFactory.createEquipmentSelection()
        let session1Plans = self.testDataFactory.createMultipleWorkoutPlans(count: 3)

        try await self.userPreferencesService.saveEquipmentSelection(session1Equipment)
        for plan in session1Plans {
            try await self.userPreferencesService.savePlan(plan)
        }
        try await self.userPreferencesService.markPlanAsUsed(session1Plans[0].id)

        // Simulate app termination by creating new service instance
        let session2Service = UserPreferencesService(persistenceController: persistenceController)

        // Session 2: Verify data persistence
        try await session2Service.loadSelectedEquipment()
        try await session2Service.loadSavedPlans()

        // Equipment should be preserved
        let session2Equipment = session2Service.selectedEquipment
        XCTAssertEqual(session2Equipment.count, session1Equipment.count)

        let session1SelectedIds = Set(session1Equipment.filter(\.isSelected).map(\.id))
        let session2SelectedIds = Set(session2Equipment.filter(\.isSelected).map(\.id))
        XCTAssertEqual(session1SelectedIds, session2SelectedIds, "Equipment selection should persist")

        // Plans should be preserved
        XCTAssertEqual(session2Service.savedPlans.count, session1Plans.count)

        let session1PlanIds = Set(session1Plans.map(\.id))
        let session2PlanIds = Set(session2Service.savedPlans.map(\.id))
        XCTAssertEqual(session1PlanIds, session2PlanIds, "Plan IDs should persist")

        // Usage data should be preserved
        let usedPlan = session2Service.savedPlans.first { $0.id == session1Plans[0].id }
        XCTAssertNotNil(usedPlan?.lastUsedDate, "Plan usage should persist across sessions")

        // Session 2: Make modifications
        let newPlan = self.testDataFactory.createWorkoutPlan(name: "Session 2 Plan")
        try await session2Service.savePlan(newPlan)

        let equipmentUpdate = self.testDataFactory.createEquipmentItem(id: "new-equipment", isSelected: true)
        try await session2Service.updateEquipmentSelection(equipmentUpdate, isSelected: true)

        // Simulate another app restart
        let session3Service = UserPreferencesService(persistenceController: persistenceController)

        // Session 3: Verify all changes persist
        try await session3Service.loadSelectedEquipment()
        try await session3Service.loadSavedPlans()

        XCTAssertEqual(session3Service.savedPlans.count, session1Plans.count + 1, "New plan should persist")

        let newEquipmentExists = session3Service.selectedEquipment
            .contains { $0.id == "new-equipment" && $0.isSelected }
        XCTAssertTrue(newEquipmentExists, "New equipment should persist")
    }

    // MARK: - Data Integrity Tests

    /// Tests data integrity across various operations
    func testDataIntegrityMaintenance() async throws {
        // Given: Complex data setup
        let equipment = self.testDataFactory.createLargeEquipmentSet(count: 50)
        let plans = self.testDataFactory.createMultipleWorkoutPlans(count: 20)

        try await self.userPreferencesService.saveEquipmentSelection(equipment)
        for plan in plans {
            try await self.userPreferencesService.savePlan(plan)
        }

        // When: Performing many concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Concurrent plan usage updates
            for plan in Array(plans.prefix(10)) {
                group.addTask {
                    do {
                        try await self.userPreferencesService.markPlanAsUsed(plan.id)
                    } catch {
                        XCTFail("Concurrent plan usage failed: \(error)")
                    }
                }
            }

            // Concurrent equipment updates
            for equipment in Array(equipment.prefix(10)) {
                group.addTask {
                    do {
                        try await self.userPreferencesService.updateEquipmentSelection(
                            equipment,
                            isSelected: !equipment.isSelected
                        )
                    } catch {
                        XCTFail("Concurrent equipment update failed: \(error)")
                    }
                }
            }

            // Concurrent plan renames
            for (index, plan) in Array(plans.suffix(5)).enumerated() {
                group.addTask {
                    do {
                        try await self.userPreferencesService.renamePlan(
                            plan.id,
                            newName: "Concurrent Rename \(index)"
                        )
                    } catch {
                        XCTFail("Concurrent plan rename failed: \(error)")
                    }
                }
            }
        }

        // Then: Data should remain consistent
        try await self.userPreferencesService.loadSelectedEquipment()
        try await self.userPreferencesService.loadSavedPlans()

        // Verify no data corruption
        XCTAssertEqual(self.userPreferencesService.selectedEquipment.count, equipment.count)
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, plans.count)

        // Verify all plans have valid data
        for plan in self.userPreferencesService.savedPlans {
            XCTAssertFalse(plan.name.isEmpty, "Plan name should not be empty")
            XCTAssertFalse(plan.exercises.isEmpty, "Plan should have exercises")
            XCTAssertNotEqual(plan.id, UUID(), "Plan should have valid ID")
        }

        // Verify all equipment has valid data
        for equipment in self.userPreferencesService.selectedEquipment {
            XCTAssertFalse(equipment.id.isEmpty, "Equipment ID should not be empty")
            XCTAssertFalse(equipment.name.isEmpty, "Equipment name should not be empty")
        }
    }

    // MARK: - Error Recovery Tests

    /// Tests system recovery from various error conditions
    func testErrorRecoveryScenarios() async throws {
        // Given: Valid initial data
        let equipment = self.testDataFactory.createEquipmentSelection()
        let plans = self.testDataFactory.createMultipleWorkoutPlans(count: 3)

        try await self.userPreferencesService.saveEquipmentSelection(equipment)
        for plan in plans {
            try await self.userPreferencesService.savePlan(plan)
        }

        // When: Attempting operations on non-existent data
        let nonExistentPlanId = UUID()

        do {
            try await self.userPreferencesService.markPlanAsUsed(nonExistentPlanId)
            XCTFail("Should throw error for non-existent plan")
        } catch let error as UserPreferencesError {
            if case let .planNotFound(id) = error {
                XCTAssertEqual(id, nonExistentPlanId)
            } else {
                XCTFail("Expected planNotFound error, got \(error)")
            }
        }

        do {
            try await self.userPreferencesService.renamePlan(nonExistentPlanId, newName: "New Name")
            XCTFail("Should throw error for non-existent plan")
        } catch is UserPreferencesError {
            // Expected error
        }

        do {
            try await self.userPreferencesService.deletePlan(nonExistentPlanId)
            XCTFail("Should throw error for non-existent plan")
        } catch is UserPreferencesError {
            // Expected error
        }

        // Then: Valid data should remain unaffected
        try await self.userPreferencesService.loadSelectedEquipment()
        try await self.userPreferencesService.loadSavedPlans()

        XCTAssertEqual(self.userPreferencesService.selectedEquipment.count, equipment.count)
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, plans.count)

        // When: Attempting invalid operations
        do {
            try await self.userPreferencesService.renamePlan(plans[0].id, newName: "")
            XCTFail("Should throw error for empty plan name")
        } catch is UserPreferencesError {
            // Expected error
        }

        // Then: Original data should be preserved
        try await self.userPreferencesService.loadSavedPlans()
        let originalPlan = self.userPreferencesService.savedPlans.first { $0.id == plans[0].id }
        XCTAssertEqual(originalPlan?.name, plans[0].name, "Original plan name should be preserved")
    }

    // MARK: - Performance Integration Tests

    /// Tests system performance with realistic data loads
    func testRealisticPerformanceScenarios() async throws {
        // Given: Realistic data volumes
        let equipment = self.testDataFactory.createLargeEquipmentSet(count: 100)
        let plans = self.testDataFactory.createMultipleWorkoutPlans(count: 50)

        // When: Performing bulk operations
        let bulkSaveStartTime = CFAbsoluteTimeGetCurrent()

        try await userPreferencesService.saveEquipmentSelection(equipment)
        for plan in plans {
            try await self.userPreferencesService.savePlan(plan)
        }

        let bulkSaveEndTime = CFAbsoluteTimeGetCurrent()
        let bulkSaveTime = bulkSaveEndTime - bulkSaveStartTime

        // Then: Operations should complete in reasonable time
        XCTAssertLessThan(bulkSaveTime, 30.0, "Bulk save should complete within 30 seconds")

        // When: Performing frequent access operations
        let accessStartTime = CFAbsoluteTimeGetCurrent()

        for _ in 0 ..< 10 {
            try await self.userPreferencesService.loadSelectedEquipment()
            try await self.userPreferencesService.loadSavedPlans()
        }

        let accessEndTime = CFAbsoluteTimeGetCurrent()
        let accessTime = accessEndTime - accessStartTime

        // Then: Access should be fast
        XCTAssertLessThan(accessTime, 5.0, "Repeated access should be fast")

        // When: Performing mixed operations
        let mixedOpsStartTime = CFAbsoluteTimeGetCurrent()

        for i in 0 ..< 20 {
            let plan = plans[i % plans.count]
            try await self.userPreferencesService.markPlanAsUsed(plan.id)

            if i % 5 == 0 {
                try await self.userPreferencesService.loadSavedPlans()
            }
        }

        let mixedOpsEndTime = CFAbsoluteTimeGetCurrent()
        let mixedOpsTime = mixedOpsEndTime - mixedOpsStartTime

        // Then: Mixed operations should be efficient
        XCTAssertLessThan(mixedOpsTime, 10.0, "Mixed operations should complete efficiently")

        print("Performance Results:")
        print("- Bulk save time: \(bulkSaveTime)s")
        print("- Access time: \(accessTime)s")
        print("- Mixed operations time: \(mixedOpsTime)s")
    }
}

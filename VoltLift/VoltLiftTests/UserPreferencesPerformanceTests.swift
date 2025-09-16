//
//  UserPreferencesPerformanceTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

/// Performance tests for UserPreferencesService
final class UserPreferencesPerformanceTests: XCTestCase {
    var service: UserPreferencesService!
    var persistenceController: PersistenceController!

    override func setUp() async throws {
        try await super.setUp()
        self.persistenceController = PersistenceController(inMemory: true)
        self.service = await UserPreferencesService(persistenceController: self.persistenceController)
    }

    override func tearDown() {
        self.service = nil
        self.persistenceController = nil
        super.tearDown()
    }

    // MARK: - Plan Management Performance Tests

    func testPlanSavePerformance() async throws {
        // Create test plans
        let testPlans = self.createTestPlans(count: 50)

        // Measure time to save multiple plans
        let startTime = CFAbsoluteTimeGetCurrent()

        for plan in testPlans {
            try await self.service.savePlan(plan)
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime

        // Should complete within reasonable time (2 seconds for 50 plans)
        XCTAssertLessThan(totalTime, 2.0, "Saving 50 plans should complete within 2 seconds")

        // Verify all plans were saved
        try await self.service.loadSavedPlans()
        let savedPlansCount = await service.savedPlans.count
        XCTAssertEqual(savedPlansCount, 50)
    }

    func testPlanLoadPerformance() async throws {
        // Create and save test plans
        let testPlans = self.createTestPlans(count: 20)

        for plan in testPlans {
            try await self.service.savePlan(plan)
        }

        // Measure time to load all plans
        let startTime = CFAbsoluteTimeGetCurrent()
        try await service.loadSavedPlans()
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime

        // Should complete within reasonable time
        XCTAssertLessThan(totalTime, 1.0, "Loading 20 plans should complete within 1 second")

        // Verify all plans were loaded
        let savedPlansCount = await service.savedPlans.count
        XCTAssertEqual(savedPlansCount, 20)

        print("Plan load time: \(totalTime)s")
    }

    func testEquipmentSavePerformance() async throws {
        // Create test equipment
        let testEquipment = self.createTestEquipment(count: 100)

        // Measure time to save equipment
        let startTime = CFAbsoluteTimeGetCurrent()
        try await service.saveEquipmentSelection(testEquipment)
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime

        // Should complete within reasonable time
        XCTAssertLessThan(totalTime, 1.0, "Saving 100 equipment items should complete within 1 second")

        // Verify equipment was saved
        try await self.service.loadSelectedEquipment()
        let selectedEquipmentCount = await service.selectedEquipment.count
        XCTAssertEqual(selectedEquipmentCount, 100)

        print("Equipment save time: \(totalTime)s")
    }

    func testPlanDeletePerformance() async throws {
        // Create and save test plans
        let testPlans = self.createTestPlans(count: 30)

        for plan in testPlans {
            try await self.service.savePlan(plan)
        }

        // Measure time to delete plans
        let startTime = CFAbsoluteTimeGetCurrent()

        for plan in testPlans {
            try await self.service.deletePlan(plan.id)
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime

        // Should complete within reasonable time
        XCTAssertLessThan(totalTime, 2.0, "Deleting 30 plans should complete within 2 seconds")

        // Verify plans were deleted
        try await self.service.loadSavedPlans()
        let savedPlansCount = await service.savedPlans.count
        XCTAssertEqual(savedPlansCount, 0)

        print("Plan delete time: \(totalTime)s")
    }

    func testSetupCompletionPerformance() async throws {
        // Create test equipment
        let testEquipment = self.createTestEquipment(count: 50)
        try await self.service.saveEquipmentSelection(testEquipment)

        // Measure setup completion check time
        let startTime = CFAbsoluteTimeGetCurrent()
        let isComplete = try await service.checkSetupCompletion()
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime

        // Should be very fast
        XCTAssertLessThan(totalTime, 0.1, "Setup completion check should be under 0.1 seconds")
        XCTAssertTrue(isComplete)

        print("Setup completion check time: \(totalTime)s")
    }

    // MARK: - Helper Methods

    private func createTestPlans(count: Int, startIndex: Int = 0) -> [WorkoutPlanData] {
        (startIndex ..< (startIndex + count)).map { index in
            let exercises = self.createTestExercises(count: 3, planIndex: index)
            return WorkoutPlanData(
                name: "Test Plan \(index)",
                exercises: exercises
            )
        }
    }

    private func createTestExercises(count: Int, planIndex: Int) -> [ExerciseData] {
        (0 ..< count).map { exerciseIndex in
            ExerciseData(
                name: "Exercise \(planIndex)-\(exerciseIndex)",
                sets: Int.random(in: 3 ... 5),
                reps: Int.random(in: 8 ... 15),
                weight: Double.random(in: 20 ... 100),
                restTime: Int.random(in: 60 ... 180),
                orderIndex: exerciseIndex
            )
        }
    }

    private func createTestEquipment(count: Int, startIndex: Int = 0) -> [EquipmentItem] {
        let categories = ["Cardio", "Strength", "Flexibility", "Functional"]

        return (startIndex ..< (startIndex + count)).map { index in
            EquipmentItem(
                id: "equipment_\(index)",
                name: "Equipment \(index)",
                category: categories[index % categories.count],
                isSelected: index % 2 == 0
            )
        }
    }
}

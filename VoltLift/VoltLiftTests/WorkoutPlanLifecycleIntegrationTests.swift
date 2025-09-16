//
//  WorkoutPlanLifecycleIntegrationTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

/// Integration tests for the complete workout plan lifecycle
/// Tests plan creation, saving, loading, usage tracking, and workout execution flow
@MainActor
final class WorkoutPlanLifecycleIntegrationTests: XCTestCase {
    var userPreferencesService: UserPreferencesService!
    var testPersistenceController: PersistenceController!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory persistence controller for testing
        self.testPersistenceController = PersistenceController(inMemory: true)
        self.userPreferencesService = UserPreferencesService(persistenceController: self.testPersistenceController)
    }

    override func tearDown() async throws {
        self.userPreferencesService = nil
        self.testPersistenceController = nil
        try await super.tearDown()
    }

    // MARK: - Plan Creation and Saving Tests

    func testPlanCreationAndAutomaticSaving() async throws {
        // Given: A new workout plan
        let exercises = [
            ExerciseData(name: "Push-ups", sets: 3, reps: 12, weight: 0, restTime: 60, orderIndex: 0),
            ExerciseData(name: "Squats", sets: 3, reps: 15, weight: 0, restTime: 90, orderIndex: 1)
        ]
        let plan = WorkoutPlanData(name: "Bodyweight Basics", exercises: exercises)

        // When: Plan is saved
        try await userPreferencesService.savePlan(plan)

        // Then: Plan should be persisted and available
        try await self.userPreferencesService.loadSavedPlans()
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, 1)

        let savedPlan = self.userPreferencesService.savedPlans.first!
        XCTAssertEqual(savedPlan.name, "Bodyweight Basics")
        XCTAssertEqual(savedPlan.exercises.count, 2)
        XCTAssertEqual(savedPlan.exercises[0].name, "Push-ups")
        XCTAssertEqual(savedPlan.exercises[1].name, "Squats")
        XCTAssertNil(savedPlan.lastUsedDate)
    }

    func testMultiplePlanCreationAndOrdering() async throws {
        // Given: Multiple workout plans created at different times
        let plan1 = WorkoutPlanData(
            name: "Upper Body",
            exercises: [ExerciseData(name: "Push-ups", sets: 3, reps: 10, weight: 0, restTime: 60, orderIndex: 0)],
            createdDate: Date().addingTimeInterval(-86_400) // 1 day ago
        )

        let plan2 = WorkoutPlanData(
            name: "Lower Body",
            exercises: [ExerciseData(name: "Squats", sets: 3, reps: 15, weight: 0, restTime: 60, orderIndex: 0)],
            createdDate: Date().addingTimeInterval(-3_600) // 1 hour ago
        )

        let plan3 = WorkoutPlanData(
            name: "Full Body",
            exercises: [ExerciseData(name: "Burpees", sets: 3, reps: 8, weight: 0, restTime: 120, orderIndex: 0)]
        )

        // When: Plans are saved
        try await userPreferencesService.savePlan(plan1)
        try await self.userPreferencesService.savePlan(plan2)
        try await self.userPreferencesService.savePlan(plan3)

        // Then: Plans should be ordered by last used (most recent first), then by creation date
        try await self.userPreferencesService.loadSavedPlans()
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, 3)

        // Since no plans have been used, they should be ordered by creation date (newest first)
        XCTAssertEqual(self.userPreferencesService.savedPlans[0].name, "Full Body")
        XCTAssertEqual(self.userPreferencesService.savedPlans[1].name, "Lower Body")
        XCTAssertEqual(self.userPreferencesService.savedPlans[2].name, "Upper Body")
    }

    // MARK: - Plan Usage Tracking Tests

    func testPlanUsageTracking() async throws {
        // Given: A saved workout plan
        let plan = WorkoutPlanData(
            name: "Test Workout",
            exercises: [ExerciseData(name: "Test Exercise", sets: 1, reps: 1, weight: 0, restTime: 30, orderIndex: 0)]
        )
        try await userPreferencesService.savePlan(plan)

        // When: Plan is marked as used
        let usageDate = Date()
        try await userPreferencesService.markPlanAsUsed(plan.id)

        // Then: Plan should have updated last used date
        try await self.userPreferencesService.loadSavedPlans()
        let updatedPlan = self.userPreferencesService.savedPlans.first!
        XCTAssertNotNil(updatedPlan.lastUsedDate)

        // Allow for small time difference in test execution
        let timeDifference = abs(updatedPlan.lastUsedDate!.timeIntervalSince(usageDate))
        XCTAssertLessThan(timeDifference, 5.0, "Last used date should be within 5 seconds of marking")
    }

    func testPlanUsageOrderingAfterUse() async throws {
        // Given: Multiple plans with different creation dates
        let oldPlan = WorkoutPlanData(
            name: "Old Plan",
            exercises: [ExerciseData(name: "Exercise", sets: 1, reps: 1, weight: 0, restTime: 30, orderIndex: 0)],
            createdDate: Date().addingTimeInterval(-86_400) // 1 day ago
        )

        let newPlan = WorkoutPlanData(
            name: "New Plan",
            exercises: [ExerciseData(name: "Exercise", sets: 1, reps: 1, weight: 0, restTime: 30, orderIndex: 0)]
        )

        try await userPreferencesService.savePlan(oldPlan)
        try await self.userPreferencesService.savePlan(newPlan)

        // When: Old plan is used
        try await self.userPreferencesService.markPlanAsUsed(oldPlan.id)

        // Then: Old plan should appear first due to recent usage
        try await self.userPreferencesService.loadSavedPlans()
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, 2)
        XCTAssertEqual(self.userPreferencesService.savedPlans[0].name, "Old Plan")
        XCTAssertEqual(self.userPreferencesService.savedPlans[1].name, "New Plan")

        // Verify the old plan has a last used date
        XCTAssertNotNil(self.userPreferencesService.savedPlans[0].lastUsedDate)
        XCTAssertNil(self.userPreferencesService.savedPlans[1].lastUsedDate)
    }

    // MARK: - Workout Execution Integration Tests

    func testWorkoutExecutionPlanUsageIntegration() async throws {
        // Given: A workout plan ready for execution
        let exercises = [
            ExerciseData(name: "Push-ups", sets: 2, reps: 10, weight: 0, restTime: 60, orderIndex: 0),
            ExerciseData(name: "Squats", sets: 2, reps: 12, weight: 0, restTime: 60, orderIndex: 1)
        ]
        let plan = WorkoutPlanData(name: "Quick Workout", exercises: exercises)
        try await userPreferencesService.savePlan(plan)

        // Verify plan is saved without usage
        try await self.userPreferencesService.loadSavedPlans()
        let savedPlan = self.userPreferencesService.savedPlans.first!
        XCTAssertNil(savedPlan.lastUsedDate)

        // When: Plan is marked as used (simulating workout start)
        let workoutStartTime = Date()
        try await userPreferencesService.markPlanAsUsed(plan.id)

        // Then: Plan should be marked as used
        try await self.userPreferencesService.loadSavedPlans()
        let usedPlan = self.userPreferencesService.savedPlans.first!
        XCTAssertNotNil(usedPlan.lastUsedDate)

        let timeDifference = abs(usedPlan.lastUsedDate!.timeIntervalSince(workoutStartTime))
        XCTAssertLessThan(timeDifference, 5.0, "Usage time should be close to workout start time")
    }

    func testMultipleWorkoutSessionsUsageTracking() async throws {
        // Given: A workout plan
        let plan = WorkoutPlanData(
            name: "Regular Workout",
            exercises: [ExerciseData(name: "Exercise", sets: 1, reps: 1, weight: 0, restTime: 30, orderIndex: 0)]
        )
        try await userPreferencesService.savePlan(plan)

        // When: Plan is used multiple times
        let firstUse = Date().addingTimeInterval(-3_600) // 1 hour ago
        let secondUse = Date().addingTimeInterval(-1_800) // 30 minutes ago
        let thirdUse = Date() // Now

        // Simulate first workout session
        try await userPreferencesService.markPlanAsUsed(plan.id)

        // Wait a moment and use again
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        try await self.userPreferencesService.markPlanAsUsed(plan.id)

        // Then: Plan should have the most recent usage date
        try await self.userPreferencesService.loadSavedPlans()
        let updatedPlan = self.userPreferencesService.savedPlans.first!
        XCTAssertNotNil(updatedPlan.lastUsedDate)

        // The last used date should be very recent (within the last few seconds)
        let timeSinceLastUse = Date().timeIntervalSince(updatedPlan.lastUsedDate!)
        XCTAssertLessThan(timeSinceLastUse, 5.0, "Last used date should be very recent")
    }

    // MARK: - Plan Management Integration Tests

    func testPlanRenamePreservesUsageData() async throws {
        // Given: A used workout plan
        let plan = WorkoutPlanData(
            name: "Original Name",
            exercises: [ExerciseData(name: "Exercise", sets: 1, reps: 1, weight: 0, restTime: 30, orderIndex: 0)]
        )
        try await userPreferencesService.savePlan(plan)
        try await self.userPreferencesService.markPlanAsUsed(plan.id)

        // When: Plan is renamed
        try await self.userPreferencesService.renamePlan(plan.id, newName: "New Name")

        // Then: Plan should have new name but preserve usage data
        try await self.userPreferencesService.loadSavedPlans()
        let renamedPlan = self.userPreferencesService.savedPlans.first!
        XCTAssertEqual(renamedPlan.name, "New Name")
        XCTAssertNotNil(renamedPlan.lastUsedDate)
        XCTAssertEqual(renamedPlan.id, plan.id)
    }

    func testPlanDeletionRemovesFromUsageTracking() async throws {
        // Given: Multiple plans, one of which is used
        let plan1 = WorkoutPlanData(
            name: "Plan 1",
            exercises: [ExerciseData(name: "Exercise", sets: 1, reps: 1, weight: 0, restTime: 30, orderIndex: 0)]
        )
        let plan2 = WorkoutPlanData(
            name: "Plan 2",
            exercises: [ExerciseData(name: "Exercise", sets: 1, reps: 1, weight: 0, restTime: 30, orderIndex: 0)]
        )

        try await userPreferencesService.savePlan(plan1)
        try await self.userPreferencesService.savePlan(plan2)
        try await self.userPreferencesService.markPlanAsUsed(plan1.id)

        // When: Used plan is deleted
        try await self.userPreferencesService.deletePlan(plan1.id)

        // Then: Only the remaining plan should exist
        try await self.userPreferencesService.loadSavedPlans()
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, 1)
        XCTAssertEqual(self.userPreferencesService.savedPlans.first!.name, "Plan 2")
        XCTAssertNil(self.userPreferencesService.savedPlans.first!.lastUsedDate)
    }

    // MARK: - Error Handling Tests

    func testMarkingNonExistentPlanAsUsedThrowsError() async {
        // Given: A non-existent plan ID
        let nonExistentPlanId = UUID()

        // When/Then: Marking non-existent plan as used should throw error
        do {
            try await self.userPreferencesService.markPlanAsUsed(nonExistentPlanId)
            XCTFail("Expected error when marking non-existent plan as used")
        } catch let error as UserPreferencesError {
            if case let .planNotFound(id) = error {
                XCTAssertEqual(id, nonExistentPlanId)
            } else {
                XCTFail("Expected planNotFound error, got \(error)")
            }
        } catch {
            XCTFail("Expected UserPreferencesError, got \(error)")
        }
    }

    // MARK: - Performance Tests

    func testLargePlanCollectionPerformance() async throws {
        // Given: A large number of workout plans
        let planCount = 100
        var plans: [WorkoutPlanData] = []

        for i in 0 ..< planCount {
            let exercises = [
                ExerciseData(name: "Exercise \(i)", sets: 3, reps: 10, weight: 0, restTime: 60, orderIndex: 0)
            ]
            let plan = WorkoutPlanData(
                name: "Plan \(i)",
                exercises: exercises,
                createdDate: Date().addingTimeInterval(TimeInterval(-i * 60)) // Spread over time
            )
            plans.append(plan)
        }

        // When: Plans are saved and loaded
        let saveStartTime = Date()
        for plan in plans {
            try await self.userPreferencesService.savePlan(plan)
        }
        let saveEndTime = Date()

        let loadStartTime = Date()
        try await userPreferencesService.loadSavedPlans()
        let loadEndTime = Date()

        // Then: Operations should complete in reasonable time
        let saveTime = saveEndTime.timeIntervalSince(saveStartTime)
        let loadTime = loadEndTime.timeIntervalSince(loadStartTime)

        XCTAssertLessThan(saveTime, 10.0, "Saving 100 plans should take less than 10 seconds")
        XCTAssertLessThan(loadTime, 2.0, "Loading 100 plans should take less than 2 seconds")

        // Verify all plans were saved and loaded correctly
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, planCount)
    }

    func testFrequentUsageUpdatesPerformance() async throws {
        // Given: A workout plan
        let plan = WorkoutPlanData(
            name: "Performance Test Plan",
            exercises: [ExerciseData(name: "Exercise", sets: 1, reps: 1, weight: 0, restTime: 30, orderIndex: 0)]
        )
        try await userPreferencesService.savePlan(plan)

        // When: Plan is marked as used many times (simulating frequent workouts)
        let usageCount = 50
        let startTime = Date()

        for _ in 0 ..< usageCount {
            try await self.userPreferencesService.markPlanAsUsed(plan.id)
        }

        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)

        // Then: Updates should complete in reasonable time
        XCTAssertLessThan(totalTime, 5.0, "50 usage updates should take less than 5 seconds")

        // Verify the plan still has the correct data
        try await self.userPreferencesService.loadSavedPlans()
        let updatedPlan = self.userPreferencesService.savedPlans.first!
        XCTAssertNotNil(updatedPlan.lastUsedDate)
        XCTAssertEqual(updatedPlan.name, "Performance Test Plan")
    }
}

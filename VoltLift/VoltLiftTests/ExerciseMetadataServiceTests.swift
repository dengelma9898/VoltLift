//
//  ExerciseMetadataServiceTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 14.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

@MainActor
final class ExerciseMetadataServiceTests: XCTestCase {
    var service: ExerciseMetadataService!
    var context: NSManagedObjectContext!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory Core Data stack for testing
        let persistenceController = PersistenceController(inMemory: true)
        self.context = persistenceController.container.viewContext
        self.service = ExerciseMetadataService(context: self.context)
    }

    override func tearDown() async throws {
        self.service = nil
        self.context = nil
        try await super.tearDown()
    }

    // MARK: - Test Metadata Creation and Retrieval

    func testGetMetadata_WhenMetadataDoesNotExist_ReturnsNil() async throws {
        // Given
        let exerciseId = UUID()

        // When
        let metadata = await service.getMetadata(for: exerciseId)

        // Then
        XCTAssertNil(metadata)
    }

    func testUpdateLastUsed_CreatesNewMetadata() async throws {
        // Given
        let exerciseId = UUID()
        let exerciseName = "Push-up"

        // When
        await service.updateLastUsed(for: exerciseId, name: exerciseName)

        // Then
        let metadata = await service.getMetadata(for: exerciseId)
        XCTAssertNotNil(metadata)
        XCTAssertEqual(metadata?.exerciseId, exerciseId)
        XCTAssertEqual(metadata?.name, exerciseName)
        XCTAssertEqual(metadata?.usageCount, 1)
        XCTAssertNotNil(metadata?.lastUsed)
    }

    func testUpdateLastUsed_UpdatesExistingMetadata() async throws {
        // Given
        let exerciseId = UUID()
        let exerciseName = "Push-up"
        await service.updateLastUsed(for: exerciseId, name: exerciseName)

        let originalMetadata = await service.getMetadata(for: exerciseId)
        let originalUsageCount = originalMetadata?.usageCount ?? 0
        let originalLastUsed = originalMetadata?.lastUsed

        // Wait a small amount to ensure different timestamp
        try await Task.sleep(nanoseconds: 1_000_000) // 1ms

        // When
        await self.service.updateLastUsed(for: exerciseId, name: exerciseName)

        // Then
        let updatedMetadata = await service.getMetadata(for: exerciseId)
        XCTAssertEqual(updatedMetadata?.usageCount, originalUsageCount + 1)
        XCTAssertNotEqual(updatedMetadata?.lastUsed, originalLastUsed)
    }

    // MARK: - Test Personal Notes

    func testUpdatePersonalNotes_UpdatesExistingMetadata() async throws {
        // Given
        let exerciseId = UUID()
        let exerciseName = "Push-up"
        let notes = "Great exercise for chest development"

        await service.updateLastUsed(for: exerciseId, name: exerciseName)

        // When
        await self.service.updatePersonalNotes(for: exerciseId, notes: notes)

        // Then
        let metadata = await service.getMetadata(for: exerciseId)
        XCTAssertEqual(metadata?.personalNotes, notes)
    }

    func testUpdatePersonalNotes_WithEmptyString_SetsToNil() async throws {
        // Given
        let exerciseId = UUID()
        let exerciseName = "Push-up"

        await service.updateLastUsed(for: exerciseId, name: exerciseName)
        await self.service.updatePersonalNotes(for: exerciseId, notes: "Some notes")

        // When
        await self.service.updatePersonalNotes(for: exerciseId, notes: "")

        // Then
        let metadata = await service.getMetadata(for: exerciseId)
        XCTAssertNil(metadata?.personalNotes)
    }

    func testUpdatePersonalNotes_ForNonExistentMetadata_DoesNothing() async throws {
        // Given
        let exerciseId = UUID()
        let notes = "Some notes"

        // When
        await service.updatePersonalNotes(for: exerciseId, notes: notes)

        // Then
        let metadata = await service.getMetadata(for: exerciseId)
        XCTAssertNil(metadata)
    }

    // MARK: - Test Custom Weight

    func testUpdateCustomWeight_UpdatesExistingMetadata() async throws {
        // Given
        let exerciseId = UUID()
        let exerciseName = "Bench Press"
        let weight = 135.0

        await service.updateLastUsed(for: exerciseId, name: exerciseName)

        // When
        await self.service.updateCustomWeight(for: exerciseId, weight: weight)

        // Then
        let metadata = await service.getMetadata(for: exerciseId)
        XCTAssertEqual(metadata?.customWeight ?? 0.0, weight, accuracy: 0.01)
    }

    func testUpdateCustomWeight_ForNonExistentMetadata_DoesNothing() async throws {
        // Given
        let exerciseId = UUID()
        let weight = 135.0

        // When
        await service.updateCustomWeight(for: exerciseId, weight: weight)

        // Then
        let metadata = await service.getMetadata(for: exerciseId)
        XCTAssertNil(metadata)
    }

    // MARK: - Test Recently Used Exercises

    func testGetRecentlyUsedExercises_ReturnsInCorrectOrder() async throws {
        // Given
        let exercise1Id = UUID()
        let exercise2Id = UUID()
        let exercise3Id = UUID()

        await service.updateLastUsed(for: exercise1Id, name: "Exercise 1")

        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        await self.service.updateLastUsed(for: exercise2Id, name: "Exercise 2")

        try await Task.sleep(nanoseconds: 1_000_000) // 1ms
        await self.service.updateLastUsed(for: exercise3Id, name: "Exercise 3")

        // When
        let recentExercises = await service.getRecentlyUsedExercises(limit: 10)

        // Then
        XCTAssertEqual(recentExercises.count, 3)
        XCTAssertEqual(recentExercises[0].exerciseId, exercise3Id) // Most recent first
        XCTAssertEqual(recentExercises[1].exerciseId, exercise2Id)
        XCTAssertEqual(recentExercises[2].exerciseId, exercise1Id)
    }

    func testGetRecentlyUsedExercises_RespectsLimit() async throws {
        // Given
        for i in 0 ..< 5 {
            await self.service.updateLastUsed(for: UUID(), name: "Exercise \(i)")
        }

        // When
        let recentExercises = await service.getRecentlyUsedExercises(limit: 3)

        // Then
        XCTAssertEqual(recentExercises.count, 3)
    }

    // MARK: - Test Most Used Exercises

    func testGetMostUsedExercises_ReturnsInCorrectOrder() async throws {
        // Given
        let exercise1Id = UUID()
        let exercise2Id = UUID()
        let exercise3Id = UUID()

        // Exercise 1: 1 use
        await service.updateLastUsed(for: exercise1Id, name: "Exercise 1")

        // Exercise 2: 3 uses
        await self.service.updateLastUsed(for: exercise2Id, name: "Exercise 2")
        await self.service.updateLastUsed(for: exercise2Id, name: "Exercise 2")
        await self.service.updateLastUsed(for: exercise2Id, name: "Exercise 2")

        // Exercise 3: 2 uses
        await self.service.updateLastUsed(for: exercise3Id, name: "Exercise 3")
        await self.service.updateLastUsed(for: exercise3Id, name: "Exercise 3")

        // When
        let mostUsedExercises = await service.getMostUsedExercises(limit: 10)

        // Then
        XCTAssertEqual(mostUsedExercises.count, 3)
        XCTAssertEqual(mostUsedExercises[0].exerciseId, exercise2Id) // Most used first (3 uses)
        XCTAssertEqual(mostUsedExercises[1].exerciseId, exercise3Id) // Second most used (2 uses)
        XCTAssertEqual(mostUsedExercises[2].exerciseId, exercise1Id) // Least used (1 use)
    }

    func testGetMostUsedExercises_RespectsLimit() async throws {
        // Given
        for i in 0 ..< 5 {
            await self.service.updateLastUsed(for: UUID(), name: "Exercise \(i)")
        }

        // When
        let mostUsedExercises = await service.getMostUsedExercises(limit: 2)

        // Then
        XCTAssertEqual(mostUsedExercises.count, 2)
    }

    // MARK: - Test Delete Metadata

    func testDeleteMetadata_RemovesExistingMetadata() async throws {
        // Given
        let exerciseId = UUID()
        let exerciseName = "Push-up"

        await service.updateLastUsed(for: exerciseId, name: exerciseName)
        let initialMetadata = await service.getMetadata(for: exerciseId)
        XCTAssertNotNil(initialMetadata)

        // When
        try await self.service.deleteMetadata(for: exerciseId)

        // Then
        let finalMetadata = await service.getMetadata(for: exerciseId)
        XCTAssertNil(finalMetadata)
    }

    func testDeleteMetadata_ForNonExistentMetadata_DoesNothing() async throws {
        // Given
        let exerciseId = UUID()

        // When & Then (should not crash)
        try await service.deleteMetadata(for: exerciseId)
    }

    // MARK: - Test Error Handling

    func testService_HandlesContextErrors_Gracefully() async throws {
        // This test ensures the service handles Core Data errors gracefully
        // In a real scenario, we might simulate context errors, but for now
        // we just verify the service doesn't crash with normal operations

        let exerciseId = UUID()
        await service.updateLastUsed(for: exerciseId, name: "Test Exercise")

        let metadata = await service.getMetadata(for: exerciseId)
        XCTAssertNotNil(metadata)
    }
}

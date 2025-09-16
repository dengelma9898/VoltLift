//
//  ExerciseMetadataExtensionsTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 14.9.2025.
//

import XCTest
import CoreData
@testable import VoltLift

final class ExerciseMetadataExtensionsTests: XCTestCase {
    
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        
        // Create in-memory Core Data stack for testing
        let persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }
    
    override func tearDown() {
        context = nil
        super.tearDown()
    }
    
    // MARK: - Test Convenience Initializer
    
    func testConvenienceInitializer_SetsRequiredProperties() {
        // Given
        let exerciseId = UUID()
        let exerciseName = "Push-up"
        
        // When
        let metadata = ExerciseMetadata(exerciseId: exerciseId, name: exerciseName, context: context)
        
        // Then
        XCTAssertEqual(metadata.exerciseId, exerciseId)
        XCTAssertEqual(metadata.name, exerciseName)
        XCTAssertNotNil(metadata.lastUsed)
        XCTAssertEqual(metadata.usageCount, 0)
    }
    
    // MARK: - Test Recently Used Property
    
    func testIsRecentlyUsed_WithRecentDate_ReturnsTrue() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.lastUsed = Date().addingTimeInterval(-3 * 24 * 60 * 60) // 3 days ago
        
        // When & Then
        XCTAssertTrue(metadata.isRecentlyUsed)
    }
    
    func testIsRecentlyUsed_WithOldDate_ReturnsFalse() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.lastUsed = Date().addingTimeInterval(-10 * 24 * 60 * 60) // 10 days ago
        
        // When & Then
        XCTAssertFalse(metadata.isRecentlyUsed)
    }
    
    func testIsRecentlyUsed_WithNilDate_ReturnsFalse() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.lastUsed = nil
        
        // When & Then
        XCTAssertFalse(metadata.isRecentlyUsed)
    }
    
    // MARK: - Test Frequently Used Property
    
    func testIsFrequentlyUsed_WithHighUsageCount_ReturnsTrue() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.usageCount = 10
        
        // When & Then
        XCTAssertTrue(metadata.isFrequentlyUsed)
    }
    
    func testIsFrequentlyUsed_WithLowUsageCount_ReturnsFalse() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.usageCount = 3
        
        // When & Then
        XCTAssertFalse(metadata.isFrequentlyUsed)
    }
    
    func testIsFrequentlyUsed_WithBoundaryValue_ReturnsFalse() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.usageCount = 5 // Boundary value (should be false, needs > 5)
        
        // When & Then
        XCTAssertFalse(metadata.isFrequentlyUsed)
    }
    
    // MARK: - Test Formatted Last Used
    
    func testFormattedLastUsed_WithValidDate_ReturnsFormattedString() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.lastUsed = Date().addingTimeInterval(-60 * 60) // 1 hour ago
        
        // When
        let formatted = metadata.formattedLastUsed
        
        // Then
        XCTAssertFalse(formatted.isEmpty)
        XCTAssertNotEqual(formatted, "Never")
    }
    
    func testFormattedLastUsed_WithNilDate_ReturnsNever() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.lastUsed = nil
        
        // When
        let formatted = metadata.formattedLastUsed
        
        // Then
        XCTAssertEqual(formatted, "Never")
    }
    
    // MARK: - Test Usage Frequency Description
    
    func testUsageFrequencyDescription_WithZeroUsage_ReturnsNeverUsed() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.usageCount = 0
        
        // When
        let description = metadata.usageFrequencyDescription
        
        // Then
        XCTAssertEqual(description, "Never used")
    }
    
    func testUsageFrequencyDescription_WithSingleUsage_ReturnsUsedOnce() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.usageCount = 1
        
        // When
        let description = metadata.usageFrequencyDescription
        
        // Then
        XCTAssertEqual(description, "Used once")
    }
    
    func testUsageFrequencyDescription_WithLowUsage_ReturnsUsedXTimes() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.usageCount = 3
        
        // When
        let description = metadata.usageFrequencyDescription
        
        // Then
        XCTAssertEqual(description, "Used 3 times")
    }
    
    func testUsageFrequencyDescription_WithMediumUsage_ReturnsFrequentlyUsed() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.usageCount = 10
        
        // When
        let description = metadata.usageFrequencyDescription
        
        // Then
        XCTAssertEqual(description, "Frequently used (10 times)")
    }
    
    func testUsageFrequencyDescription_WithHighUsage_ReturnsVeryFrequentlyUsed() {
        // Given
        let metadata = ExerciseMetadata(context: context)
        metadata.usageCount = 25
        
        // When
        let description = metadata.usageFrequencyDescription
        
        // Then
        XCTAssertEqual(description, "Very frequently used (25 times)")
    }
    
    // MARK: - Test Fetch Requests
    
    func testFetchRequest_ReturnsCorrectEntityName() {
        // When
        let request = ExerciseMetadata.fetchRequest()
        
        // Then
        XCTAssertEqual(request.entityName, "ExerciseMetadata")
    }
    
    func testRecentlyUsedFetchRequest_HasCorrectConfiguration() {
        // When
        let request = ExerciseMetadata.recentlyUsedFetchRequest(limit: 5)
        
        // Then
        XCTAssertEqual(request.entityName, "ExerciseMetadata")
        XCTAssertEqual(request.fetchLimit, 5)
        XCTAssertEqual(request.sortDescriptors?.count, 1)
        XCTAssertEqual(request.sortDescriptors?.first?.key, "lastUsed")
        XCTAssertEqual(request.sortDescriptors?.first?.ascending, false)
    }
    
    func testMostUsedFetchRequest_HasCorrectConfiguration() {
        // When
        let request = ExerciseMetadata.mostUsedFetchRequest(limit: 3)
        
        // Then
        XCTAssertEqual(request.entityName, "ExerciseMetadata")
        XCTAssertEqual(request.fetchLimit, 3)
        XCTAssertEqual(request.sortDescriptors?.count, 2)
        
        // Check first sort descriptor (usage count, descending)
        XCTAssertEqual(request.sortDescriptors?[0].key, "usageCount")
        XCTAssertEqual(request.sortDescriptors?[0].ascending, false)
        
        // Check second sort descriptor (last used, descending)
        XCTAssertEqual(request.sortDescriptors?[1].key, "lastUsed")
        XCTAssertEqual(request.sortDescriptors?[1].ascending, false)
    }
    
    func testFetchRequestForExerciseId_HasCorrectConfiguration() {
        // Given
        let exerciseId = UUID()
        
        // When
        let request = ExerciseMetadata.fetchRequest(for: exerciseId)
        
        // Then
        XCTAssertEqual(request.entityName, "ExerciseMetadata")
        XCTAssertEqual(request.fetchLimit, 1)
        XCTAssertNotNil(request.predicate)
        
        // Verify predicate format (basic check)
        let predicateString = request.predicate?.predicateFormat ?? ""
        XCTAssertTrue(predicateString.contains("exerciseId"))
    }
}
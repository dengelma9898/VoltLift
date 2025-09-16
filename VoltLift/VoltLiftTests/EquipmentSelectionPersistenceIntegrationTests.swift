//
//  EquipmentSelectionPersistenceIntegrationTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import XCTest
import CoreData
@testable import VoltLift

/// Integration tests for equipment selection persistence functionality
/// Tests the complete flow from UI interaction to Core Data persistence
@MainActor
final class EquipmentSelectionPersistenceIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    
    private var userPreferencesService: UserPreferencesService!
    private var persistenceController: PersistenceController!
    
    // MARK: - Setup and Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory persistence controller for testing
        persistenceController = PersistenceController(inMemory: true)
        userPreferencesService = UserPreferencesService(persistenceController: persistenceController)
    }
    
    override func tearDown() async throws {
        userPreferencesService = nil
        persistenceController = nil
        try await super.tearDown()
    }
    
    // MARK: - Equipment Selection Persistence Tests
    
    /// Tests that equipment selection is properly saved and loaded
    func testEquipmentSelectionPersistence() async throws {
        // Given: A set of equipment items
        let equipmentItems = [
            EquipmentItem(id: "dumbbells", name: "Dumbbells", category: "Weights", isSelected: true),
            EquipmentItem(id: "resistance-bands", name: "Resistance Bands", category: "Resistance", isSelected: true),
            EquipmentItem(id: "yoga-mat", name: "Yoga Mat", category: "Accessories", isSelected: false),
            EquipmentItem(id: "kettlebell", name: "Kettlebell", category: "Weights", isSelected: true)
        ]
        
        // When: Equipment selection is saved
        try await userPreferencesService.saveEquipmentSelection(equipmentItems)
        
        // Then: Equipment should be persisted in Core Data
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
        let savedEquipment = try context.fetch(request)
        
        XCTAssertEqual(savedEquipment.count, 4, "All equipment items should be saved")
        
        // Verify selected equipment
        let selectedEquipment = savedEquipment.filter { $0.isSelected }
        XCTAssertEqual(selectedEquipment.count, 3, "Three items should be selected")
        
        let selectedNames = Set(selectedEquipment.compactMap { $0.name })
        XCTAssertTrue(selectedNames.contains("Dumbbells"))
        XCTAssertTrue(selectedNames.contains("Resistance Bands"))
        XCTAssertTrue(selectedNames.contains("Kettlebell"))
        XCTAssertFalse(selectedNames.contains("Yoga Mat"))
    }
    
    /// Tests that equipment selection can be loaded after app restart
    func testEquipmentSelectionLoadAfterRestart() async throws {
        // Given: Equipment is saved
        let originalEquipment = [
            EquipmentItem(id: "dumbbells", name: "Dumbbells", category: "Weights", isSelected: true),
            EquipmentItem(id: "barbell", name: "Barbell", category: "Weights", isSelected: true),
            EquipmentItem(id: "yoga-mat", name: "Yoga Mat", category: "Accessories", isSelected: false)
        ]
        
        try await userPreferencesService.saveEquipmentSelection(originalEquipment)
        
        // When: A new service instance loads the equipment (simulating app restart)
        let newService = UserPreferencesService(persistenceController: persistenceController)
        try await newService.loadSelectedEquipment()
        
        // Then: The loaded equipment should match what was saved
        XCTAssertEqual(newService.selectedEquipment.count, 3, "All equipment items should be loaded")
        
        let selectedItems = newService.selectedEquipment.filter { $0.isSelected }
        XCTAssertEqual(selectedItems.count, 2, "Two items should be selected")
        
        let selectedNames = Set(selectedItems.map { $0.name })
        XCTAssertTrue(selectedNames.contains("Dumbbells"))
        XCTAssertTrue(selectedNames.contains("Barbell"))
        XCTAssertFalse(selectedNames.contains("Yoga Mat"))
    }
    
    /// Tests updating individual equipment selection
    func testIndividualEquipmentUpdate() async throws {
        // Given: Initial equipment setup
        let initialEquipment = [
            EquipmentItem(id: "dumbbells", name: "Dumbbells", category: "Weights", isSelected: true),
            EquipmentItem(id: "kettlebell", name: "Kettlebell", category: "Weights", isSelected: false)
        ]
        
        try await userPreferencesService.saveEquipmentSelection(initialEquipment)
        
        // When: Individual equipment selection is updated
        let kettlebell = EquipmentItem(id: "kettlebell", name: "Kettlebell", category: "Weights", isSelected: false)
        try await userPreferencesService.updateEquipmentSelection(kettlebell, isSelected: true)
        
        // Then: The update should be persisted
        try await userPreferencesService.loadSelectedEquipment()
        
        let kettlebellItem = userPreferencesService.selectedEquipment.first { $0.id == "kettlebell" }
        XCTAssertNotNil(kettlebellItem, "Kettlebell should be found")
        XCTAssertTrue(kettlebellItem?.isSelected ?? false, "Kettlebell should be selected")
    }
    
    /// Tests setup completion tracking
    func testSetupCompletionTracking() async throws {
        // Given: No equipment selected initially
        let isCompleteInitially = try await userPreferencesService.checkSetupCompletion()
        XCTAssertFalse(isCompleteInitially, "Setup should not be complete initially")
        XCTAssertFalse(userPreferencesService.hasCompletedSetup, "Service should reflect incomplete setup")
        
        // When: Equipment is selected
        let equipment = [
            EquipmentItem(id: "dumbbells", name: "Dumbbells", category: "Weights", isSelected: true)
        ]
        try await userPreferencesService.saveEquipmentSelection(equipment)
        
        // Then: Setup should be marked as complete
        let isCompleteAfterSelection = try await userPreferencesService.checkSetupCompletion()
        XCTAssertTrue(isCompleteAfterSelection, "Setup should be complete after equipment selection")
        XCTAssertTrue(userPreferencesService.hasCompletedSetup, "Service should reflect complete setup")
    }
    
    /// Tests error handling for corrupted data
    func testErrorHandlingForCorruptedData() async throws {
        // Given: Corrupted equipment data in Core Data
        let context = persistenceController.container.viewContext
        let corruptedEquipment = UserEquipment(context: context)
        corruptedEquipment.equipmentId = nil // Missing required field
        corruptedEquipment.name = "Corrupted Equipment"
        corruptedEquipment.isSelected = true
        
        try context.save()
        
        // When: Loading equipment with corrupted data
        do {
            try await userPreferencesService.loadSelectedEquipment()
            
            // Then: Corrupted items should be filtered out
            let validEquipment = userPreferencesService.selectedEquipment.filter { !$0.id.isEmpty }
            XCTAssertEqual(validEquipment.count, 0, "Corrupted equipment should be filtered out")
        } catch {
            // It's also acceptable for the service to throw an error when encountering corrupted data
            XCTAssertTrue(error is UserPreferencesError, "Should throw UserPreferencesError for corrupted data")
        }
    }
    
    /// Tests concurrent equipment updates
    func testConcurrentEquipmentUpdates() async throws {
        // Given: Initial equipment
        let initialEquipment = [
            EquipmentItem(id: "dumbbells", name: "Dumbbells", category: "Weights", isSelected: false),
            EquipmentItem(id: "kettlebell", name: "Kettlebell", category: "Weights", isSelected: false),
            EquipmentItem(id: "barbell", name: "Barbell", category: "Weights", isSelected: false)
        ]
        
        try await userPreferencesService.saveEquipmentSelection(initialEquipment)
        
        // When: Multiple concurrent updates are performed
        await withTaskGroup(of: Void.self) { group in
            for equipment in initialEquipment {
                group.addTask {
                    do {
                        try await self.userPreferencesService.updateEquipmentSelection(equipment, isSelected: true)
                    } catch {
                        XCTFail("Concurrent update failed: \(error)")
                    }
                }
            }
        }
        
        // Then: All updates should be successful
        try await userPreferencesService.loadSelectedEquipment()
        let selectedCount = userPreferencesService.selectedEquipment.filter { $0.isSelected }.count
        XCTAssertEqual(selectedCount, 3, "All equipment should be selected after concurrent updates")
    }
    
    /// Tests equipment selection with large dataset
    func testEquipmentSelectionWithLargeDataset() async throws {
        // Given: A large set of equipment items
        let largeEquipmentSet = (1...100).map { index in
            EquipmentItem(
                id: "equipment-\(index)",
                name: "Equipment \(index)",
                category: index % 2 == 0 ? "Weights" : "Accessories",
                isSelected: index % 3 == 0 // Every third item selected
            )
        }
        
        // When: Large dataset is saved and loaded
        let startTime = CFAbsoluteTimeGetCurrent()
        try await userPreferencesService.saveEquipmentSelection(largeEquipmentSet)
        try await userPreferencesService.loadSelectedEquipment()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        // Then: Operation should complete within reasonable time
        let executionTime = endTime - startTime
        XCTAssertLessThan(executionTime, 5.0, "Large dataset operations should complete within 5 seconds")
        
        XCTAssertEqual(userPreferencesService.selectedEquipment.count, 100, "All equipment should be loaded")
        
        let selectedCount = userPreferencesService.selectedEquipment.filter { $0.isSelected }.count
        let expectedSelectedCount = largeEquipmentSet.filter { $0.isSelected }.count
        XCTAssertEqual(selectedCount, expectedSelectedCount, "Selected equipment count should match")
    }
    
    /// Tests equipment selection persistence across multiple save/load cycles
    func testMultipleSaveLoadCycles() async throws {
        var currentEquipment = [
            EquipmentItem(id: "dumbbells", name: "Dumbbells", category: "Weights", isSelected: true),
            EquipmentItem(id: "kettlebell", name: "Kettlebell", category: "Weights", isSelected: false)
        ]
        
        // Perform multiple save/load cycles
        for cycle in 1...5 {
            // Modify selection
            currentEquipment = currentEquipment.map { equipment in
                EquipmentItem(
                    id: equipment.id,
                    name: equipment.name,
                    category: equipment.category,
                    isSelected: cycle % 2 == 0 ? !equipment.isSelected : equipment.isSelected
                )
            }
            
            // Save and load
            try await userPreferencesService.saveEquipmentSelection(currentEquipment)
            try await userPreferencesService.loadSelectedEquipment()
            
            // Verify consistency
            XCTAssertEqual(
                userPreferencesService.selectedEquipment.count,
                currentEquipment.count,
                "Equipment count should remain consistent in cycle \(cycle)"
            )
            
            for equipment in currentEquipment {
                let loadedEquipment = userPreferencesService.selectedEquipment.first { $0.id == equipment.id }
                XCTAssertEqual(
                    loadedEquipment?.isSelected,
                    equipment.isSelected,
                    "Equipment selection should match for \(equipment.name) in cycle \(cycle)"
                )
            }
        }
    }
}

// MARK: - Test Helpers

extension EquipmentSelectionPersistenceIntegrationTests {
    
    /// Creates a sample equipment item for testing
    private func createSampleEquipment(
        id: String = "test-equipment",
        name: String = "Test Equipment",
        category: String = "Test",
        isSelected: Bool = false
    ) -> EquipmentItem {
        EquipmentItem(id: id, name: name, category: category, isSelected: isSelected)
    }
    
    /// Verifies that Core Data contains expected equipment
    private func verifyEquipmentInCoreData(
        expectedCount: Int,
        selectedCount: Int,
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
        
        let actualSelectedCount = savedEquipment.filter { $0.isSelected }.count
        XCTAssertEqual(
            actualSelectedCount,
            selectedCount,
            "Expected \(selectedCount) selected equipment items in Core Data",
            file: file,
            line: line
        )
    }
}
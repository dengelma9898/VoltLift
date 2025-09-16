//
//  UserPreferencesErrorHandlingTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

@MainActor
final class UserPreferencesErrorHandlingTests: XCTestCase {
    var userPreferencesService: UserPreferencesService!
    var mockPersistenceController: PersistenceController!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory Core Data stack for testing
        self.mockPersistenceController = PersistenceController(inMemory: true)
        self.userPreferencesService = UserPreferencesService(persistenceController: self.mockPersistenceController)
    }

    override func tearDown() async throws {
        self.userPreferencesService = nil
        self.mockPersistenceController = nil
        try await super.tearDown()
    }

    // MARK: - Error Mapping Tests

    func testErrorMapping_DecodingError_MapsToDataCorruption() {
        // Given
        let decodingError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON")
        )

        // When
        let mappedError = self.userPreferencesService.mapError(decodingError, operation: "load plans")

        // Then
        XCTAssertEqual(mappedError, UserPreferencesError.dataCorruption)
        XCTAssertEqual(mappedError.severity, ErrorSeverity.critical)
        XCTAssertFalse(mappedError.isRecoverable)
    }

    func testErrorMapping_TimeoutError_MapsToOperationTimeout() {
        // Given
        let timeoutError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)

        // When
        let mappedError = self.userPreferencesService.mapError(timeoutError, operation: "save equipment")

        // Then
        XCTAssertEqual(mappedError, UserPreferencesError.operationTimeout)
        XCTAssertEqual(mappedError.severity, ErrorSeverity.warning)
        XCTAssertTrue(mappedError.canRetry)
    }

    func testErrorMapping_NetworkError_MapsToNetworkUnavailable() {
        // Given
        let networkError = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil)

        // When
        let mappedError = self.userPreferencesService.mapError(networkError, operation: "sync data")

        // Then
        XCTAssertEqual(mappedError, UserPreferencesError.networkUnavailable)
        XCTAssertEqual(mappedError.severity, ErrorSeverity.warning)
        XCTAssertTrue(mappedError.isRecoverable)
    }

    func testErrorMapping_StorageError_MapsToInsufficientStorage() {
        // Given
        let storageError = NSError(domain: "TestDomain", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Not enough storage space available"
        ])

        // When
        let mappedError = self.userPreferencesService.mapError(storageError, operation: "save plan")

        // Then
        XCTAssertEqual(mappedError, UserPreferencesError.insufficientStorage)
        XCTAssertEqual(mappedError.severity, ErrorSeverity.critical)
        XCTAssertTrue(mappedError.isRecoverable)
    }

    func testErrorMapping_ValidationError_MapsToInvalidData() {
        // Given
        let validationError = NSError(
            domain: NSCocoaErrorDomain,
            code: NSValidationMissingMandatoryPropertyError,
            userInfo: nil
        )

        // When
        let mappedError = self.userPreferencesService.mapError(validationError, operation: "save equipment")

        // Then
        XCTAssertEqual(mappedError, UserPreferencesError.invalidData(field: "save equipment"))
        XCTAssertEqual(mappedError.severity, ErrorSeverity.error)
        XCTAssertTrue(mappedError.isRecoverable)
    }

    // MARK: - Loading State Tests

    func testLoadingState_SetCorrectly_DuringEquipmentLoad() async throws {
        // Given
        XCTAssertFalse(self.userPreferencesService.isLoading)
        XCTAssertEqual(self.userPreferencesService.loadingMessage, "")

        // When
        let loadTask = Task {
            try await self.userPreferencesService.loadSelectedEquipment()
        }

        // Then - Check loading state is set
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        XCTAssertTrue(self.userPreferencesService.isLoading)
        XCTAssertEqual(self.userPreferencesService.loadingMessage, "Loading your equipment...")
        XCTAssertEqual(self.userPreferencesService.operationInProgress, "Loading equipment")

        // Wait for completion
        _ = try await loadTask.value

        // Then - Check loading state is cleared
        XCTAssertFalse(self.userPreferencesService.isLoading)
        XCTAssertEqual(self.userPreferencesService.loadingMessage, "")
        XCTAssertNil(self.userPreferencesService.operationInProgress)
    }

    func testLoadingState_SetCorrectly_DuringPlanLoad() async throws {
        // Given
        XCTAssertFalse(self.userPreferencesService.isLoading)

        // When
        let loadTask = Task {
            try await self.userPreferencesService.loadSavedPlans()
        }

        // Then - Check loading state is set
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        XCTAssertTrue(self.userPreferencesService.isLoading)
        XCTAssertEqual(self.userPreferencesService.loadingMessage, "Loading your workout plans...")
        XCTAssertEqual(self.userPreferencesService.operationInProgress, "Loading plans")

        // Wait for completion
        _ = try await loadTask.value

        // Then - Check loading state is cleared
        XCTAssertFalse(self.userPreferencesService.isLoading)
        XCTAssertEqual(self.userPreferencesService.loadingMessage, "")
        XCTAssertNil(self.userPreferencesService.operationInProgress)
    }

    // MARK: - Error Handling Tests

    func testErrorHandling_SetsCorrectErrorState() async {
        // Given
        let testError = UserPreferencesError.dataCorruption

        // When
        await self.userPreferencesService.handleError(testError, operation: "test operation")

        // Then
        XCTAssertEqual(self.userPreferencesService.lastError, testError)
        XCTAssertTrue(self.userPreferencesService.showingErrorAlert)
        XCTAssertFalse(self.userPreferencesService.errorRecoveryOptions.isEmpty)
    }

    func testErrorHandling_CreatesCorrectRecoveryOptions_ForDataCorruption() async {
        // Given
        let testError = UserPreferencesError.dataCorruption

        // When
        await self.userPreferencesService.handleError(testError, operation: "load data")

        // Then
        let options = self.userPreferencesService.errorRecoveryOptions
        XCTAssertTrue(options.contains { $0.title == "Reset Data" && $0.isDestructive })
        XCTAssertTrue(options.contains { $0.title == "Dismiss" })
    }

    func testErrorHandling_CreatesCorrectRecoveryOptions_ForRetryableError() async {
        // Given
        let testError = UserPreferencesError.operationTimeout

        // When
        await self.userPreferencesService.handleError(testError, operation: "save data")

        // Then
        let options = self.userPreferencesService.errorRecoveryOptions
        XCTAssertTrue(options.contains { $0.title == "Retry" })
        XCTAssertTrue(options.contains { $0.title == "Dismiss" })
    }

    func testErrorHandling_CreatesCorrectRecoveryOptions_ForStorageError() async {
        // Given
        let testError = UserPreferencesError.insufficientStorage

        // When
        await self.userPreferencesService.handleError(testError, operation: "save plan")

        // Then
        let options = self.userPreferencesService.errorRecoveryOptions
        XCTAssertTrue(options.contains { $0.title == "Check Storage" })
        XCTAssertTrue(options.contains { $0.title == "Dismiss" })
    }

    func testErrorHandling_CreatesCorrectRecoveryOptions_ForLoadFailure() async {
        // Given
        let testError = UserPreferencesError.loadFailure(underlying: "Test error")

        // When
        await self.userPreferencesService.handleError(testError, operation: "load equipment")

        // Then
        let options = self.userPreferencesService.errorRecoveryOptions
        XCTAssertTrue(options.contains { $0.title == "Retry" })
        XCTAssertTrue(options.contains { $0.title == "Use Defaults" })
        XCTAssertTrue(options.contains { $0.title == "Dismiss" })
    }

    func testErrorHandling_CreatesCorrectRecoveryOptions_ForConcurrentModification() async {
        // Given
        let testError = UserPreferencesError.concurrentModification

        // When
        await self.userPreferencesService.handleError(testError, operation: "update plan")

        // Then
        let options = self.userPreferencesService.errorRecoveryOptions
        XCTAssertTrue(options.contains { $0.title == "Retry" })
        XCTAssertTrue(options.contains { $0.title == "Refresh Data" })
        XCTAssertTrue(options.contains { $0.title == "Dismiss" })
    }

    // MARK: - Error Clearing Tests

    func testClearError_ResetsAllErrorState() async {
        // Given
        let testError = UserPreferencesError.dataCorruption
        await self.userPreferencesService.handleError(testError, operation: "test")
        XCTAssertNotNil(self.userPreferencesService.lastError)
        XCTAssertTrue(self.userPreferencesService.showingErrorAlert)
        XCTAssertFalse(self.userPreferencesService.errorRecoveryOptions.isEmpty)

        // When
        await self.userPreferencesService.clearError()

        // Then
        XCTAssertNil(self.userPreferencesService.lastError)
        XCTAssertFalse(self.userPreferencesService.showingErrorAlert)
        XCTAssertTrue(self.userPreferencesService.errorRecoveryOptions.isEmpty)
    }

    // MARK: - Data Integrity Tests

    func testDataIntegrity_ValidData_LoadsCorrectly() async {
        // Given - Add valid test data
        let equipment = [
            EquipmentItem(id: "1", name: "Barbell", category: "Strength", isSelected: true),
            EquipmentItem(id: "2", name: "Dumbbells", category: "Strength", isSelected: false)
        ]

        let plan = WorkoutPlanData(
            name: "Test Plan",
            exercises: [
                ExerciseData(name: "Squat", sets: 3, reps: 10, weight: 100, restTime: 60, orderIndex: 0)
            ]
        )

        do {
            try await self.userPreferencesService.saveEquipmentSelection(equipment)
            try await self.userPreferencesService.savePlan(plan)
        } catch {
            XCTFail("Setup failed: \(error)")
        }

        // When - Load data back
        do {
            try await self.userPreferencesService.loadSelectedEquipment()
            try await self.userPreferencesService.loadSavedPlans()

            // Then - Verify data integrity
            XCTAssertEqual(self.userPreferencesService.selectedEquipment.count, 2)
            XCTAssertEqual(self.userPreferencesService.savedPlans.count, 1)
            XCTAssertEqual(self.userPreferencesService.savedPlans.first?.name, "Test Plan")
        } catch {
            XCTFail("Data integrity test failed: \(error)")
        }
    }

    func testDataPersistence_EquipmentSelection_PersistsCorrectly() async {
        // Given
        let equipment = [
            EquipmentItem(id: "1", name: "Barbell", category: "Strength", isSelected: true),
            EquipmentItem(id: "2", name: "Dumbbells", category: "Strength", isSelected: false)
        ]

        // When - Save and reload
        do {
            try await self.userPreferencesService.saveEquipmentSelection(equipment)

            // Clear local state
            self.userPreferencesService.selectedEquipment = []

            // Reload from persistence
            try await self.userPreferencesService.loadSelectedEquipment()

            // Then
            XCTAssertEqual(self.userPreferencesService.selectedEquipment.count, 2)
            XCTAssertEqual(self.userPreferencesService.selectedEquipment.first?.name, "Barbell")
            XCTAssertTrue(self.userPreferencesService.selectedEquipment.first?.isSelected ?? false)
        } catch {
            XCTFail("Equipment persistence test failed: \(error)")
        }
    }

    func testDataPersistence_WorkoutPlans_PersistsCorrectly() async {
        // Given
        let plan = WorkoutPlanData(
            name: "Test Plan",
            exercises: [
                ExerciseData(name: "Squat", sets: 3, reps: 10, weight: 100, restTime: 60, orderIndex: 0),
                ExerciseData(name: "Bench Press", sets: 3, reps: 8, weight: 80, restTime: 90, orderIndex: 1)
            ]
        )

        // When - Save and reload
        do {
            try await self.userPreferencesService.savePlan(plan)

            // Clear local state
            self.userPreferencesService.savedPlans = []

            // Reload from persistence
            try await self.userPreferencesService.loadSavedPlans()

            // Then
            XCTAssertEqual(self.userPreferencesService.savedPlans.count, 1)
            XCTAssertEqual(self.userPreferencesService.savedPlans.first?.name, "Test Plan")
            XCTAssertEqual(self.userPreferencesService.savedPlans.first?.exercises.count, 2)
        } catch {
            XCTFail("Plan persistence test failed: \(error)")
        }
    }

    func testDataRecovery_ClearErrorState_Success() async {
        // Given - Set an error state
        let testError = UserPreferencesError.saveFailure(underlying: "Test error")
        await self.userPreferencesService.handleError(testError, operation: "test operation")

        XCTAssertNotNil(self.userPreferencesService.lastError)

        // When - Clear the error
        await self.userPreferencesService.clearError()

        // Then - Error state should be cleared
        XCTAssertNil(self.userPreferencesService.lastError)
        XCTAssertFalse(self.userPreferencesService.showingErrorAlert)
        XCTAssertTrue(self.userPreferencesService.errorRecoveryOptions.isEmpty)
    }

    // MARK: - Setup State Tests

    func testSetupCompletion_WithEquipment_ReturnsTrue() async {
        // Given - Add equipment
        let equipment = [
            EquipmentItem(id: "1", name: "Barbell", category: "Strength", isSelected: true)
        ]

        do {
            try await self.userPreferencesService.saveEquipmentSelection(equipment)

            // When
            let isComplete = try await userPreferencesService.checkSetupCompletion()

            // Then
            XCTAssertTrue(isComplete)
            XCTAssertTrue(self.userPreferencesService.hasCompletedSetup)
        } catch {
            XCTFail("Setup completion test failed: \(error)")
        }
    }

    func testSetupCompletion_WithoutEquipment_ReturnsFalse() async {
        // Given - No equipment

        do {
            // When
            let isComplete = try await userPreferencesService.checkSetupCompletion()

            // Then
            XCTAssertFalse(isComplete)
            XCTAssertFalse(self.userPreferencesService.hasCompletedSetup)
        } catch {
            XCTFail("Setup completion test failed: \(error)")
        }
    }

    // MARK: - Equipment Update Tests

    func testEquipmentUpdate_SingleItem_UpdatesCorrectly() async {
        // Given - Add initial equipment
        let equipment = [
            EquipmentItem(id: "1", name: "Barbell", category: "Strength", isSelected: false),
            EquipmentItem(id: "2", name: "Dumbbells", category: "Strength", isSelected: false)
        ]

        do {
            try await self.userPreferencesService.saveEquipmentSelection(equipment)

            // When - Update single item
            let updatedItem = EquipmentItem(id: "1", name: "Barbell", category: "Strength", isSelected: true)
            try await userPreferencesService.updateEquipmentSelection(updatedItem, isSelected: true)

            // Then - Verify update
            let selectedItem = self.userPreferencesService.selectedEquipment.first { $0.id == "1" }
            XCTAssertTrue(selectedItem?.isSelected ?? false)
        } catch {
            XCTFail("Equipment update test failed: \(error)")
        }
    }
}

// MARK: - Error Recovery Option Tests

final class ErrorRecoveryOptionTests: XCTestCase {
    func testErrorRecoveryOption_Initialization() {
        // Given
        var actionCalled = false

        // When
        let option = ErrorRecoveryOption(
            title: "Test Action",
            description: "Test description",
            isDestructive: true
        ) {
            actionCalled = true
        }

        // Then
        XCTAssertEqual(option.title, "Test Action")
        XCTAssertEqual(option.description, "Test description")
        XCTAssertTrue(option.isDestructive)
        XCTAssertNotNil(option.id)

        // Test action execution
        Task {
            await option.action()
            XCTAssertTrue(actionCalled)
        }
    }

    func testErrorRecoveryOption_DefaultValues() {
        // When
        let option = ErrorRecoveryOption(
            title: "Test",
            description: "Description"
        ) {}

        // Then
        XCTAssertFalse(option.isDestructive) // Default should be false
    }
}

// MARK: - UserPreferencesError Tests

final class UserPreferencesErrorTests: XCTestCase {
    func testErrorSeverity_Warning() {
        let errors: [UserPreferencesError] = [
            .networkUnavailable,
            .operationTimeout
        ]

        for error in errors {
            XCTAssertEqual(error.severity, .warning, "Error \(error) should have warning severity")
        }
    }

    func testErrorSeverity_Error() {
        let errors: [UserPreferencesError] = [
            .invalidData(field: "test"),
            .planNotFound(id: UUID()),
            .equipmentNotFound(id: "test"),
            .concurrentModification,
            .saveFailure(underlying: "test"),
            .loadFailure(underlying: "test")
        ]

        for error in errors {
            XCTAssertEqual(error.severity, .error, "Error \(error) should have error severity")
        }
    }

    func testErrorSeverity_Critical() {
        let errors: [UserPreferencesError] = [
            .dataCorruption,
            .insufficientStorage,
            .migrationFailure(version: "1.0")
        ]

        for error in errors {
            XCTAssertEqual(error.severity, .critical, "Error \(error) should have critical severity")
        }
    }

    func testErrorRecoverability() {
        let recoverableErrors: [UserPreferencesError] = [
            .networkUnavailable,
            .operationTimeout,
            .concurrentModification,
            .insufficientStorage,
            .invalidData(field: "test"),
            .planNotFound(id: UUID()),
            .equipmentNotFound(id: "test"),
            .saveFailure(underlying: "test"),
            .loadFailure(underlying: "test")
        ]

        let nonRecoverableErrors: [UserPreferencesError] = [
            .dataCorruption,
            .migrationFailure(version: "1.0")
        ]

        for error in recoverableErrors {
            XCTAssertTrue(error.isRecoverable, "Error \(error) should be recoverable")
        }

        for error in nonRecoverableErrors {
            XCTAssertFalse(error.isRecoverable, "Error \(error) should not be recoverable")
        }
    }

    func testErrorRetryability() {
        let retryableErrors: [UserPreferencesError] = [
            .networkUnavailable,
            .operationTimeout,
            .saveFailure(underlying: "test"),
            .loadFailure(underlying: "test"),
            .concurrentModification
        ]

        let nonRetryableErrors: [UserPreferencesError] = [
            .dataCorruption,
            .invalidData(field: "test"),
            .planNotFound(id: UUID()),
            .equipmentNotFound(id: "test"),
            .insufficientStorage,
            .migrationFailure(version: "1.0")
        ]

        for error in retryableErrors {
            XCTAssertTrue(error.canRetry, "Error \(error) should be retryable")
        }

        for error in nonRetryableErrors {
            XCTAssertFalse(error.canRetry, "Error \(error) should not be retryable")
        }
    }
}

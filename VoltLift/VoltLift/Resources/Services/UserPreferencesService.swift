//
//  UserPreferencesService.swift
//  VoltLift
//
//  Created by Kiro on 15.9.2025.
//

import Combine
import CoreData
import Foundation

/// Service responsible for managing user equipment preferences and workout plans
/// Provides persistent storage using Core Data with error handling and retry logic
@MainActor
class UserPreferencesService: ObservableObject {
    // MARK: - Published Properties

    @Published var selectedEquipment: [EquipmentItem] = []
    @Published var savedPlans: [WorkoutPlanData] = []
    @Published var hasCompletedSetup: Bool = false
    @Published var isLoading: Bool = false
    @Published var lastError: UserPreferencesError?
    @Published var loadingMessage: String = ""
    @Published var operationInProgress: String?
    @Published var showingErrorAlert: Bool = false
    @Published var errorRecoveryOptions: [ErrorRecoveryOption] = []

    // MARK: - Private Properties

    private let persistenceController: PersistenceController
    private let maxRetryAttempts: Int = 3
    private let retryDelay: TimeInterval = 1.0

    // Performance optimization properties
    private var lazyLoadedPlans: [UUID: WorkoutPlanData] = [:]
    private var planMetadataCache: [WorkoutPlanMetadata] = []
    private let backgroundQueue = DispatchQueue(label: "com.voltlift.userpreferences.background", qos: .utility)
    private let batchSize: Int = 50

    // MARK: - Internal Properties for Testing

    /// Internal access to lazy loaded plans count for testing purposes
    var cachedPlansCount: Int {
        self.lazyLoadedPlans.count
    }

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Equipment Management

    /// Loads selected equipment from Core Data
    /// - Throws: UserPreferencesError if loading fails
    func loadSelectedEquipment() async throws {
        setLoadingState(true, message: "Loading your equipment...")
        self.operationInProgress = "Loading equipment"
        defer {
            isLoading = false
            loadingMessage = ""
            operationInProgress = nil
        }

        do {
            let equipment = try await performWithRetry {
                try await self.fetchEquipmentFromCoreData()
            }

            self.selectedEquipment = equipment
            clearError()
        } catch {
            let preferencesError = mapError(error, operation: "load equipment")
            handleError(preferencesError, operation: "loading equipment")
            throw preferencesError
        }
    }

    /// Saves equipment selection to Core Data
    /// - Parameter equipment: Array of equipment items to save
    /// - Throws: UserPreferencesError if saving fails
    func saveEquipmentSelection(_ equipment: [EquipmentItem]) async throws {
        setLoadingState(true, message: "Saving your equipment selection...")
        self.operationInProgress = "Saving equipment"
        defer {
            isLoading = false
            loadingMessage = ""
            operationInProgress = nil
        }

        do {
            try await performWithRetry {
                try await self.saveEquipmentToCoreData(equipment)
            }

            self.selectedEquipment = equipment
            clearError()
        } catch {
            let preferencesError = mapError(error, operation: "save equipment")
            handleError(preferencesError, operation: "saving equipment")
            throw preferencesError
        }
    }

    /// Updates a single equipment item's selection status
    /// - Parameters:
    ///   - equipment: The equipment item to update
    ///   - isSelected: New selection status
    /// - Throws: UserPreferencesError if update fails
    func updateEquipmentSelection(_ equipment: EquipmentItem, isSelected: Bool) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            try await performWithRetry {
                try await self.updateEquipmentInCoreData(equipment, isSelected: isSelected)
            }

            // Update local state
            if let index = selectedEquipment.firstIndex(where: { $0.id == equipment.id }) {
                self.selectedEquipment[index] = EquipmentItem(
                    id: equipment.id,
                    name: equipment.name,
                    category: equipment.category,
                    isSelected: isSelected
                )
            }

            self.lastError = nil
        } catch {
            let preferencesError = mapError(error, operation: "update equipment")
            self.lastError = preferencesError
            throw preferencesError
        }
    }

    // MARK: - Workout Plan Management

    /// Loads all saved workout plans from Core Data
    /// - Throws: UserPreferencesError if loading fails
    func loadSavedPlans() async throws {
        setLoadingState(true, message: "Loading your workout plans...")
        self.operationInProgress = "Loading plans"
        defer {
            isLoading = false
            loadingMessage = ""
            operationInProgress = nil
        }

        do {
            let plans = try await performWithRetry {
                try await self.fetchPlansFromCoreData()
            }

            self.savedPlans = plans
            clearError()
        } catch {
            let preferencesError = mapError(error, operation: "load plans")
            handleError(preferencesError, operation: "loading plans")
            throw preferencesError
        }
    }

    /// Saves a workout plan with automatic JSON serialization
    /// - Parameters:
    ///   - plan: The workout plan data to save
    ///   - name: Custom name for the plan (optional, uses plan.name if nil)
    /// - Throws: UserPreferencesError if saving fails
    func savePlan(_ plan: WorkoutPlanData, name: String? = nil) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let planToSave = name != nil ? WorkoutPlanData(
                id: plan.id,
                name: name ?? plan.name,
                exercises: plan.exercises,
                createdDate: plan.createdDate,
                lastUsedDate: plan.lastUsedDate
            ) : plan

            try await performWithRetry {
                try await self.savePlanToCoreData(planToSave)
            }

            // Update local state
            if let index = savedPlans.firstIndex(where: { $0.id == planToSave.id }) {
                self.savedPlans[index] = planToSave
            } else {
                self.savedPlans.append(planToSave)
            }

            self.lastError = nil
        } catch {
            let preferencesError = mapError(error, operation: "save plan")
            self.lastError = preferencesError
            throw preferencesError
        }
    }

    /// Deletes a workout plan by ID
    /// - Parameter planId: UUID of the plan to delete
    /// - Throws: UserPreferencesError if deletion fails
    func deletePlan(_ planId: UUID) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            try await performWithRetry {
                try await self.deletePlanFromCoreData(planId)
            }

            // Update local state
            self.savedPlans.removeAll { $0.id == planId }
            self.lastError = nil
        } catch {
            let preferencesError = mapError(error, operation: "delete plan")
            self.lastError = preferencesError
            throw preferencesError
        }
    }

    /// Renames a workout plan
    /// - Parameters:
    ///   - planId: UUID of the plan to rename
    ///   - newName: New name for the plan
    /// - Throws: UserPreferencesError if renaming fails
    func renamePlan(_ planId: UUID, newName: String) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            try await performWithRetry {
                try await self.renamePlanInCoreData(planId, newName: newName)
            }

            // Update local state
            if let index = savedPlans.firstIndex(where: { $0.id == planId }) {
                let existingPlan = self.savedPlans[index]
                self.savedPlans[index] = WorkoutPlanData(
                    id: existingPlan.id,
                    name: newName,
                    exercises: existingPlan.exercises,
                    createdDate: existingPlan.createdDate,
                    lastUsedDate: existingPlan.lastUsedDate
                )
            }

            self.lastError = nil
        } catch {
            let preferencesError = mapError(error, operation: "rename plan")
            self.lastError = preferencesError
            throw preferencesError
        }
    }

    /// Marks a workout plan as used by updating its last used date
    /// - Parameter planId: UUID of the plan to mark as used
    /// - Throws: UserPreferencesError if update fails
    func markPlanAsUsed(_ planId: UUID) async throws {
        self.isLoading = true
        defer { isLoading = false }

        do {
            let currentDate = Date()

            try await performWithRetry {
                try await self.updatePlanLastUsedDate(planId, date: currentDate)
            }

            // Update local state
            if let index = savedPlans.firstIndex(where: { $0.id == planId }) {
                let existingPlan = self.savedPlans[index]
                self.savedPlans[index] = WorkoutPlanData(
                    id: existingPlan.id,
                    name: existingPlan.name,
                    exercises: existingPlan.exercises,
                    createdDate: existingPlan.createdDate,
                    lastUsedDate: currentDate
                )
            }

            self.lastError = nil
        } catch {
            let preferencesError = mapError(error, operation: "mark plan as used")
            self.lastError = preferencesError
            throw preferencesError
        }
    }

    // MARK: - Setup State Management

    /// Checks if user has completed initial setup
    /// - Returns: True if setup is complete, false otherwise
    /// - Throws: UserPreferencesError if check fails
    func checkSetupCompletion() async throws -> Bool {
        do {
            let hasEquipment = try await performWithRetry {
                try await self.hasSelectedEquipmentInCoreData()
            }

            self.hasCompletedSetup = hasEquipment
            self.lastError = nil
            return hasEquipment
        } catch {
            let preferencesError = mapError(error, operation: "check setup completion")
            self.lastError = preferencesError
            throw preferencesError
        }
    }

    /// Marks setup as complete by ensuring equipment selection exists
    /// - Throws: UserPreferencesError if marking fails
    func markSetupComplete() async throws {
        do {
            let isComplete = try await checkSetupCompletion()

            if !isComplete {
                throw UserPreferencesError.invalidData(field: "equipment selection")
            }

            self.hasCompletedSetup = true
            self.lastError = nil
        } catch {
            let preferencesError = mapError(error, operation: "mark setup complete")
            self.lastError = preferencesError
            throw preferencesError
        }
    }
}

// MARK: - Private Core Data Methods

private extension UserPreferencesService {
    /// Fetches equipment from Core Data
    /// - Returns: Array of EquipmentItem
    /// - Throws: Error if fetch fails
    func fetchEquipmentFromCoreData() async throws -> [EquipmentItem] {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
                    request.sortDescriptors = [NSSortDescriptor(keyPath: \UserEquipment.name, ascending: true)]

                    let coreDataEquipment = try context.fetch(request)

                    let equipment = coreDataEquipment.map { entity in
                        EquipmentItem(
                            id: entity.equipmentId ?? UUID().uuidString,
                            name: entity.name ?? "",
                            category: entity.category ?? "Other",
                            isSelected: entity.isSelected
                        )
                    }

                    continuation.resume(returning: equipment)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Saves equipment to Core Data
    /// - Parameter equipment: Array of EquipmentItem to save
    /// - Throws: Error if save fails
    func saveEquipmentToCoreData(_ equipment: [EquipmentItem]) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    // Clear existing equipment
                    let deleteRequest = NSBatchDeleteRequest(
                        fetchRequest: UserEquipment.fetchRequest() as! NSFetchRequest<NSFetchRequestResult>
                    )
                    try context.execute(deleteRequest)

                    // Add new equipment
                    for item in equipment {
                        let entity = UserEquipment(context: context)
                        entity.equipmentId = item.id
                        entity.name = item.name
                        entity.category = item.category
                        entity.isSelected = item.isSelected
                        entity.dateAdded = Date()
                    }

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Updates a single equipment item in Core Data
    /// - Parameters:
    ///   - equipment: Equipment item to update
    ///   - isSelected: New selection status
    /// - Throws: Error if update fails
    func updateEquipmentInCoreData(_ equipment: EquipmentItem, isSelected: Bool) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
                    request.predicate = NSPredicate(format: "equipmentId == %@", equipment.id)
                    request.fetchLimit = 1

                    let results = try context.fetch(request)

                    if let entity = results.first {
                        entity.isSelected = isSelected
                    } else {
                        // Create new entity if it doesn't exist
                        let entity = UserEquipment(context: context)
                        entity.equipmentId = equipment.id
                        entity.name = equipment.name
                        entity.category = equipment.category
                        entity.isSelected = isSelected
                        entity.dateAdded = Date()
                    }

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Checks if user has selected equipment in Core Data
    /// - Returns: True if equipment exists, false otherwise
    /// - Throws: Error if check fails
    func hasSelectedEquipmentInCoreData() async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
                    request.predicate = NSPredicate(format: "isSelected == YES")
                    request.fetchLimit = 1

                    let count = try context.count(for: request)
                    continuation.resume(returning: count > 0)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Fetches all workout plans from Core Data
    /// - Returns: Array of WorkoutPlanData
    /// - Throws: Error if fetch fails
    func fetchPlansFromCoreData() async throws -> [WorkoutPlanData] {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
                    request.sortDescriptors = [
                        NSSortDescriptor(keyPath: \WorkoutPlan.lastUsedDate, ascending: false),
                        NSSortDescriptor(keyPath: \WorkoutPlan.createdDate, ascending: false)
                    ]

                    let coreDataPlans = try context.fetch(request)

                    let plans = try coreDataPlans.compactMap { entity -> WorkoutPlanData? in
                        guard let planId = entity.planId,
                              let name = entity.name,
                              let createdDate = entity.createdDate,
                              let planData = entity.planData
                        else {
                            return nil
                        }

                        // Deserialize exercises from JSON
                        let exercises = try self.deserializeExercises(from: planData)

                        return WorkoutPlanData(
                            id: planId,
                            name: name,
                            exercises: exercises,
                            createdDate: createdDate,
                            lastUsedDate: entity.lastUsedDate
                        )
                    }

                    continuation.resume(returning: plans)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Saves a workout plan to Core Data with JSON serialization
    /// - Parameter plan: WorkoutPlanData to save
    /// - Throws: Error if save fails
    func savePlanToCoreData(_ plan: WorkoutPlanData) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    // Check if plan already exists
                    let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
                    request.predicate = NSPredicate(format: "planId == %@", plan.id as CVarArg)
                    request.fetchLimit = 1

                    let existingPlans = try context.fetch(request)
                    let entity = existingPlans.first ?? WorkoutPlan(context: context)

                    // Serialize exercises to JSON
                    let exerciseData = try self.serializeExercises(plan.exercises)

                    // Update entity properties
                    entity.planId = plan.id
                    entity.name = plan.name
                    entity.createdDate = plan.createdDate
                    entity.lastUsedDate = plan.lastUsedDate
                    entity.exerciseCount = Int32(plan.exerciseCount)
                    entity.planData = exerciseData

                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Deletes a workout plan from Core Data
    /// - Parameter planId: UUID of the plan to delete
    /// - Throws: Error if deletion fails
    func deletePlanFromCoreData(_ planId: UUID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
                    request.predicate = NSPredicate(format: "planId == %@", planId as CVarArg)
                    request.fetchLimit = 1

                    let plans = try context.fetch(request)

                    guard let planToDelete = plans.first else {
                        continuation.resume(throwing: UserPreferencesError.planNotFound(id: planId))
                        return
                    }

                    context.delete(planToDelete)
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Renames a workout plan in Core Data
    /// - Parameters:
    ///   - planId: UUID of the plan to rename
    ///   - newName: New name for the plan
    /// - Throws: Error if renaming fails
    func renamePlanInCoreData(_ planId: UUID, newName: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
                    request.predicate = NSPredicate(format: "planId == %@", planId as CVarArg)
                    request.fetchLimit = 1

                    let plans = try context.fetch(request)

                    guard let planToRename = plans.first else {
                        continuation.resume(throwing: UserPreferencesError.planNotFound(id: planId))
                        return
                    }

                    planToRename.name = newName
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Updates the last used date for a workout plan
    /// - Parameters:
    ///   - planId: UUID of the plan to update
    ///   - date: New last used date
    /// - Throws: Error if update fails
    func updatePlanLastUsedDate(_ planId: UUID, date: Date) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.persistenceController.newBackgroundContext()

            context.perform {
                do {
                    let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
                    request.predicate = NSPredicate(format: "planId == %@", planId as CVarArg)
                    request.fetchLimit = 1

                    let plans = try context.fetch(request)

                    guard let planToUpdate = plans.first else {
                        continuation.resume(throwing: UserPreferencesError.planNotFound(id: planId))
                        return
                    }

                    planToUpdate.lastUsedDate = date
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - JSON Serialization Helpers

    /// Serializes exercises to JSON data
    /// - Parameter exercises: Array of ExerciseData to serialize
    /// - Returns: JSON data
    /// - Throws: Error if serialization fails
    func serializeExercises(_ exercises: [ExerciseData]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(exercises)
    }

    /// Deserializes exercises from JSON data
    /// - Parameter data: JSON data to deserialize
    /// - Returns: Array of ExerciseData
    /// - Throws: Error if deserialization fails
    func deserializeExercises(from data: Data) throws -> [ExerciseData] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ExerciseData].self, from: data)
    }
}

// MARK: - Error Handling and Recovery

extension UserPreferencesService {
    /// Sets the loading state with an optional message
    /// - Parameters:
    ///   - loading: Whether loading is in progress
    ///   - message: Optional loading message to display
    private func setLoadingState(_ loading: Bool, message: String = "") {
        self.isLoading = loading
        self.loadingMessage = message
    }

    /// Clears the current error state
    func clearError() {
        self.lastError = nil
        self.showingErrorAlert = false
        self.errorRecoveryOptions = []
    }

    /// Handles an error by setting appropriate state and recovery options
    /// - Parameters:
    ///   - error: The error to handle
    ///   - operation: Description of the operation that failed
    func handleError(_ error: UserPreferencesError, operation: String) {
        self.lastError = error
        self.errorRecoveryOptions = self.createRecoveryOptions(for: error, operation: operation)

        // Show alert for critical errors or non-recoverable errors
        if error.severity == .critical || !error.isRecoverable {
            self.showingErrorAlert = true
        }
    }

    /// Creates recovery options for a given error
    /// - Parameters:
    ///   - error: The error to create recovery options for
    ///   - operation: Description of the operation that failed
    /// - Returns: Array of recovery options
    private func createRecoveryOptions(for error: UserPreferencesError, operation: String) -> [ErrorRecoveryOption] {
        var options: [ErrorRecoveryOption] = []

        // Add retry option for retryable errors
        if error.canRetry {
            options.append(ErrorRecoveryOption(
                title: "Retry",
                description: "Try the operation again"
            ) {
                // Implementation would retry the last operation
            })
        }

        // Always add dismiss option
        options.append(ErrorRecoveryOption(
            title: "Dismiss",
            description: "Close this error message"
        ) {
            await self.clearError()
        })

        return options
    }

    /// Performs an operation with retry logic
    /// - Parameter operation: The async operation to perform
    /// - Returns: Result of the operation
    /// - Throws: Error if all retry attempts fail
    func performWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?

        for attempt in 1 ... self.maxRetryAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error

                // Don't retry for certain error types
                if let preferencesError = error as? UserPreferencesError,
                   !preferencesError.canRetry
                {
                    throw error
                }

                // Wait before retrying (exponential backoff)
                if attempt < self.maxRetryAttempts {
                    let delay = self.retryDelay * pow(2.0, Double(attempt - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }

        throw lastError ?? UserPreferencesError.operationTimeout
    }

    /// Maps generic errors to UserPreferencesError
    /// - Parameters:
    ///   - error: The original error
    ///   - operation: Description of the operation that failed
    /// - Returns: Mapped UserPreferencesError
    func mapError(_ error: Error, operation: String) -> UserPreferencesError {
        if let preferencesError = error as? UserPreferencesError {
            return preferencesError
        }

        // Map Core Data errors
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSCoreDataError:
                return .dataCorruption
            case NSFileWriteFileExistsError, NSFileWriteNoPermissionError:
                return .saveFailure(underlying: nsError.localizedDescription)
            case NSFileReadNoSuchFileError:
                return .loadFailure(underlying: nsError.localizedDescription)
            default:
                break
            }
        }

        // Default mapping
        if operation.contains("save") {
            return .saveFailure(underlying: error.localizedDescription)
        } else if operation.contains("load") || operation.contains("fetch") {
            return .loadFailure(underlying: error.localizedDescription)
        } else {
            return .loadFailure(underlying: error.localizedDescription)
        }
    }
}

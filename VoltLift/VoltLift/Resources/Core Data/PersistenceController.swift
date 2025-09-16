//
//  PersistenceController.swift
//  VoltLift
//
//  Created by Kiro on 14.9.2025.
//

import CoreData
import Foundation

/// Manages Core Data stack for VoltLift app
struct PersistenceController {
    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Preview Support

    /// Preview instance for SwiftUI previews with in-memory store
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Add sample data for previews
        let sampleMetadata = ExerciseMetadata(context: viewContext)
        sampleMetadata.exerciseId = UUID()
        sampleMetadata.name = "Push-up"
        sampleMetadata.lastUsed = Date()
        sampleMetadata.usageCount = 5
        sampleMetadata.personalNotes = "Great for chest development"

        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    // MARK: - Core Data Stack

    let container: NSPersistentContainer

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        self.container = NSPersistentContainer(name: "VoltLift")

        if inMemory {
            if let description = self.container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            }
        }

        // Configure persistent store descriptions for better performance
        for storeDescription in self.container.persistentStoreDescriptions {
            storeDescription.shouldInferMappingModelAutomatically = true
            storeDescription.shouldMigrateStoreAutomatically = true

            // Enable persistent history tracking for CloudKit sync (future feature)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        self.container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.

                // Typical reasons for an error here include:
                // * The parent directory does not exist, cannot be created, or disallows writing.
                // * The persistent store is not accessible, due to permissions or data protection when the device is
                // locked.
                // * The device is out of space.
                // * The store could not be migrated to the current model version.
                fatalError("Unresolved error \(error), \((error as NSError).userInfo)")
            }
        }

        // Configure view context for better performance
        self.container.viewContext.automaticallyMergesChangesFromParent = true
        self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save Context

    /// Saves the view context if there are changes
    func save() {
        let context = self.container.viewContext

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    /// Creates a new background context for performing operations off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = self.container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Performance optimizations for background contexts
        context.undoManager = nil // Disable undo for better performance
        context.shouldDeleteInaccessibleFaults = true

        return context
    }

    /// Creates a new background context optimized for batch operations
    func newBatchContext() -> NSManagedObjectContext {
        let context = self.newBackgroundContext()

        // Additional optimizations for batch operations
        context.automaticallyMergesChangesFromParent = false
        context.stalenessInterval = 0.0 // Always use fresh data

        return context
    }

    /// Performs a background save operation with proper error handling
    /// - Parameter operation: The operation to perform in the background context
    /// - Returns: Result of the operation
    func performBackgroundTask<T>(_ operation: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let context = self.newBatchContext()

            context.perform {
                do {
                    let result = try operation(context)

                    if context.hasChanges {
                        try context.save()
                    }

                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Initializes migration support and validates data integrity
    /// Should be called after the PersistenceController is created
    func initializeMigrationSupport() {
        // Check if migration is needed and perform validation
        do {
            if needsMigration {
                _ = try performMigrationIfNeeded()
            }

            // Always validate data integrity on startup
            try validateDataIntegrity()
        } catch {
            // If validation fails, attempt corruption recovery
            let hadCorruption = detectAndHandleCorruption()

            if hadCorruption {
                print("Data corruption detected and cleaned up")
            } else {
                print("Migration or validation failed: \(error)")
            }
        }
    }
}

// MARK: - Migration Support

extension PersistenceController {
    /// Migration errors that can occur during Core Data migration
    enum MigrationError: LocalizedError {
        case storeNotFound
        case migrationFailed(underlying: Error)
        case dataCorruption
        case backupFailed
        case validationFailed(String)

        var errorDescription: String? {
            switch self {
            case .storeNotFound:
                "Core Data store not found"
            case let .migrationFailed(error):
                "Migration failed: \(error.localizedDescription)"
            case .dataCorruption:
                "Data corruption detected"
            case .backupFailed:
                "Failed to create backup before migration"
            case let .validationFailed(message):
                "Data validation failed: \(message)"
            }
        }
    }

    /// Checks if Core Data migration is needed
    var needsMigration: Bool {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            return false
        }

        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL,
                options: nil
            )

            let model = self.container.managedObjectModel
            return !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            return false
        }
    }

    /// Performs Core Data migration with backup and validation
    /// - Returns: True if migration was successful, false otherwise
    /// - Throws: MigrationError if migration fails
    func performMigrationIfNeeded() throws -> Bool {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else {
            throw MigrationError.storeNotFound
        }

        // Check if migration is needed
        guard self.needsMigration else {
            return false // No migration needed
        }

        // Create backup before migration
        try self.createBackup(storeURL: storeURL)

        // Perform migration
        do {
            try self.migrateStore(storeURL: storeURL)

            // Validate data after migration
            try self.validateDataIntegrity()

            return true
        } catch {
            // Restore from backup if migration fails
            try self.restoreFromBackup(storeURL: storeURL)
            throw MigrationError.migrationFailed(underlying: error)
        }
    }

    /// Creates a backup of the Core Data store before migration
    private func createBackup(storeURL: URL) throws {
        let backupURL = storeURL.appendingPathExtension("backup")
        let fileManager = FileManager.default

        // Remove existing backup
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }

        // Create new backup
        do {
            try fileManager.copyItem(at: storeURL, to: backupURL)
        } catch {
            throw MigrationError.backupFailed
        }
    }

    /// Restores Core Data store from backup
    private func restoreFromBackup(storeURL: URL) throws {
        let backupURL = storeURL.appendingPathExtension("backup")
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: backupURL.path) else {
            return // No backup available
        }

        // Remove corrupted store
        if fileManager.fileExists(atPath: storeURL.path) {
            try fileManager.removeItem(at: storeURL)
        }

        // Restore from backup
        try fileManager.copyItem(at: backupURL, to: storeURL)
    }

    /// Performs the actual Core Data migration
    private func migrateStore(storeURL: URL) throws {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: container.managedObjectModel)

        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]

        do {
            try coordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: options
            )

            // After successful migration, perform data migration for PlanExercise entities
            try self.migratePlanExerciseData()

        } catch {
            throw error
        }
    }

    /// Migrates PlanExercise entities from legacy format to new set-based format
    private func migratePlanExerciseData() throws {
        let context = self.container.viewContext
        let request: NSFetchRequest<PlanExercise> = PlanExercise.fetchRequest()

        do {
            let exercises = try context.fetch(request)
            var migratedCount = 0

            for exercise in exercises {
                // Check if this exercise needs migration (has legacy data but no setsData)
                if exercise.setsData == nil, exercise.sets > 0 {
                    try self.migrateSinglePlanExercise(exercise)
                    migratedCount += 1
                }
            }

            if migratedCount > 0 {
                try context.save()
                print("Successfully migrated \(migratedCount) PlanExercise entities to new format")
            }

        } catch {
            throw MigrationError.migrationFailed(underlying: error)
        }
    }

    /// Migrates a single PlanExercise entity from legacy format to new set-based format
    private func migrateSinglePlanExercise(_ exercise: PlanExercise) throws {
        // Extract legacy values
        let legacySets = Int(exercise.sets)
        let legacyReps = Int(exercise.reps)
        let legacyWeight = exercise.weight

        // Validate legacy values
        guard legacySets > 0, legacyReps > 0, legacyWeight >= 0 else {
            throw MigrationError
                .validationFailed("Invalid legacy values for PlanExercise: \(exercise.name ?? "unknown")")
        }

        // Create ExerciseSet array from legacy data
        let exerciseSets = (1 ... legacySets).map { setNumber in
            ExerciseSet(setNumber: setNumber, reps: legacyReps, weight: legacyWeight, setType: .normal)
        }

        // Serialize to JSON
        do {
            let setsData = try JSONEncoder().encode(exerciseSets)
            exercise.setsData = setsData

            // Update computed attributes
            exercise.totalSets = Int32(exerciseSets.count)
            exercise.averageWeight = legacyWeight

            print(
                "Migrated PlanExercise '\(exercise.name ?? "unknown")': \(legacySets) sets, \(legacyReps) reps, \(legacyWeight) weight"
            )

        } catch {
            throw MigrationError.migrationFailed(underlying: error)
        }
    }

    /// Validates data integrity after migration or on app launch
    func validateDataIntegrity() throws {
        let context = self.container.viewContext

        // Validate UserEquipment entities
        try self.validateUserEquipment(context: context)

        // Validate WorkoutPlan entities
        try self.validateWorkoutPlans(context: context)

        // Validate PlanExercise entities
        try self.validatePlanExercises(context: context)

        // Validate ExerciseMetadata entities
        try self.validateExerciseMetadata(context: context)
    }

    /// Validates UserEquipment entities for data corruption
    private func validateUserEquipment(context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()

        do {
            let equipment = try context.fetch(request)

            for item in equipment {
                // Check required fields
                guard let equipmentId = item.equipmentId, !equipmentId.isEmpty,
                      let name = item.name, !name.isEmpty
                else {
                    throw MigrationError.validationFailed("UserEquipment has invalid required fields")
                }

                // Check date validity
                guard let dateAdded = item.dateAdded, dateAdded <= Date() else {
                    throw MigrationError.validationFailed("UserEquipment has future dateAdded")
                }
            }
        } catch let error as MigrationError {
            throw error
        } catch {
            throw MigrationError.dataCorruption
        }
    }

    /// Validates WorkoutPlan entities for data corruption
    private func validateWorkoutPlans(context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()

        do {
            let plans = try context.fetch(request)

            for plan in plans {
                // Check required fields
                guard let name = plan.name, !name.isEmpty else {
                    throw MigrationError.validationFailed("WorkoutPlan has empty name")
                }

                // Check date validity
                guard let createdDate = plan.createdDate, createdDate <= Date() else {
                    throw MigrationError.validationFailed("WorkoutPlan has future createdDate")
                }

                if let lastUsed = plan.lastUsedDate {
                    guard lastUsed <= Date() else {
                        throw MigrationError.validationFailed("WorkoutPlan has future lastUsedDate")
                    }
                }

                // Check exercise count consistency
                guard plan.exerciseCount >= 0 else {
                    throw MigrationError.validationFailed("WorkoutPlan has negative exerciseCount")
                }

                // Validate planData is valid JSON
                do {
                    guard let planData = plan.planData else {
                        throw MigrationError.validationFailed("WorkoutPlan has nil planData")
                    }
                    _ = try JSONSerialization.jsonObject(with: planData)
                } catch {
                    throw MigrationError.validationFailed("WorkoutPlan has invalid planData JSON")
                }
            }
        } catch let error as MigrationError {
            throw error
        } catch {
            throw MigrationError.dataCorruption
        }
    }

    /// Validates PlanExercise entities for data corruption
    private func validatePlanExercises(context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<PlanExercise> = PlanExercise.fetchRequest()

        do {
            let exercises = try context.fetch(request)

            for exercise in exercises {
                // Check required fields
                guard let name = exercise.name, !name.isEmpty else {
                    throw MigrationError.validationFailed("PlanExercise has empty name")
                }

                // Check if this is a migrated exercise (has setsData) or legacy (has sets/reps/weight)
                if let setsData = exercise.setsData {
                    // Validate setsData is valid JSON
                    do {
                        let sets = try JSONDecoder().decode([ExerciseSet].self, from: setsData)
                        guard !sets.isEmpty else {
                            throw MigrationError.validationFailed("PlanExercise has empty sets array")
                        }

                        // Validate each set
                        for set in sets {
                            guard set.reps > 0, set.weight >= 0, set.setNumber > 0 else {
                                throw MigrationError.validationFailed("PlanExercise has invalid set values")
                            }
                        }
                    } catch {
                        throw MigrationError.validationFailed("PlanExercise has invalid setsData JSON")
                    }
                } else {
                    // Legacy validation for unmigrated exercises
                    guard exercise.sets > 0,
                          exercise.reps > 0,
                          exercise.weight >= 0
                    else {
                        throw MigrationError.validationFailed("PlanExercise has invalid legacy numeric values")
                    }
                }

                // Common validation
                guard exercise.restTime >= 0,
                      exercise.orderIndex >= 0
                else {
                    throw MigrationError.validationFailed("PlanExercise has invalid common values")
                }
            }
        } catch let error as MigrationError {
            throw error
        } catch {
            throw MigrationError.dataCorruption
        }
    }

    /// Validates ExerciseMetadata entities for data corruption
    private func validateExerciseMetadata(context: NSManagedObjectContext) throws {
        let request: NSFetchRequest<ExerciseMetadata> = ExerciseMetadata.fetchRequest()

        do {
            let metadata = try context.fetch(request)

            for item in metadata {
                // Check required fields
                guard let name = item.name, !name.isEmpty else {
                    throw MigrationError.validationFailed("ExerciseMetadata has empty name")
                }

                // Check date validity
                guard let lastUsed = item.lastUsed, lastUsed <= Date() else {
                    throw MigrationError.validationFailed("ExerciseMetadata has future lastUsed date")
                }

                // Check numeric validity
                guard item.usageCount >= 0,
                      item.customWeight >= 0
                else {
                    throw MigrationError.validationFailed("ExerciseMetadata has invalid numeric values")
                }
            }
        } catch let error as MigrationError {
            throw error
        } catch {
            throw MigrationError.dataCorruption
        }
    }

    /// Detects and handles data corruption
    func detectAndHandleCorruption() -> Bool {
        do {
            try self.validateDataIntegrity()
            return false // No corruption detected
        } catch {
            // Corruption detected, attempt recovery
            return self.handleDataCorruption()
        }
    }

    /// Handles data corruption by cleaning up invalid entities
    private func handleDataCorruption() -> Bool {
        let context = self.container.viewContext
        var hasCorruption = false

        // Clean up corrupted UserEquipment
        hasCorruption = self.cleanupCorruptedUserEquipment(context: context) || hasCorruption

        // Clean up corrupted WorkoutPlans
        hasCorruption = self.cleanupCorruptedWorkoutPlans(context: context) || hasCorruption

        // Clean up corrupted PlanExercises
        hasCorruption = self.cleanupCorruptedPlanExercises(context: context) || hasCorruption

        // Clean up corrupted ExerciseMetadata
        hasCorruption = self.cleanupCorruptedExerciseMetadata(context: context) || hasCorruption

        if hasCorruption {
            self.save()
        }

        return hasCorruption
    }

    /// Cleans up corrupted UserEquipment entities
    private func cleanupCorruptedUserEquipment(context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<UserEquipment> = UserEquipment.fetchRequest()
        var hasCorruption = false

        do {
            let equipment = try context.fetch(request)

            for item in equipment {
                let equipmentIdEmpty = item.equipmentId?.isEmpty ?? true
                let nameEmpty = item.name?.isEmpty ?? true
                let futureDateAdded = (item.dateAdded ?? Date.distantPast) > Date()

                if equipmentIdEmpty || nameEmpty || futureDateAdded {
                    context.delete(item)
                    hasCorruption = true
                }
            }
        } catch {
            // If we can't fetch, assume corruption and clear all
            let deleteRequest =
                NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "UserEquipment"))
            try? context.execute(deleteRequest)
            hasCorruption = true
        }

        return hasCorruption
    }

    /// Cleans up corrupted WorkoutPlan entities
    private func cleanupCorruptedWorkoutPlans(context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        var hasCorruption = false

        do {
            let plans = try context.fetch(request)

            for plan in plans {
                var shouldDelete = false

                // Check for corruption indicators
                let nameEmpty = plan.name?.isEmpty ?? true
                let futureDateCreated = (plan.createdDate ?? Date.distantPast) > Date()
                let negativeExerciseCount = plan.exerciseCount < 0

                if nameEmpty || futureDateCreated || negativeExerciseCount {
                    shouldDelete = true
                }

                // Check if planData is valid JSON
                if let planData = plan.planData {
                    do {
                        _ = try JSONSerialization.jsonObject(with: planData)
                    } catch {
                        shouldDelete = true
                    }
                } else {
                    shouldDelete = true
                }

                if shouldDelete {
                    context.delete(plan)
                    hasCorruption = true
                }
            }
        } catch {
            // If we can't fetch, assume corruption and clear all
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
            try? context.execute(deleteRequest)
            hasCorruption = true
        }

        return hasCorruption
    }

    /// Cleans up corrupted PlanExercise entities
    private func cleanupCorruptedPlanExercises(context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<PlanExercise> = PlanExercise.fetchRequest()
        var hasCorruption = false

        do {
            let exercises = try context.fetch(request)

            for exercise in exercises {
                var shouldDelete = false

                // Check required fields
                let nameEmpty = exercise.name?.isEmpty ?? true
                let invalidCommonValues = exercise.restTime < 0 || exercise.orderIndex < 0

                if nameEmpty || invalidCommonValues {
                    shouldDelete = true
                }

                // Check format-specific validity
                if let setsData = exercise.setsData {
                    // New format validation
                    do {
                        let sets = try JSONDecoder().decode([ExerciseSet].self, from: setsData)
                        if sets.isEmpty {
                            shouldDelete = true
                        }
                    } catch {
                        shouldDelete = true
                    }
                } else {
                    // Legacy format validation
                    let invalidLegacyValues = exercise.sets <= 0 ||
                        exercise.reps <= 0 ||
                        exercise.weight < 0
                    if invalidLegacyValues {
                        shouldDelete = true
                    }
                }

                if shouldDelete {
                    context.delete(exercise)
                    hasCorruption = true
                }
            }
        } catch {
            // If we can't fetch, assume corruption and clear all
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
            try? context.execute(deleteRequest)
            hasCorruption = true
        }

        return hasCorruption
    }

    /// Cleans up corrupted ExerciseMetadata entities
    private func cleanupCorruptedExerciseMetadata(context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<ExerciseMetadata> = ExerciseMetadata.fetchRequest()
        var hasCorruption = false

        do {
            let metadata = try context.fetch(request)

            for item in metadata {
                let nameEmpty = item.name?.isEmpty ?? true
                let futureLastUsed = (item.lastUsed ?? Date.distantPast) > Date()
                let invalidValues = item.usageCount < 0 || item.customWeight < 0

                if nameEmpty || futureLastUsed || invalidValues {
                    context.delete(item)
                    hasCorruption = true
                }
            }
        } catch {
            // If we can't fetch, assume corruption and clear all
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>)
            try? context.execute(deleteRequest)
            hasCorruption = true
        }

        return hasCorruption
    }
}

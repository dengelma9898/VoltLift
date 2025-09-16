//
//  ExerciseMetadataService.swift
//  VoltLift
//
//  Created by Kiro on 14.9.2025.
//

import Combine
import CoreData
import Foundation

/// Protocol defining the interface for exercise metadata services
@MainActor
protocol ExerciseMetadataServiceProtocol: ObservableObject {
    func recordExerciseUsage(exerciseId: UUID, exerciseName: String) async throws
    func updateLastUsed(for exerciseId: UUID, name exerciseName: String) async
    func updatePersonalNotes(for exerciseId: UUID, exerciseName: String, notes: String?) async throws
    func updatePersonalNotes(for exerciseId: UUID, notes: String?) async
    func updateCustomWeight(for exerciseId: UUID, exerciseName: String, weight: Double?) async throws
    func updateCustomWeight(for exerciseId: UUID, weight: Double?) async
    func getMetadata(for exerciseId: UUID) async -> ExerciseMetadata?
    func getRecentlyUsedExercises(limit: Int) async -> [ExerciseMetadata]
    func getMostUsedExercises(limit: Int) async -> [ExerciseMetadata]
    func deleteMetadata(for exerciseId: UUID) async throws
    func clearAllMetadata() async throws
}

/// Service for managing exercise metadata persistence and retrieval
@MainActor
class ExerciseMetadataService: ObservableObject, ExerciseMetadataServiceProtocol {
    // MARK: - Properties

    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext

    // MARK: - Published Properties

    @Published var recentlyUsedExercises: [ExerciseMetadata] = []
    @Published var mostUsedExercises: [ExerciseMetadata] = []

    // MARK: - Initialization

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext

        self.loadRecentlyUsedExercises()
        self.loadMostUsedExercises()
    }

    /// Test initializer with custom context
    init(context: NSManagedObjectContext) {
        self.persistenceController = PersistenceController.shared
        self.context = context

        self.loadRecentlyUsedExercises()
        self.loadMostUsedExercises()
    }

    // MARK: - Public Methods

    /// Records exercise usage and updates metadata
    func recordExerciseUsage(exerciseId: UUID, exerciseName: String) async throws {
        let metadata = try await getOrCreateMetadata(for: exerciseId, name: exerciseName)

        metadata.lastUsed = Date()
        metadata.usageCount += 1

        try await self.saveContext()

        // Update published properties
        self.loadRecentlyUsedExercises()
        self.loadMostUsedExercises()
    }

    /// Updates last used date and increments usage count (alias for recordExerciseUsage)
    func updateLastUsed(for exerciseId: UUID, name exerciseName: String) async {
        do {
            try await self.recordExerciseUsage(exerciseId: exerciseId, exerciseName: exerciseName)
        } catch {
            print("Error updating last used: \(error)")
        }
    }

    /// Updates personal notes for an exercise
    func updatePersonalNotes(for exerciseId: UUID, exerciseName: String, notes: String?) async throws {
        let metadata = try await getOrCreateMetadata(for: exerciseId, name: exerciseName)
        metadata.personalNotes = notes?.isEmpty == true ? nil : notes

        try await self.saveContext()
    }

    /// Updates personal notes for an exercise (simplified interface for tests)
    func updatePersonalNotes(for exerciseId: UUID, notes: String?) async {
        guard let existingMetadata = await getMetadata(for: exerciseId) else { return }

        existingMetadata.personalNotes = notes?.isEmpty == true ? nil : notes

        do {
            try await self.saveContext()
        } catch {
            print("Error updating personal notes: \(error)")
        }
    }

    /// Updates custom weight for an exercise
    func updateCustomWeight(for exerciseId: UUID, exerciseName: String, weight: Double?) async throws {
        let metadata = try await getOrCreateMetadata(for: exerciseId, name: exerciseName)
        metadata.customWeight = weight ?? 0.0

        try await self.saveContext()
    }

    /// Updates custom weight for an exercise (simplified interface for tests)
    func updateCustomWeight(for exerciseId: UUID, weight: Double?) async {
        guard let existingMetadata = await getMetadata(for: exerciseId) else { return }

        existingMetadata.customWeight = weight ?? 0.0

        do {
            try await self.saveContext()
        } catch {
            print("Error updating custom weight: \(error)")
        }
    }

    /// Retrieves metadata for a specific exercise
    func getMetadata(for exerciseId: UUID) async -> ExerciseMetadata? {
        let request = ExerciseMetadata.fetchRequest(for: exerciseId)

        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Error fetching exercise metadata: \(error)")
            return nil
        }
    }

    /// Retrieves recently used exercises
    func getRecentlyUsedExercises(limit: Int = 10) async -> [ExerciseMetadata] {
        let request = ExerciseMetadata.recentlyUsedFetchRequest(limit: limit)

        do {
            return try self.context.fetch(request)
        } catch {
            print("Error fetching recently used exercises: \(error)")
            return []
        }
    }

    /// Retrieves most used exercises
    func getMostUsedExercises(limit: Int = 10) async -> [ExerciseMetadata] {
        let request = ExerciseMetadata.mostUsedFetchRequest(limit: limit)

        do {
            return try self.context.fetch(request)
        } catch {
            print("Error fetching most used exercises: \(error)")
            return []
        }
    }

    /// Deletes metadata for a specific exercise
    func deleteMetadata(for exerciseId: UUID) async throws {
        guard let metadata = await getMetadata(for: exerciseId) else { return }

        self.context.delete(metadata)
        try await self.saveContext()

        // Update published properties
        self.loadRecentlyUsedExercises()
        self.loadMostUsedExercises()
    }

    /// Clears all exercise metadata (for testing or reset purposes)
    func clearAllMetadata() async throws {
        let request: NSFetchRequest<NSFetchRequestResult> = ExerciseMetadata.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        try context.execute(deleteRequest)
        try await self.saveContext()

        // Update published properties
        self.loadRecentlyUsedExercises()
        self.loadMostUsedExercises()
    }

    // MARK: - Private Methods

    /// Gets existing metadata or creates new one if it doesn't exist
    private func getOrCreateMetadata(for exerciseId: UUID, name: String) async throws -> ExerciseMetadata {
        if let existing = await getMetadata(for: exerciseId) {
            return existing
        }

        let metadata = ExerciseMetadata(exerciseId: exerciseId, name: name, context: context)
        return metadata
    }

    /// Saves the Core Data context
    private func saveContext() async throws {
        if self.context.hasChanges {
            try self.context.save()
        }
    }

    /// Loads recently used exercises and updates published property
    private func loadRecentlyUsedExercises() {
        Task {
            let exercises = await getRecentlyUsedExercises()
            await MainActor.run {
                self.recentlyUsedExercises = exercises
            }
        }
    }

    /// Loads most used exercises and updates published property
    private func loadMostUsedExercises() {
        Task {
            let exercises = await getMostUsedExercises()
            await MainActor.run {
                self.mostUsedExercises = exercises
            }
        }
    }
}

// MARK: - Exercise Integration

extension ExerciseMetadataService {
    /// Enhanced exercise display item that includes metadata
    struct ExerciseWithMetadata {
        let exercise: Exercise
        let metadata: ExerciseMetadata?

        var isRecentlyUsed: Bool {
            self.metadata?.isRecentlyUsed ?? false
        }

        var isFrequentlyUsed: Bool {
            self.metadata?.isFrequentlyUsed ?? false
        }

        var usageCount: Int32 {
            self.metadata?.usageCount ?? 0
        }

        var personalNotes: String? {
            self.metadata?.personalNotes
        }

        var customWeight: Double? {
            let weight = self.metadata?.customWeight ?? 0.0
            return weight > 0 ? weight : nil
        }

        var lastUsed: Date? {
            self.metadata?.lastUsed
        }
    }

    /// Gets exercise with its metadata
    func getExerciseWithMetadata(_ exercise: Exercise) async -> ExerciseWithMetadata {
        let metadata = await getMetadata(for: exercise.id)
        return ExerciseWithMetadata(exercise: exercise, metadata: metadata)
    }

    /// Gets multiple exercises with their metadata
    func getExercisesWithMetadata(_ exercises: [Exercise]) async -> [ExerciseWithMetadata] {
        var results: [ExerciseWithMetadata] = []

        for exercise in exercises {
            let exerciseWithMetadata = await getExerciseWithMetadata(exercise)
            results.append(exerciseWithMetadata)
        }

        return results
    }
}

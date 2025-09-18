//
//  ExerciseCustomizationService.swift
//  VoltLift
//
//  Created by Kiro on 16.9.2025.
//

import Combine
import Foundation

// MARK: - Error Types

enum ValidationError: LocalizedError, Equatable {
    case invalidReps(value: Int, allowed: ClosedRange<Int>)
    case invalidWeight(value: Double, allowed: ClosedRange<Double>)
    case maximumSetsExceeded(maximum: Int)
    case minimumSetsRequired(minimum: Int)
    case invalidStructure(message: String)

    var errorDescription: String? {
        switch self {
        case let .invalidReps(value, allowed):
            "Repetitions \(value) out of allowed range \(allowed.lowerBound)-\(allowed.upperBound)."
        case let .invalidWeight(value, allowed):
            "Weight \(value) out of allowed range \(allowed.lowerBound)-\(allowed.upperBound)."
        case let .maximumSetsExceeded(maximum):
            "Maximum number of sets (\(maximum)) exceeded."
        case let .minimumSetsRequired(minimum):
            "At least \(minimum) set(s) required."
        case let .invalidStructure(message):
            message
        }
    }
}

enum ExerciseCustomizationError: LocalizedError, Equatable {
    case validationFailed(errors: [ValidationError])
    case exerciseNotFound(id: UUID)
    case setNotFound(id: UUID)
    case maximumSetsExceeded(maximum: Int)
    case minimumSetsRequired(minimum: Int)
    case invalidReorderOperation
    case updateFailed(underlying: String)
    case addSetFailed(underlying: String)
    case removeSetFailed(underlying: String)
    case reorderFailed(underlying: String)

    var errorDescription: String? {
        switch self {
        case let .validationFailed(errors):
            errors.compactMap(\.errorDescription).joined(separator: "\n")
        case let .exerciseNotFound(id):
            "Exercise not found: \(id)"
        case let .setNotFound(id):
            "Set not found: \(id)"
        case let .maximumSetsExceeded(maximum):
            "Maximum sets exceeded (\(maximum))."
        case let .minimumSetsRequired(minimum):
            "Minimum sets required (\(minimum))."
        case .invalidReorderOperation:
            "Invalid reorder operation."
        case let .updateFailed(underlying),
             let .addSetFailed(underlying),
             let .removeSetFailed(underlying),
             let .reorderFailed(underlying):
            underlying
        }
    }
}

/// Service responsible for managing exercise customization operations
/// Provides validation, modification, and management of exercise sets within workout plans
@MainActor
class ExerciseCustomizationService: ObservableObject {
    // MARK: - Published Properties

    @Published var isCustomizing: Bool = false
    @Published var validationErrors: [ValidationError] = []
    @Published var isLoading: Bool = false
    @Published var lastError: ExerciseCustomizationError?
    @Published var operationInProgress: String?

    // MARK: - Private Properties

    private let userPreferencesService: UserPreferencesService
    private let maxSetsPerExercise: Int = 10
    private let minSetsPerExercise: Int = 1
    private let validRepsRange: ClosedRange<Int> = 1 ... 50
    private let validWeightRange: ClosedRange<Double> = 0.0 ... 1_000.0

    // MARK: - Initialization

    init(userPreferencesService: UserPreferencesService = UserPreferencesService()) {
        self.userPreferencesService = userPreferencesService
    }

    // MARK: - Exercise Set Modification Methods

    /// Updates parameters for a specific exercise set
    /// - Parameters:
    ///   - exerciseId: UUID of the exercise containing the set
    ///   - setId: UUID of the set to update
    ///   - reps: New repetition count
    ///   - weight: New weight value
    ///   - setType: New set type
    /// - Throws: ExerciseCustomizationError if validation fails or update fails
    func updateExerciseSet(
        _ exerciseId: UUID,
        setId: UUID,
        reps: Int,
        weight: Double,
        setType: SetType
    ) async throws {
        setOperationInProgress("Updating exercise set")
        defer { clearOperationInProgress() }

        // Validate parameters
        let validationErrors = validateSetParameters(reps: reps, weight: weight)
        if !validationErrors.isEmpty {
            self.validationErrors = validationErrors
            throw ExerciseCustomizationError.validationFailed(errors: validationErrors)
        }

        do {
            // Find the workout plan containing this exercise
            guard let planData = try await findPlanContainingExercise(exerciseId) else {
                throw ExerciseCustomizationError.exerciseNotFound(id: exerciseId)
            }

            // Find and update the exercise
            var updatedExercises = planData.exercises
            guard let exerciseIndex = updatedExercises.firstIndex(where: { $0.id == exerciseId }) else {
                throw ExerciseCustomizationError.exerciseNotFound(id: exerciseId)
            }

            var exercise = updatedExercises[exerciseIndex]
            guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setId }) else {
                throw ExerciseCustomizationError.setNotFound(id: setId)
            }

            // Update the set with new parameters
            var updatedSets = exercise.sets
            updatedSets[setIndex] = updatedSets[setIndex].withUpdatedParameters(
                reps: reps,
                weight: weight,
                setType: setType
            )

            // Update the exercise with new sets
            updatedExercises[exerciseIndex] = exercise.withUpdatedSets(updatedSets)

            // Validate the updated exercise structure
            let structureErrors = validateExerciseStructure(updatedExercises[exerciseIndex])
            if !structureErrors.isEmpty {
                self.validationErrors = structureErrors
                throw ExerciseCustomizationError.validationFailed(errors: structureErrors)
            }

            // Save the updated plan
            let updatedPlan = WorkoutPlanData(
                id: planData.id,
                name: planData.name,
                exercises: updatedExercises,
                createdDate: planData.createdDate,
                lastUsedDate: planData.lastUsedDate
            )

            try await self.userPreferencesService.savePlan(updatedPlan)
            clearError()

        } catch let error as ExerciseCustomizationError {
            handleError(error)
            throw error
        } catch {
            let customizationError = ExerciseCustomizationError.updateFailed(underlying: error.localizedDescription)
            handleError(customizationError)
            throw customizationError
        }
    }

    /// Adds a new set to an exercise with intelligent default values
    /// - Parameters:
    ///   - exerciseId: UUID of the exercise to add the set to
    ///   - afterSet: Optional set number to insert after (nil to append at end)
    /// - Returns: The newly created ExerciseSet
    /// - Throws: ExerciseCustomizationError if operation fails
    func addSetToExercise(_ exerciseId: UUID, afterSet: Int? = nil) async throws -> ExerciseSet {
        setOperationInProgress("Adding set to exercise")
        defer { clearOperationInProgress() }

        do {
            // Find the workout plan containing this exercise
            guard let planData = try await findPlanContainingExercise(exerciseId) else {
                throw ExerciseCustomizationError.exerciseNotFound(id: exerciseId)
            }

            // Find the exercise
            var updatedExercises = planData.exercises
            guard let exerciseIndex = updatedExercises.firstIndex(where: { $0.id == exerciseId }) else {
                throw ExerciseCustomizationError.exerciseNotFound(id: exerciseId)
            }

            let exercise = updatedExercises[exerciseIndex]

            // Check maximum sets limit
            if exercise.sets.count >= self.maxSetsPerExercise {
                throw ExerciseCustomizationError.maximumSetsExceeded(maximum: self.maxSetsPerExercise)
            }

            // Calculate intelligent defaults based on existing sets
            let defaultValues = calculateDefaultSetValues(from: exercise.sets)

            // Determine insertion position and new set number
            let insertionIndex: Int
            let newSetNumber: Int

            if let afterSetNumber = afterSet,
               let afterIndex = exercise.sets.firstIndex(where: { $0.setNumber == afterSetNumber })
            {
                insertionIndex = afterIndex + 1
                newSetNumber = afterSetNumber + 1
            } else {
                insertionIndex = exercise.sets.count
                newSetNumber = (exercise.sets.map(\.setNumber).max() ?? 0) + 1
            }

            // Create new set with intelligent defaults
            let newSet = ExerciseSet(
                setNumber: newSetNumber,
                reps: defaultValues.reps,
                weight: defaultValues.weight,
                setType: defaultValues.setType
            )

            // Insert the new set and renumber subsequent sets
            var updatedSets = exercise.sets
            updatedSets.insert(newSet, at: insertionIndex)
            updatedSets = renumberSets(updatedSets)

            // Update the exercise
            updatedExercises[exerciseIndex] = exercise.withUpdatedSets(updatedSets)

            // Validate the updated exercise structure
            let structureErrors = validateExerciseStructure(updatedExercises[exerciseIndex])
            if !structureErrors.isEmpty {
                self.validationErrors = structureErrors
                throw ExerciseCustomizationError.validationFailed(errors: structureErrors)
            }

            // Save the updated plan
            let updatedPlan = WorkoutPlanData(
                id: planData.id,
                name: planData.name,
                exercises: updatedExercises,
                createdDate: planData.createdDate,
                lastUsedDate: planData.lastUsedDate
            )

            try await self.userPreferencesService.savePlan(updatedPlan)
            clearError()

            return newSet

        } catch let error as ExerciseCustomizationError {
            handleError(error)
            throw error
        } catch {
            let customizationError = ExerciseCustomizationError.addSetFailed(underlying: error.localizedDescription)
            handleError(customizationError)
            throw customizationError
        }
    }

    /// Removes a set from an exercise with set numbering updates and minimum validation
    /// - Parameters:
    ///   - exerciseId: UUID of the exercise containing the set
    ///   - setId: UUID of the set to remove
    /// - Throws: ExerciseCustomizationError if operation fails or minimum sets violated
    func removeSetFromExercise(_ exerciseId: UUID, setId: UUID) async throws {
        setOperationInProgress("Removing set from exercise")
        defer { clearOperationInProgress() }

        do {
            // Find the workout plan containing this exercise
            guard let planData = try await findPlanContainingExercise(exerciseId) else {
                throw ExerciseCustomizationError.exerciseNotFound(id: exerciseId)
            }

            // Find the exercise
            var updatedExercises = planData.exercises
            guard let exerciseIndex = updatedExercises.firstIndex(where: { $0.id == exerciseId }) else {
                throw ExerciseCustomizationError.exerciseNotFound(id: exerciseId)
            }

            let exercise = updatedExercises[exerciseIndex]

            // Check minimum sets requirement
            if exercise.sets.count <= self.minSetsPerExercise {
                throw ExerciseCustomizationError.minimumSetsRequired(minimum: self.minSetsPerExercise)
            }

            // Find and remove the set
            guard let setIndex = exercise.sets.firstIndex(where: { $0.id == setId }) else {
                throw ExerciseCustomizationError.setNotFound(id: setId)
            }

            var updatedSets = exercise.sets
            updatedSets.remove(at: setIndex)

            // Renumber remaining sets to maintain sequential numbering
            updatedSets = renumberSets(updatedSets)

            // Update the exercise
            updatedExercises[exerciseIndex] = exercise.withUpdatedSets(updatedSets)

            // Validate the updated exercise structure
            let structureErrors = validateExerciseStructure(updatedExercises[exerciseIndex])
            if !structureErrors.isEmpty {
                self.validationErrors = structureErrors
                throw ExerciseCustomizationError.validationFailed(errors: structureErrors)
            }

            // Save the updated plan
            let updatedPlan = WorkoutPlanData(
                id: planData.id,
                name: planData.name,
                exercises: updatedExercises,
                createdDate: planData.createdDate,
                lastUsedDate: planData.lastUsedDate
            )

            try await self.userPreferencesService.savePlan(updatedPlan)
            clearError()

        } catch let error as ExerciseCustomizationError {
            handleError(error)
            throw error
        } catch {
            let customizationError = ExerciseCustomizationError.removeSetFailed(underlying: error.localizedDescription)
            handleError(customizationError)
            throw customizationError
        }
    }

    /// Reorders sets within an exercise for drag-and-drop functionality
    /// - Parameters:
    ///   - exerciseId: UUID of the exercise containing the sets
    ///   - from: IndexSet of source indices
    ///   - to: Destination index
    /// - Throws: ExerciseCustomizationError if operation fails
    func reorderSets(_ exerciseId: UUID, from: IndexSet, to: Int) async throws {
        setOperationInProgress("Reordering exercise sets")
        defer { clearOperationInProgress() }

        do {
            // Find the workout plan containing this exercise
            guard let planData = try await findPlanContainingExercise(exerciseId) else {
                throw ExerciseCustomizationError.exerciseNotFound(id: exerciseId)
            }

            // Find the exercise
            var updatedExercises = planData.exercises
            guard let exerciseIndex = updatedExercises.firstIndex(where: { $0.id == exerciseId }) else {
                throw ExerciseCustomizationError.exerciseNotFound(id: exerciseId)
            }

            let exercise = updatedExercises[exerciseIndex]

            // Validate reorder parameters
            guard !from.isEmpty,
                  from.allSatisfy({ $0 < exercise.sets.count }),
                  to <= exercise.sets.count
            else {
                throw ExerciseCustomizationError.invalidReorderOperation
            }

            // Perform the reorder operation
            var updatedSets = exercise.sets
            updatedSets.move(fromOffsets: from, toOffset: to)

            // Renumber sets to maintain sequential numbering
            updatedSets = renumberSets(updatedSets)

            // Update the exercise
            updatedExercises[exerciseIndex] = exercise.withUpdatedSets(updatedSets)

            // Validate the updated exercise structure
            let structureErrors = validateExerciseStructure(updatedExercises[exerciseIndex])
            if !structureErrors.isEmpty {
                self.validationErrors = structureErrors
                throw ExerciseCustomizationError.validationFailed(errors: structureErrors)
            }

            // Save the updated plan
            let updatedPlan = WorkoutPlanData(
                id: planData.id,
                name: planData.name,
                exercises: updatedExercises,
                createdDate: planData.createdDate,
                lastUsedDate: planData.lastUsedDate
            )

            try await self.userPreferencesService.savePlan(updatedPlan)
            clearError()

        } catch let error as ExerciseCustomizationError {
            handleError(error)
            throw error
        } catch {
            let customizationError = ExerciseCustomizationError.reorderFailed(underlying: error.localizedDescription)
            handleError(customizationError)
            throw customizationError
        }
    }
}

// MARK: - Private Helpers

private extension ExerciseCustomizationService {
    func setOperationInProgress(_ description: String) {
        self.operationInProgress = description
        self.isLoading = true
    }

    func clearOperationInProgress() {
        self.operationInProgress = nil
        self.isLoading = false
    }

    func clearError() {
        self.lastError = nil
    }

    func handleError(_ error: ExerciseCustomizationError) {
        self.lastError = error
    }

    func validateSetParameters(reps: Int, weight: Double) -> [ValidationError] {
        var errors: [ValidationError] = []
        if !self.validRepsRange.contains(reps) {
            errors.append(.invalidReps(value: reps, allowed: self.validRepsRange))
        }
        if !self.validWeightRange.contains(weight) {
            errors.append(.invalidWeight(value: weight, allowed: self.validWeightRange))
        }
        return errors
    }

    func validateExerciseStructure(_ exercise: ExerciseData) -> [ValidationError] {
        var errors: [ValidationError] = []

        if exercise.sets.count < self.minSetsPerExercise {
            errors.append(.minimumSetsRequired(minimum: self.minSetsPerExercise))
        }
        if exercise.sets.count > self.maxSetsPerExercise {
            errors.append(.maximumSetsExceeded(maximum: self.maxSetsPerExercise))
        }

        // Ensure set numbers start at 1 and are consecutive
        let sorted = exercise.sets.sorted { $0.setNumber < $1.setNumber }
        for (index, set) in sorted.enumerated() {
            let expected = index + 1
            if set.setNumber != expected {
                errors.append(.invalidStructure(message: "Set numbering must be consecutive starting at 1."))
                break
            }
            // Validate each set parameters
            errors.append(contentsOf: self.validateSetParameters(reps: set.reps, weight: set.weight))
        }

        return errors
    }

    func renumberSets(_ sets: [ExerciseSet]) -> [ExerciseSet] {
        let sorted = sets.sorted { $0.setNumber < $1.setNumber }
        return sorted.enumerated().map { index, set in
            set.withSetNumber(index + 1)
        }
    }

    func calculateDefaultSetValues(from sets: [ExerciseSet]) -> (reps: Int, weight: Double, setType: SetType) {
        guard let last = sets.sorted(by: { $0.setNumber < $1.setNumber }).last else {
            return (reps: 10, weight: 0.0, setType: .normal)
        }
        // Heuristic: keep reps, slightly increase weight for progression within safe bounds
        let nextWeight = min(max(self.validWeightRange.lowerBound, last.weight + 2.5), self.validWeightRange.upperBound)
        return (reps: last.reps, weight: nextWeight, setType: last.setType)
    }

    func findPlanContainingExercise(_ exerciseId: UUID) async throws -> WorkoutPlanData? {
        // Use cached plans first
        if let plan = self.userPreferencesService.savedPlans.first(where: { plan in
            plan.exercises.contains(where: { $0.id == exerciseId })
        }) {
            return plan
        }

        // Load plans if not already available
        do {
            try await self.userPreferencesService.loadSavedPlans()
        } catch {
            throw ExerciseCustomizationError.updateFailed(underlying: error.localizedDescription)
        }

        return self.userPreferencesService.savedPlans.first(where: { plan in
            plan.exercises.contains(where: { $0.id == exerciseId })
        })
    }
}

//
//  ExerciseCustomizationService.swift
//  VoltLift
//
//  Created by Kiro on 16.9.2025.
//

import Foundation
import Combine

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
    private let validRepsRange: ClosedRange<Int> = 1...50
    private let validWeightRange: ClosedRange<Double> = 0.0...1000.0
    
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
            
            try await userPreferencesService.savePlan(updatedPlan)
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
            if exercise.sets.count >= maxSetsPerExercise {
                throw ExerciseCustomizationError.maximumSetsExceeded(maximum: maxSetsPerExercise)
            }
            
            // Calculate intelligent defaults based on existing sets
            let defaultValues = calculateDefaultSetValues(from: exercise.sets)
            
            // Determine insertion position and new set number
            let insertionIndex: Int
            let newSetNumber: Int
            
            if let afterSetNumber = afterSet,
               let afterIndex = exercise.sets.firstIndex(where: { $0.setNumber == afterSetNumber }) {
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
            
            try await userPreferencesService.savePlan(updatedPlan)
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
            if exercise.sets.count <= minSetsPerExercise {
                throw ExerciseCustomizationError.minimumSetsRequired(minimum: minSetsPerExercise)
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
            
            try await userPreferencesService.savePlan(updatedPlan)
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
                  to <= exercise.sets.count else {
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
            
            try await userPreferencesService.savePlan(updatedPlan)
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
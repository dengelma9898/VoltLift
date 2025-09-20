import Foundation

public enum PlanEditorError: Error, Equatable, LocalizedError {
    case indexOutOfRange
    case unilateralNotSupported
    case invalidReps
    case invalidSide

    public var errorDescription: String? {
        switch self {
        case .indexOutOfRange: "Index außerhalb des gültigen Bereichs."
        case .unilateralNotSupported: "Einseitige Ausführung für diese Übung nicht verfügbar."
        case .invalidReps: "Wiederholungen müssen ≥ 0 sein."
        case .invalidSide: "Ungültige Seitenwahl."
        }
    }
}

public struct PlanEditorService {
    public init() {}

    // UC1: Add/Remove/Move Sets
    public func addSet(to plan: PlanDraft, exerciseId: UUID, newSet: PlanSetDraft, at index: Int?) throws -> PlanDraft {
        var updatedPlan = plan
        guard let exerciseIndex = updatedPlan.exercises.firstIndex(where: { $0.id == exerciseId }) else {
            throw PlanEditorError.indexOutOfRange
        }
        guard PlanValidation.isValidReps(newSet.reps) else { throw PlanEditorError.invalidReps }
        guard PlanValidation.isValidSide(
            newSet.side,
            allowsUnilateral: updatedPlan.exercises[exerciseIndex].allowsUnilateral
        ) else {
            throw PlanEditorError.unilateralNotSupported
        }
        if let idx = index {
            guard idx >= 0,
                  idx <= updatedPlan.exercises[exerciseIndex].sets.count else { throw PlanEditorError.indexOutOfRange }
            updatedPlan.exercises[exerciseIndex].sets.insert(newSet, at: idx)
        } else {
            updatedPlan.exercises[exerciseIndex].sets.append(newSet)
        }
        return updatedPlan
    }

    public func removeSet(from plan: PlanDraft, exerciseId: UUID, at index: Int) throws -> PlanDraft {
        var updatedPlan = plan
        guard let exerciseIndex = updatedPlan.exercises.firstIndex(where: { $0.id == exerciseId }) else {
            throw PlanEditorError.indexOutOfRange
        }
        guard updatedPlan.exercises[exerciseIndex].sets.indices.contains(index)
        else { throw PlanEditorError.indexOutOfRange }
        updatedPlan.exercises[exerciseIndex].sets.remove(at: index)
        return updatedPlan
    }

    public func moveSet(
        in plan: PlanDraft,
        exerciseId: UUID,
        from sourceIndex: Int,
        to destinationIndex: Int
    ) throws -> PlanDraft {
        var updatedPlan = plan
        guard let exerciseIndex = updatedPlan.exercises.firstIndex(where: { $0.id == exerciseId }) else {
            throw PlanEditorError.indexOutOfRange
        }
        var sets = updatedPlan.exercises[exerciseIndex].sets
        guard sets.indices.contains(sourceIndex), destinationIndex >= 0,
              destinationIndex <= sets.count else { throw PlanEditorError.indexOutOfRange }
        let element = sets.remove(at: sourceIndex)
        sets.insert(element, at: destinationIndex)
        updatedPlan.exercises[exerciseIndex].sets = sets
        return updatedPlan
    }

    // UC2: Edit Set Attributes
    public func editSetAttributes(
        in plan: PlanDraft,
        exerciseId: UUID,
        setIndex: Int,
        reps: Int,
        setType: ExerciseSetType,
        side: ExecutionSide,
        comment: String?
    ) throws -> PlanDraft {
        var updatedPlan = plan
        guard let exerciseIndex = updatedPlan.exercises.firstIndex(where: { $0.id == exerciseId }) else {
            throw PlanEditorError.indexOutOfRange
        }
        guard updatedPlan.exercises[exerciseIndex].sets.indices.contains(setIndex)
        else { throw PlanEditorError.indexOutOfRange }
        guard PlanValidation.isValidReps(reps) else { throw PlanEditorError.invalidReps }
        guard PlanValidation.isValidSide(side, allowsUnilateral: updatedPlan.exercises[exerciseIndex].allowsUnilateral)
        else {
            throw PlanEditorError.unilateralNotSupported
        }
        updatedPlan.exercises[exerciseIndex].sets[setIndex].reps = reps
        updatedPlan.exercises[exerciseIndex].sets[setIndex].setType = setType
        updatedPlan.exercises[exerciseIndex].sets[setIndex].side = side
        updatedPlan.exercises[exerciseIndex].sets[setIndex].comment = comment
        return updatedPlan
    }

    // UC3: Save Plan (Domain-level: passthrough; Persistenz folgt in T027)
    public func savePlan(_ plan: PlanDraft) throws -> PlanDraft {
        // Validierung des gesamten Plans optional
        for exercise in plan.exercises {
            for set in exercise.sets {
                guard PlanValidation.isValidReps(set.reps) else { throw PlanEditorError.invalidReps }
                guard PlanValidation.isValidSide(set.side, allowsUnilateral: exercise.allowsUnilateral)
                else { throw PlanEditorError.invalidSide }
            }
        }
        return plan
    }

    // UC4: Add/Remove Exercises
    func addExercise(to plan: PlanDraft, from exercise: Exercise) throws -> PlanDraft {
        var updated = plan
        // Default: three normal sets with 10 reps
        let defaultSets: [PlanSetDraft] = (0 ..< 3).map { _ in
            PlanSetDraft(reps: 10, setType: .normal, side: exercise.allowsUnilateral ? .both : .both, comment: nil)
        }
        let newExercise = PlanExerciseDraft(
            id: UUID(),
            referenceExerciseId: exercise.id.uuidString,
            displayName: exercise.name,
            allowsUnilateral: exercise.allowsUnilateral,
            sets: defaultSets
        )
        updated.exercises.append(newExercise)
        return updated
    }

    func removeExercise(from plan: PlanDraft, exerciseId: UUID) throws -> PlanDraft {
        var updated = plan
        guard updated.exercises.contains(where: { $0.id == exerciseId }) else { throw PlanEditorError.indexOutOfRange }
        updated.exercises.removeAll { $0.id == exerciseId }
        return updated
    }
}

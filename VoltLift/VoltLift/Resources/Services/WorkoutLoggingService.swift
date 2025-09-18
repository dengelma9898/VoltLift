import Foundation

public enum WorkoutLoggingError: Error, Equatable, LocalizedError {
    case notActiveWorkout
    case noEquipment
    case invalidWeight
    case invalidDifficulties

    public var errorDescription: String? {
        switch self {
        case .notActiveWorkout: "Kein aktives Workout."
        case .noEquipment: "Übung erfordert kein Equipment – kein Gewicht erfassbar."
        case .invalidWeight: "Ungültiges Gewicht (Schritt 0,5; Minimum 0)."
        case .invalidDifficulties: "Ungültige Schwierigkeit(en) (1–10) oder Länge passt nicht zu Wiederholungen."
        }
    }
}

public struct WorkoutLoggingService {
    public init() {}

    // UC4: Record Set Weight
    public func recordSetWeight(
        entries: [WorkoutSetEntry],
        planExerciseId: UUID,
        setIndex: Int,
        weightKg: Double,
        exerciseUsesEquipment: Bool
    ) throws -> [WorkoutSetEntry] {
        guard exerciseUsesEquipment else { throw WorkoutLoggingError.noEquipment }
        guard ExecutionValidation.isValidWeightKg(weightKg) else { throw WorkoutLoggingError.invalidWeight }
        var updated = entries
        if let idx = updated.firstIndex(where: { $0.planExerciseId == planExerciseId && $0.setIndex == setIndex }) {
            updated[idx].weightKg = weightKg
        } else {
            updated.append(WorkoutSetEntry(
                planExerciseId: planExerciseId,
                setIndex: setIndex,
                weightKg: weightKg,
                difficulties: []
            ))
        }
        return updated
    }

    // UC5: Record Per-Rep Difficulty
    public func recordPerRepDifficulty(
        entries: [WorkoutSetEntry],
        planExerciseId: UUID,
        setIndex: Int,
        difficulties: [Int],
        reps: Int
    ) throws -> [WorkoutSetEntry] {
        guard ExecutionValidation.isValidDifficulties(difficulties, reps: reps)
        else { throw WorkoutLoggingError.invalidDifficulties }
        var updated = entries
        if let idx = updated.firstIndex(where: { $0.planExerciseId == planExerciseId && $0.setIndex == setIndex }) {
            updated[idx].difficulties = difficulties
        } else {
            updated.append(WorkoutSetEntry(
                planExerciseId: planExerciseId,
                setIndex: setIndex,
                weightKg: nil,
                difficulties: difficulties
            ))
        }
        return updated
    }
}

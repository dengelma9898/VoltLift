import Foundation

public struct WorkoutSetEntry: Equatable, Identifiable {
    public let id: UUID
    public var planExerciseId: UUID
    public var setIndex: Int
    public var weightKg: Double? // nil bei Körpergewicht
    public var difficulties: [Int] // pro Wiederholung 1..10
    public var timestamp: Date

    public init(
        id: UUID = UUID(),
        planExerciseId: UUID,
        setIndex: Int,
        weightKg: Double?,
        difficulties: [Int],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.planExerciseId = planExerciseId
        self.setIndex = setIndex
        self.weightKg = weightKg
        self.difficulties = difficulties
        self.timestamp = timestamp
    }
}

// MARK: - Validation Helpers

public enum ExecutionValidation {
    public static func isValidWeightKg(_ weight: Double?) -> Bool {
        guard let weight else { return true } // Körpergewicht → ok
        guard weight >= 0 else { return false }
        // Schrittweite 0,5 → Gewicht * 2 muss ganzzahlig sein (Toleranz für Float)
        let doubled = weight * 2.0
        return abs(doubled.rounded() - doubled) < 0.000001
    }

    public static func isValidDifficulties(_ difficulties: [Int], reps: Int) -> Bool {
        guard difficulties.count == reps else { return false }
        return difficulties.allSatisfy { (1 ... 10).contains($0) }
    }
}

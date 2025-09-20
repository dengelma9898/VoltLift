import Foundation

struct WorkoutSessionSummary: Identifiable, Equatable, Sendable {
    let id: UUID
    let planId: UUID
    let startedAt: Date
    let finishedAt: Date?
    let status: WorkoutSessionStatus

    let totalSets: Int
    let totalReps: Int
    let totalVolumeKg: Double

    struct ExerciseAggregate: Identifiable, Equatable, Sendable {
        let id: UUID // planExerciseId
        let setsCount: Int
        let repsCount: Int
        let volumeKg: Double
    }

    let perExercise: [ExerciseAggregate]
}

struct PlanInsights: Equatable, Sendable {
    let sessionCount: Int
    let totalVolumeKg: Double
    let avgVolumePerSession: Double
    let avgRepsPerSet: Double
    let avgDifficulty: Double?
    let volumeTrendDelta: Double?
    let repsTrendDelta: Double?
    let weightTrendDelta: Double?
    let recentSummaries: [WorkoutSessionSummary]
}

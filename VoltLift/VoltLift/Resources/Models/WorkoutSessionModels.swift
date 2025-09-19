import Foundation

public enum WorkoutSessionStatus: String, Equatable, CaseIterable, Sendable {
    case active
    case finished
    case canceled
}

public struct WorkoutSession: Equatable, Identifiable, Sendable {
    public let id: UUID
    public var planId: UUID
    public var startedAt: Date
    public var finishedAt: Date?
    public var status: WorkoutSessionStatus
    public var currentExerciseIndex: Int
    public var setIndex: Int
    public var repIndex: Int
    public var restDurationSeconds: Int
    public var restTimerRemainingSeconds: Int
    public var hapticOnTimerEnd: Bool

    public init(
        id: UUID = UUID(),
        planId: UUID,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        status: WorkoutSessionStatus = .active,
        currentExerciseIndex: Int = 0,
        setIndex: Int = 0,
        repIndex: Int = 0,
        restDurationSeconds: Int = 120,
        restTimerRemainingSeconds: Int = 0,
        hapticOnTimerEnd: Bool = true
    ) {
        self.id = id
        self.planId = planId
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.status = status
        self.currentExerciseIndex = currentExerciseIndex
        self.setIndex = setIndex
        self.repIndex = repIndex
        self.restDurationSeconds = restDurationSeconds
        self.restTimerRemainingSeconds = restTimerRemainingSeconds
        self.hapticOnTimerEnd = hapticOnTimerEnd
    }
}

// MARK: - Validation Helpers

public enum WorkoutSessionValidation {
    public static func isNonNegative(_ value: Int) -> Bool { value >= 0 }

    public static func isValidStatus(_ status: WorkoutSessionStatus) -> Bool {
        WorkoutSessionStatus.allCases.contains(status)
    }
}

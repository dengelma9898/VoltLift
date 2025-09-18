import Foundation

public struct PlanDraft: Equatable, Identifiable {
    public let id: UUID
    public var name: String
    public var exercises: [PlanExerciseDraft]

    public init(id: UUID = UUID(), name: String, exercises: [PlanExerciseDraft]) {
        self.id = id
        self.name = name
        self.exercises = exercises
    }
}

extension PlanDraft: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

public struct PlanExerciseDraft: Equatable, Identifiable {
    public let id: UUID
    public var referenceExerciseId: String
    public var displayName: String
    public var allowsUnilateral: Bool
    public var sets: [PlanSetDraft]

    public init(
        id: UUID = UUID(),
        referenceExerciseId: String,
        displayName: String,
        allowsUnilateral: Bool,
        sets: [PlanSetDraft]
    ) {
        self.id = id
        self.referenceExerciseId = referenceExerciseId
        self.displayName = displayName
        self.allowsUnilateral = allowsUnilateral
        self.sets = sets
    }
}

public enum ExerciseSetType: String, Equatable, CaseIterable {
    case warmUp
    case normal
    case coolDown
}

public enum ExecutionSide: String, Equatable, CaseIterable {
    case both
    case unilateral
}

public struct PlanSetDraft: Equatable, Identifiable {
    public let id: UUID
    public var reps: Int
    public var setType: ExerciseSetType
    public var side: ExecutionSide
    public var comment: String?

    public init(
        id: UUID = UUID(),
        reps: Int,
        setType: ExerciseSetType,
        side: ExecutionSide,
        comment: String? = nil
    ) {
        self.id = id
        self.reps = reps
        self.setType = setType
        self.side = side
        self.comment = comment
    }
}

// MARK: - Validation Helpers

public enum PlanValidation {
    public static func isValidReps(_ reps: Int) -> Bool { reps >= 0 }

    public static func isValidSide(_ side: ExecutionSide, allowsUnilateral: Bool) -> Bool {
        switch side {
        case .both: true
        case .unilateral: allowsUnilateral
        }
    }
}

import Foundation

// MARK: - Equipment Models

/// Represents a piece of equipment that can be selected by the user
struct EquipmentItem: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let category: String
    var isSelected: Bool

    init(id: String, name: String, category: String, isSelected: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.isSelected = isSelected
    }
}

// MARK: - Workout Plan Models

/// Represents a complete workout plan for the UI layer
struct WorkoutPlanData: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let exercises: [ExerciseData]
    let createdDate: Date
    let lastUsedDate: Date?

    /// Computed property for exercise count
    var exerciseCount: Int {
        self.exercises.count
    }

    init(
        id: UUID = UUID(),
        name: String,
        exercises: [ExerciseData],
        createdDate: Date = Date(),
        lastUsedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.exercises = exercises
        self.createdDate = createdDate
        self.lastUsedDate = lastUsedDate
    }
}

/// Lightweight metadata for workout plans to enable lazy loading
struct WorkoutPlanMetadata: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let exerciseCount: Int
    let createdDate: Date
    let lastUsedDate: Date?

    init(id: UUID, name: String, exerciseCount: Int, createdDate: Date, lastUsedDate: Date? = nil) {
        self.id = id
        self.name = name
        self.exerciseCount = exerciseCount
        self.createdDate = createdDate
        self.lastUsedDate = lastUsedDate
    }

    /// Creates metadata from a full WorkoutPlanData
    init(from planData: WorkoutPlanData) {
        self.id = planData.id
        self.name = planData.name
        self.exerciseCount = planData.exerciseCount
        self.createdDate = planData.createdDate
        self.lastUsedDate = planData.lastUsedDate
    }
}

// MARK: - Exercise Set Models

/// Represents the type of set within an exercise
enum SetType: String, CaseIterable, Codable, Equatable {
    case warmUp = "warm_up"
    case normal
    case coolDown = "cool_down"

    var displayName: String {
        switch self {
        case .warmUp: "Warm-up"
        case .normal: "Working Set"
        case .coolDown: "Cool-down"
        }
    }

    var icon: String {
        switch self {
        case .warmUp: "thermometer.low"
        case .normal: "dumbbell.fill"
        case .coolDown: "leaf.fill"
        }
    }

    var description: String {
        switch self {
        case .warmUp: "Preparation set with lighter weight"
        case .normal: "Main working set at target intensity"
        case .coolDown: "Recovery set with reduced intensity"
        }
    }
}

/// Represents an individual set within an exercise
struct ExerciseSet: Identifiable, Codable, Equatable {
    let id: UUID
    let setNumber: Int
    let reps: Int
    let weight: Double
    let setType: SetType
    let isCompleted: Bool
    let completedAt: Date?

    init(setNumber: Int, reps: Int = 10, weight: Double = 0.0, setType: SetType = .normal) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.setType = setType
        self.isCompleted = false
        self.completedAt = nil
    }

    /// Creates a completed set with completion timestamp
    init(setNumber: Int, reps: Int, weight: Double, setType: SetType, completedAt: Date) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.setType = setType
        self.isCompleted = true
        self.completedAt = completedAt
    }

    /// Creates a copy of this set with updated completion status
    func withCompletion(isCompleted: Bool, completedAt: Date? = nil) -> ExerciseSet {
        ExerciseSet(
            id: self.id,
            setNumber: self.setNumber,
            reps: self.reps,
            weight: self.weight,
            setType: self.setType,
            isCompleted: isCompleted,
            completedAt: isCompleted ? (completedAt ?? Date()) : nil
        )
    }

    /// Creates a copy of this set with updated parameters
    func withUpdatedParameters(reps: Int? = nil, weight: Double? = nil, setType: SetType? = nil) -> ExerciseSet {
        ExerciseSet(
            id: self.id,
            setNumber: self.setNumber,
            reps: reps ?? self.reps,
            weight: weight ?? self.weight,
            setType: setType ?? self.setType,
            isCompleted: self.isCompleted,
            completedAt: self.completedAt
        )
    }

    /// Private initializer for internal use with all parameters
    private init(
        id: UUID,
        setNumber: Int,
        reps: Int,
        weight: Double,
        setType: SetType,
        isCompleted: Bool,
        completedAt: Date?
    ) {
        self.id = id
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.setType = setType
        self.isCompleted = isCompleted
        self.completedAt = completedAt
    }
}

/// Represents an individual exercise within a workout plan
struct ExerciseData: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let sets: [ExerciseSet]
    let restTime: Int
    let orderIndex: Int

    // MARK: - Computed Properties for Backward Compatibility

    /// Total number of sets in this exercise
    var totalSets: Int {
        self.sets.count
    }

    /// Average repetitions across all sets
    var averageReps: Int {
        guard !self.sets.isEmpty else { return 0 }
        let totalReps = self.sets.map(\.reps).reduce(0, +)
        return totalReps / self.sets.count
    }

    /// Average weight across all sets
    var averageWeight: Double {
        guard !self.sets.isEmpty else { return 0.0 }
        let totalWeight = self.sets.map(\.weight).reduce(0.0, +)
        return totalWeight / Double(self.sets.count)
    }

    /// Number of completed sets
    var completedSets: Int {
        self.sets.filter(\.isCompleted).count
    }

    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard !self.sets.isEmpty else { return 0.0 }
        return Double(self.completedSets) / Double(self.totalSets)
    }

    /// Whether all sets are completed
    var isCompleted: Bool {
        !self.sets.isEmpty && self.sets.allSatisfy(\.isCompleted)
    }

    // MARK: - Initializers

    /// Creates an exercise with detailed set configuration
    init(id: UUID = UUID(), name: String, sets: [ExerciseSet], restTime: Int, orderIndex: Int = 0) {
        self.id = id
        self.name = name
        self.sets = sets
        self.restTime = restTime
        self.orderIndex = orderIndex
    }

    /// Creates an exercise with simple parameters (backward compatibility)
    init(id: UUID = UUID(), name: String, sets: Int, reps: Int, weight: Double, restTime: Int, orderIndex: Int = 0) {
        self.id = id
        self.name = name
        self.restTime = restTime
        self.orderIndex = orderIndex

        // Create ExerciseSet array from simple parameters
        self.sets = (1 ... sets).map { setNumber in
            ExerciseSet(setNumber: setNumber, reps: reps, weight: weight, setType: .normal)
        }
    }

    // MARK: - Helper Methods

    /// Creates a copy with updated sets
    func withUpdatedSets(_ newSets: [ExerciseSet]) -> ExerciseData {
        ExerciseData(
            id: self.id,
            name: self.name,
            sets: newSets,
            restTime: self.restTime,
            orderIndex: self.orderIndex
        )
    }

    /// Gets sets grouped by type
    var setsByType: [SetType: [ExerciseSet]] {
        Dictionary(grouping: self.sets, by: \.setType)
    }

    /// Gets sets in execution order (warm-up, normal, cool-down)
    var setsInExecutionOrder: [ExerciseSet] {
        let warmUpSets = self.sets.filter { $0.setType == .warmUp }.sorted { $0.setNumber < $1.setNumber }
        let normalSets = self.sets.filter { $0.setType == .normal }.sorted { $0.setNumber < $1.setNumber }
        let coolDownSets = self.sets.filter { $0.setType == .coolDown }.sorted { $0.setNumber < $1.setNumber }

        return warmUpSets + normalSets + coolDownSets
    }
}

// MARK: - Error Recovery

/// Represents a recovery option for handling errors
struct ErrorRecoveryOption: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let action: () async -> Void
    let isDestructive: Bool

    init(title: String, description: String, isDestructive: Bool = false, action: @escaping () async -> Void) {
        self.title = title
        self.description = description
        self.isDestructive = isDestructive
        self.action = action
    }
}

// MARK: - Error Types

/// Errors that can occur during user preferences operations
enum UserPreferencesError: LocalizedError, Equatable {
    case saveFailure(underlying: String)
    case loadFailure(underlying: String)
    case dataCorruption
    case invalidData(field: String)
    case planNotFound(id: UUID)
    case equipmentNotFound(id: String)
    case networkUnavailable
    case insufficientStorage
    case operationTimeout
    case concurrentModification
    case migrationFailure(version: String)

    var errorDescription: String? {
        switch self {
        case .saveFailure:
            "Failed to save your preferences. Please try again."
        case .loadFailure:
            "Unable to load your saved data. Using defaults."
        case .dataCorruption:
            "Data corruption detected. Preferences will be reset."
        case let .invalidData(field):
            "Invalid data detected in \(field). Please check your input."
        case .planNotFound:
            "The requested workout plan could not be found."
        case .equipmentNotFound:
            "The requested equipment item could not be found."
        case .networkUnavailable:
            "Network connection is unavailable. Some features may be limited."
        case .insufficientStorage:
            "Insufficient storage space. Please free up space and try again."
        case .operationTimeout:
            "The operation took too long to complete. Please try again."
        case .concurrentModification:
            "Data was modified by another process. Please refresh and try again."
        case .migrationFailure:
            "Failed to migrate your data to the latest version."
        }
    }

    var failureReason: String? {
        switch self {
        case let .saveFailure(underlying):
            "Save operation failed: \(underlying)"
        case let .loadFailure(underlying):
            "Load operation failed: \(underlying)"
        case .dataCorruption:
            "Stored data is corrupted or in an invalid format"
        case let .invalidData(field):
            "The \(field) contains invalid or missing data"
        case let .planNotFound(id):
            "No workout plan found with ID: \(id)"
        case let .equipmentNotFound(id):
            "No equipment found with ID: \(id)"
        case .networkUnavailable:
            "Network connection is not available"
        case .insufficientStorage:
            "Device storage is full or nearly full"
        case .operationTimeout:
            "Operation exceeded the maximum allowed time"
        case .concurrentModification:
            "Data was changed while the operation was in progress"
        case let .migrationFailure(version):
            "Failed to migrate data from version \(version)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .saveFailure:
            "Check available storage space and try again. If the problem persists, restart the app."
        case .loadFailure:
            "Your preferences will be reset to defaults. You can reconfigure them in Settings."
        case .dataCorruption:
            "Your preferences will be reset to defaults. You can reconfigure them in Settings."
        case .invalidData:
            "Please verify your input and try again."
        case .planNotFound:
            "The plan may have been deleted. Please select a different plan."
        case .equipmentNotFound:
            "The equipment may have been removed. Please update your selection."
        case .networkUnavailable:
            "Check your internet connection and try again. Some features work offline."
        case .insufficientStorage:
            "Delete unused apps or files to free up space, then try again."
        case .operationTimeout:
            "Check your connection and try again. Large operations may take longer."
        case .concurrentModification:
            "Refresh the data and try your operation again."
        case .migrationFailure:
            "Your data may need to be reset. Contact support if this persists."
        }
    }

    /// Indicates the severity level of the error
    var severity: ErrorSeverity {
        switch self {
        case .networkUnavailable, .operationTimeout:
            .warning
        case .invalidData, .planNotFound, .equipmentNotFound, .concurrentModification:
            .error
        case .saveFailure, .loadFailure:
            .error
        case .dataCorruption, .insufficientStorage, .migrationFailure:
            .critical
        }
    }

    /// Indicates whether the error is recoverable through user action
    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .operationTimeout, .concurrentModification, .insufficientStorage:
            true
        case .invalidData, .planNotFound, .equipmentNotFound:
            true
        case .saveFailure, .loadFailure:
            true
        case .dataCorruption, .migrationFailure:
            false
        }
    }

    /// Indicates whether the operation can be retried automatically
    var canRetry: Bool {
        switch self {
        case .networkUnavailable, .operationTimeout, .saveFailure, .loadFailure:
            true
        case .concurrentModification:
            true
        default:
            false
        }
    }
}

/// Represents the severity level of an error
enum ErrorSeverity {
    case warning // Non-blocking, informational
    case error // Blocking, but recoverable
    case critical // Blocking, may require data reset
}

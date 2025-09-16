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
        exercises.count
    }
    
    init(id: UUID = UUID(), name: String, exercises: [ExerciseData], createdDate: Date = Date(), lastUsedDate: Date? = nil) {
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
    case normal = "normal"
    case coolDown = "cool_down"
    
    var displayName: String {
        switch self {
        case .warmUp: return "Warm-up"
        case .normal: return "Working Set"
        case .coolDown: return "Cool-down"
        }
    }
    
    var icon: String {
        switch self {
        case .warmUp: return "thermometer.low"
        case .normal: return "dumbbell.fill"
        case .coolDown: return "leaf.fill"
        }
    }
    
    var description: String {
        switch self {
        case .warmUp: return "Preparation set with lighter weight"
        case .normal: return "Main working set at target intensity"
        case .coolDown: return "Recovery set with reduced intensity"
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
    private init(id: UUID, setNumber: Int, reps: Int, weight: Double, setType: SetType, isCompleted: Bool, completedAt: Date?) {
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
        sets.count
    }
    
    /// Average repetitions across all sets
    var averageReps: Int {
        guard !sets.isEmpty else { return 0 }
        let totalReps = sets.map(\.reps).reduce(0, +)
        return totalReps / sets.count
    }
    
    /// Average weight across all sets
    var averageWeight: Double {
        guard !sets.isEmpty else { return 0.0 }
        let totalWeight = sets.map(\.weight).reduce(0.0, +)
        return totalWeight / Double(sets.count)
    }
    
    /// Number of completed sets
    var completedSets: Int {
        sets.filter(\.isCompleted).count
    }
    
    /// Progress percentage (0.0 to 1.0)
    var progressPercentage: Double {
        guard !sets.isEmpty else { return 0.0 }
        return Double(completedSets) / Double(totalSets)
    }
    
    /// Whether all sets are completed
    var isCompleted: Bool {
        !sets.isEmpty && sets.allSatisfy(\.isCompleted)
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
        self.sets = (1...sets).map { setNumber in
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
        Dictionary(grouping: sets, by: \.setType)
    }
    
    /// Gets sets in execution order (warm-up, normal, cool-down)
    var setsInExecutionOrder: [ExerciseSet] {
        let warmUpSets = sets.filter { $0.setType == .warmUp }.sorted { $0.setNumber < $1.setNumber }
        let normalSets = sets.filter { $0.setType == .normal }.sorted { $0.setNumber < $1.setNumber }
        let coolDownSets = sets.filter { $0.setType == .coolDown }.sorted { $0.setNumber < $1.setNumber }
        
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
            return "Failed to save your preferences. Please try again."
        case .loadFailure:
            return "Unable to load your saved data. Using defaults."
        case .dataCorruption:
            return "Data corruption detected. Preferences will be reset."
        case .invalidData(let field):
            return "Invalid data detected in \(field). Please check your input."
        case .planNotFound:
            return "The requested workout plan could not be found."
        case .equipmentNotFound:
            return "The requested equipment item could not be found."
        case .networkUnavailable:
            return "Network connection is unavailable. Some features may be limited."
        case .insufficientStorage:
            return "Insufficient storage space. Please free up space and try again."
        case .operationTimeout:
            return "The operation took too long to complete. Please try again."
        case .concurrentModification:
            return "Data was modified by another process. Please refresh and try again."
        case .migrationFailure:
            return "Failed to migrate your data to the latest version."
        }
    }
    
    var failureReason: String? {
        switch self {
        case .saveFailure(let underlying):
            return "Save operation failed: \(underlying)"
        case .loadFailure(let underlying):
            return "Load operation failed: \(underlying)"
        case .dataCorruption:
            return "Stored data is corrupted or in an invalid format"
        case .invalidData(let field):
            return "The \(field) contains invalid or missing data"
        case .planNotFound(let id):
            return "No workout plan found with ID: \(id)"
        case .equipmentNotFound(let id):
            return "No equipment found with ID: \(id)"
        case .networkUnavailable:
            return "Network connection is not available"
        case .insufficientStorage:
            return "Device storage is full or nearly full"
        case .operationTimeout:
            return "Operation exceeded the maximum allowed time"
        case .concurrentModification:
            return "Data was changed while the operation was in progress"
        case .migrationFailure(let version):
            return "Failed to migrate data from version \(version)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailure:
            return "Check available storage space and try again. If the problem persists, restart the app."
        case .loadFailure:
            return "Your preferences will be reset to defaults. You can reconfigure them in Settings."
        case .dataCorruption:
            return "Your preferences will be reset to defaults. You can reconfigure them in Settings."
        case .invalidData:
            return "Please verify your input and try again."
        case .planNotFound:
            return "The plan may have been deleted. Please select a different plan."
        case .equipmentNotFound:
            return "The equipment may have been removed. Please update your selection."
        case .networkUnavailable:
            return "Check your internet connection and try again. Some features work offline."
        case .insufficientStorage:
            return "Delete unused apps or files to free up space, then try again."
        case .operationTimeout:
            return "Check your connection and try again. Large operations may take longer."
        case .concurrentModification:
            return "Refresh the data and try your operation again."
        case .migrationFailure:
            return "Your data may need to be reset. Contact support if this persists."
        }
    }
    
    /// Indicates the severity level of the error
    var severity: ErrorSeverity {
        switch self {
        case .networkUnavailable, .operationTimeout:
            return .warning
        case .invalidData, .planNotFound, .equipmentNotFound, .concurrentModification:
            return .error
        case .saveFailure, .loadFailure:
            return .error
        case .dataCorruption, .insufficientStorage, .migrationFailure:
            return .critical
        }
    }
    
    /// Indicates whether the error is recoverable through user action
    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .operationTimeout, .concurrentModification, .insufficientStorage:
            return true
        case .invalidData, .planNotFound, .equipmentNotFound:
            return true
        case .saveFailure, .loadFailure:
            return true
        case .dataCorruption, .migrationFailure:
            return false
        }
    }
    
    /// Indicates whether the operation can be retried automatically
    var canRetry: Bool {
        switch self {
        case .networkUnavailable, .operationTimeout, .saveFailure, .loadFailure:
            return true
        case .concurrentModification:
            return true
        default:
            return false
        }
    }
}

/// Represents the severity level of an error
enum ErrorSeverity {
    case warning    // Non-blocking, informational
    case error      // Blocking, but recoverable
    case critical   // Blocking, may require data reset
}
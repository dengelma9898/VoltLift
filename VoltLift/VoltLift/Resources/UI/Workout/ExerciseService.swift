import CoreData
import Foundation

// MARK: - ExerciseDisplayItem

/// Represents an exercise with equipment availability information
struct ExerciseDisplayItem: Identifiable, Hashable {
    let exercise: Exercise
    let isAvailable: Bool
    let missingEquipment: Set<String>

    var id: UUID { self.exercise.id }

    init(exercise: Exercise, availableEquipment: Set<String>) {
        self.exercise = exercise
        self.isAvailable = exercise.requiredEquipment.isSubset(of: availableEquipment)
        self.missingEquipment = exercise.requiredEquipment.subtracting(availableEquipment)
    }
}

// MARK: - ExerciseServiceProtocol

/// Protocol defining the interface for exercise business logic operations
@MainActor
protocol ExerciseServiceProtocol {
    /// Returns all exercises in the database
    func getAllExercises() -> [Exercise]

    /// Returns exercises for a specific muscle group that can be performed with available equipment
    func getExercises(for muscleGroup: MuscleGroup, availableEquipment: Set<String>) -> [Exercise]

    /// Returns exercises with equipment availability hints for a specific muscle group
    func getExercisesWithEquipmentHints(
        for muscleGroup: MuscleGroup,
        availableEquipment: Set<String>
    ) -> [ExerciseDisplayItem]

    /// Returns a specific exercise by its ID
    func getExercise(by id: UUID) -> Exercise?

    /// Returns exercises filtered by difficulty level
    func getExercises(for difficulty: DifficultyLevel, availableEquipment: Set<String>) -> [Exercise]

    /// Returns exercises that require no equipment (bodyweight exercises)
    func getBodyweightExercises() -> [Exercise]

    /// Returns recently used exercises
    func getRecentlyUsedExercises(limit: Int) async -> [Exercise]

    /// Returns most frequently used exercises
    func getMostUsedExercises(limit: Int) async -> [Exercise]

    /// Records exercise usage for metadata tracking
    func recordExerciseUsage(exerciseId: UUID) async

    /// Heuristic: whether exercise is sensible to perform unilaterally
    func allowsUnilateral(for exerciseId: UUID) -> Bool
}

// MARK: - ExerciseService Implementation

/// Concrete implementation of ExerciseServiceProtocol
@MainActor
final class ExerciseService: ExerciseServiceProtocol {
    // MARK: - Properties

    private let metadataService: any ExerciseMetadataServiceProtocol

    // MARK: - Singleton

    static let shared = ExerciseService()

    private init() {
        // Initialize with main context - in production this should be injected
        let context = PersistenceController.shared.container.viewContext
        self.metadataService = ExerciseMetadataService(context: context)
    }

    /// Initializer for dependency injection (useful for testing)
    init(metadataService: any ExerciseMetadataServiceProtocol) {
        self.metadataService = metadataService
    }

    // MARK: - Public Methods

    func getAllExercises() -> [Exercise] {
        EnhancedExerciseCatalog.allExercises
    }

    func getExercises(for muscleGroup: MuscleGroup, availableEquipment: Set<String>) -> [Exercise] {
        EnhancedExerciseCatalog.allExercises
            .filter { exercise in
                exercise.muscleGroup == muscleGroup &&
                    exercise.requiredEquipment.isSubset(of: availableEquipment)
            }
            .sorted { $0.name < $1.name }
    }

    func getExercisesWithEquipmentHints(
        for muscleGroup: MuscleGroup,
        availableEquipment: Set<String>
    ) -> [ExerciseDisplayItem] {
        // Performance optimization: Filter first, then map and sort
        // This reduces the number of ExerciseDisplayItem objects created
        let filteredExercises = EnhancedExerciseCatalog.allExercises.filter { $0.muscleGroup == muscleGroup }

        return filteredExercises
            .map { ExerciseDisplayItem(exercise: $0, availableEquipment: availableEquipment) }
            .sorted { lhs, rhs in
                // Sort by availability first (available exercises first), then by name
                if lhs.isAvailable != rhs.isAvailable {
                    return lhs.isAvailable && !rhs.isAvailable
                }
                return lhs.exercise.name < rhs.exercise.name
            }
    }

    func getExercise(by id: UUID) -> Exercise? {
        EnhancedExerciseCatalog.allExercises.first { $0.id == id }
    }

    func getExercises(for difficulty: DifficultyLevel, availableEquipment: Set<String>) -> [Exercise] {
        EnhancedExerciseCatalog.allExercises
            .filter { exercise in
                exercise.difficulty == difficulty &&
                    exercise.requiredEquipment.isSubset(of: availableEquipment)
            }
            .sorted { $0.name < $1.name }
    }

    func getBodyweightExercises() -> [Exercise] {
        EnhancedExerciseCatalog.allExercises
            .filter(\.requiredEquipment.isEmpty)
            .sorted { $0.name < $1.name }
    }

    func getRecentlyUsedExercises(limit: Int = 10) async -> [Exercise] {
        let metadata = await metadataService.getRecentlyUsedExercises(limit: limit)
        return metadata.compactMap { metadata in
            guard let exerciseId = metadata.exerciseId else { return nil }
            return self.getExercise(by: exerciseId)
        }
    }

    func getMostUsedExercises(limit: Int = 10) async -> [Exercise] {
        let metadata = await metadataService.getMostUsedExercises(limit: limit)
        return metadata.compactMap { metadata in
            guard let exerciseId = metadata.exerciseId else { return nil }
            return self.getExercise(by: exerciseId)
        }
    }

    func recordExerciseUsage(exerciseId: UUID) async {
        guard let exercise = getExercise(by: exerciseId) else { return }
        await self.metadataService.updateLastUsed(for: exerciseId, name: exercise.name)
    }

    func allowsUnilateral(for exerciseId: UUID) -> Bool {
        guard let exercise = getExercise(by: exerciseId) else { return false }
        return exercise.allowsUnilateral
    }
}

// MARK: - Legacy Compatibility Extension

extension ExerciseService {
    /// Returns legacy exercises for backward compatibility with existing WorkoutSetupView
    /// This method bridges the enhanced Exercise model to the legacy Exercise model
    func getLegacyExercises(
        for muscleGroup: WorkoutSetupView.MuscleGroup,
        availableEquipment: Set<String>
    ) -> [WorkoutSetupView.Exercise] {
        guard let enhancedMuscleGroup = MuscleGroup(rawValue: muscleGroup.rawValue) else {
            return []
        }

        return self.getExercises(for: enhancedMuscleGroup, availableEquipment: availableEquipment)
            .map(\.legacyExercise)
    }
}

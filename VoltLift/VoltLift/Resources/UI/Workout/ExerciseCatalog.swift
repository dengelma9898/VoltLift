import Foundation

enum ExerciseCatalog {
    /// Enhanced method that returns exercises with equipment availability status
    /// This method shows ALL exercises for the muscle group with appropriate equipment indicators
    static func forGroup(
        _ group: WorkoutSetupView.MuscleGroup,
        availableEquipment: Set<String>
    ) -> [ExerciseDisplayItem] {
        guard let enhancedMuscleGroup = MuscleGroup(rawValue: group.rawValue) else {
            return []
        }

        return ExerciseService.shared.getExercisesWithEquipmentHints(
            for: enhancedMuscleGroup,
            availableEquipment: availableEquipment
        )
    }

    /// Legacy method for backward compatibility with existing code that still expects legacy exercises
    /// This method filters to only show available exercises (old behavior)
    static func forGroupLegacy(
        _ group: WorkoutSetupView.MuscleGroup,
        availableEquipment: Set<String>
    ) -> [WorkoutSetupView.Exercise] {
        ExerciseService.shared.getLegacyExercises(
            for: group,
            availableEquipment: availableEquipment
        )
    }
}

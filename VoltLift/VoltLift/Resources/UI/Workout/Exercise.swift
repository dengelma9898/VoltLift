import Foundation

// MARK: - Enhanced Exercise Model

struct Exercise: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let muscleGroup: MuscleGroup
    let requiredEquipment: Set<String>

    // Enhanced metadata properties
    let description: String
    let instructions: [String]
    let safetyTips: [String]
    let targetMuscles: [String]
    let secondaryMuscles: [String]
    let difficulty: DifficultyLevel
    let variations: [ExerciseVariation]
    let sfSymbolName: String // SF Symbol icon name for visual representation

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        requiredEquipment: Set<String>,
        description: String,
        instructions: [String],
        safetyTips: [String],
        targetMuscles: [String],
        secondaryMuscles: [String] = [],
        difficulty: DifficultyLevel,
        variations: [ExerciseVariation] = [],
        sfSymbolName: String
    ) {
        self.id = id
        self.name = name
        self.muscleGroup = muscleGroup
        self.requiredEquipment = requiredEquipment
        self.description = description
        self.instructions = instructions
        self.safetyTips = safetyTips
        self.targetMuscles = targetMuscles
        self.secondaryMuscles = secondaryMuscles
        self.difficulty = difficulty
        self.variations = variations
        self.sfSymbolName = sfSymbolName
    }
}

// MARK: - Supporting Enums and Structures

enum DifficultyLevel: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }
}

struct ExerciseVariation: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let description: String
    let difficultyModifier: Int // -1 easier, 0 same, +1 harder
    let sfSymbolName: String

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        difficultyModifier: Int,
        sfSymbolName: String
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.difficultyModifier = difficultyModifier
        self.sfSymbolName = sfSymbolName
    }
}

enum MuscleGroup: String, CaseIterable, Identifiable, Codable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case fullBody = "Full Body"

    var id: String { rawValue }
}

// MARK: - Backward Compatibility Extension

extension Exercise {
    /// Creates a legacy Exercise struct for backward compatibility with existing WorkoutSetupView
    var legacyExercise: WorkoutSetupView.Exercise {
        WorkoutSetupView.Exercise(
            name: self.name,
            muscleGroup: WorkoutSetupView.MuscleGroup(rawValue: self.muscleGroup.rawValue) ?? .chest,
            requiredEquipment: self.requiredEquipment
        )
    }
}

extension WorkoutSetupView.Exercise {
    /// Creates an enhanced Exercise from a legacy exercise with default values
    func enhanced(
        description: String = "Exercise description not available",
        instructions: [String] = ["Instructions not available"],
        safetyTips: [String] = ["Consult a fitness professional"],
        targetMuscles: [String] = ["Primary muscles"],
        secondaryMuscles: [String] = [],
        difficulty: DifficultyLevel = .intermediate,
        variations: [ExerciseVariation] = [],
        sfSymbolName: String = "figure.strengthtraining.traditional"
    ) -> Exercise {
        Exercise(
            id: id,
            name: name,
            muscleGroup: MuscleGroup(rawValue: muscleGroup.rawValue) ?? .chest,
            requiredEquipment: requiredEquipment,
            description: description,
            instructions: instructions,
            safetyTips: safetyTips,
            targetMuscles: targetMuscles,
            secondaryMuscles: secondaryMuscles,
            difficulty: difficulty,
            variations: variations,
            sfSymbolName: sfSymbolName
        )
    }
}

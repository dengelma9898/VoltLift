import Foundation

enum ExerciseCatalog {
    private static let all: [WorkoutSetupView.Exercise] = [
        // Chest
        .init(name: "Push-up", muscleGroup: .chest, requiredEquipment: []),
        .init(name: "Dumbbell Bench Press", muscleGroup: .chest, requiredEquipment: ["Dumbbells", "Adjustable Bench"]),
        .init(
            name: "Incline Dumbbell Press",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells", "Adjustable Bench"]
        ),
        .init(name: "Band Chest Press", muscleGroup: .chest, requiredEquipment: ["Resistance Bands"]),
        // Back
        .init(name: "Bent-over Row (Dumbbell)", muscleGroup: .back, requiredEquipment: ["Dumbbells"]),
        .init(name: "Bent-over Row (Barbell)", muscleGroup: .back, requiredEquipment: ["Barbell", "Weight Plates"]),
        .init(name: "Pull-up", muscleGroup: .back, requiredEquipment: ["Pull-up Bar"]),
        .init(name: "Band Row", muscleGroup: .back, requiredEquipment: ["Resistance Bands"]),
        // Shoulders
        .init(name: "Overhead Press (Dumbbell)", muscleGroup: .shoulders, requiredEquipment: ["Dumbbells"]),
        .init(name: "Lateral Raise", muscleGroup: .shoulders, requiredEquipment: ["Dumbbells"]),
        .init(name: "Band Shoulder Press", muscleGroup: .shoulders, requiredEquipment: ["Resistance Bands"]),
        // Arms
        .init(name: "Biceps Curl", muscleGroup: .arms, requiredEquipment: ["Dumbbells"]),
        .init(name: "Triceps Extension (Band)", muscleGroup: .arms, requiredEquipment: ["Resistance Bands"]),
        .init(name: "Triceps Dip", muscleGroup: .arms, requiredEquipment: ["Adjustable Bench"]),
        // Legs
        .init(name: "Bodyweight Squat", muscleGroup: .legs, requiredEquipment: []),
        .init(name: "Goblet Squat", muscleGroup: .legs, requiredEquipment: ["Dumbbells"]),
        .init(name: "Kettlebell Deadlift", muscleGroup: .legs, requiredEquipment: ["Kettlebell"]),
        .init(name: "Lunge (Dumbbell)", muscleGroup: .legs, requiredEquipment: ["Dumbbells"]),
        // Core
        .init(name: "Plank", muscleGroup: .core, requiredEquipment: []),
        .init(name: "Russian Twist", muscleGroup: .core, requiredEquipment: ["Dumbbells"]),
        .init(name: "Dead Bug", muscleGroup: .core, requiredEquipment: []),
        // Full Body
        .init(name: "Burpee", muscleGroup: .fullBody, requiredEquipment: []),
        .init(name: "Kettlebell Swing", muscleGroup: .fullBody, requiredEquipment: ["Kettlebell"])
    ]

    static func forGroup(
        _ group: WorkoutSetupView.MuscleGroup,
        availableEquipment: Set<String>
    ) -> [WorkoutSetupView.Exercise] {
        self.all.filter { exercise in
            guard exercise.muscleGroup == group else { return false }
            return exercise.requiredEquipment.isSubset(of: availableEquipment)
        }
        .sorted { $0.name < $1.name }
    }
}

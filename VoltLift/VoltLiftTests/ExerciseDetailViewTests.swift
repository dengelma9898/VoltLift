import XCTest
import SwiftUI
@testable import VoltLift

final class ExerciseDetailViewTests: XCTestCase {
    
    func testExerciseDetailViewInitialization() {
        // Given
        let exercise = Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "A fundamental upper body exercise",
            instructions: ["Start in plank position", "Lower body", "Push back up"],
            safetyTips: ["Keep core engaged", "Maintain straight line"],
            targetMuscles: ["Pectoralis Major", "Triceps"],
            secondaryMuscles: ["Core"],
            difficulty: .beginner,
            variations: [
                ExerciseVariation(
                    name: "Knee Push-up",
                    description: "Easier variation",
                    difficultyModifier: -1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                )
            ],
            sfSymbolName: "figure.strengthtraining.traditional"
        )
        
        var addToWorkoutCalled = false
        
        // When
        let view = ExerciseDetailView(exercise: exercise) {
            addToWorkoutCalled = true
        }
        
        // Then
        XCTAssertNotNil(view)
        XCTAssertEqual(view.exercise.name, "Push-up")
        XCTAssertEqual(view.exercise.muscleGroup, .chest)
        XCTAssertEqual(view.exercise.difficulty, .beginner)
        XCTAssertEqual(view.exercise.instructions.count, 3)
        XCTAssertEqual(view.exercise.safetyTips.count, 2)
        XCTAssertEqual(view.exercise.variations.count, 1)
        XCTAssertFalse(addToWorkoutCalled)
    }
    
    func testExerciseWithEquipment() {
        // Given
        let exercise = Exercise(
            name: "Dumbbell Press",
            muscleGroup: .chest,
            requiredEquipment: ["Dumbbells", "Adjustable Bench"],
            description: "Chest exercise with dumbbells",
            instructions: ["Lie on bench", "Press dumbbells up"],
            safetyTips: ["Control the weight"],
            targetMuscles: ["Pectoralis Major"],
            difficulty: .intermediate,
            sfSymbolName: "dumbbell"
        )
        
        // When
        let view = ExerciseDetailView(exercise: exercise) {}
        
        // Then
        XCTAssertEqual(view.exercise.requiredEquipment.count, 2)
        XCTAssertTrue(view.exercise.requiredEquipment.contains("Dumbbells"))
        XCTAssertTrue(view.exercise.requiredEquipment.contains("Adjustable Bench"))
    }
    
    func testExerciseWithoutVariations() {
        // Given
        let exercise = Exercise(
            name: "Plank",
            muscleGroup: .core,
            requiredEquipment: [],
            description: "Core stability exercise",
            instructions: ["Hold plank position"],
            safetyTips: ["Keep body straight"],
            targetMuscles: ["Core"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )
        
        // When
        let view = ExerciseDetailView(exercise: exercise) {}
        
        // Then
        XCTAssertTrue(view.exercise.variations.isEmpty)
    }
    
    func testDifficultyLevels() {
        // Test all difficulty levels
        let difficulties: [DifficultyLevel] = [.beginner, .intermediate, .advanced]
        
        for difficulty in difficulties {
            let exercise = Exercise(
                name: "Test Exercise",
                muscleGroup: .chest,
                requiredEquipment: [],
                description: "Test description",
                instructions: ["Test instruction"],
                safetyTips: ["Test safety tip"],
                targetMuscles: ["Test muscle"],
                difficulty: difficulty,
                sfSymbolName: "figure.strengthtraining.traditional"
            )
            
            let view = ExerciseDetailView(exercise: exercise) {}
            XCTAssertEqual(view.exercise.difficulty, difficulty)
        }
    }
    
    func testMuscleGroups() {
        // Test all muscle groups
        let muscleGroups: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .legs, .core, .fullBody]
        
        for muscleGroup in muscleGroups {
            let exercise = Exercise(
                name: "Test Exercise",
                muscleGroup: muscleGroup,
                requiredEquipment: [],
                description: "Test description",
                instructions: ["Test instruction"],
                safetyTips: ["Test safety tip"],
                targetMuscles: ["Test muscle"],
                difficulty: .beginner,
                sfSymbolName: "figure.strengthtraining.traditional"
            )
            
            let view = ExerciseDetailView(exercise: exercise) {}
            XCTAssertEqual(view.exercise.muscleGroup, muscleGroup)
        }
    }
}
//
//  ExerciseModelTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import XCTest
@testable import VoltLift

final class ExerciseModelTests: XCTestCase {
    
    // MARK: - Exercise Model Tests
    
    func testExerciseInitialization_WithAllProperties_SetsCorrectValues() {
        // Given
        let id = UUID()
        let name = "Push-up"
        let muscleGroup = MuscleGroup.chest
        let requiredEquipment: Set<String> = []
        let description = "A fundamental upper body exercise"
        let instructions = ["Start in plank position", "Lower body", "Push back up"]
        let safetyTips = ["Keep core engaged", "Maintain straight line"]
        let targetMuscles = ["Pectoralis Major", "Triceps"]
        let secondaryMuscles = ["Core", "Shoulders"]
        let difficulty = DifficultyLevel.beginner
        let variations = [
            ExerciseVariation(
                name: "Knee Push-up",
                description: "Easier variation",
                difficultyModifier: -1,
                sfSymbolName: "figure.strengthtraining.traditional"
            )
        ]
        let sfSymbolName = "figure.strengthtraining.traditional"
        
        // When
        let exercise = Exercise(
            id: id,
            name: name,
            muscleGroup: muscleGroup,
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
        
        // Then
        XCTAssertEqual(exercise.id, id)
        XCTAssertEqual(exercise.name, name)
        XCTAssertEqual(exercise.muscleGroup, muscleGroup)
        XCTAssertEqual(exercise.requiredEquipment, requiredEquipment)
        XCTAssertEqual(exercise.description, description)
        XCTAssertEqual(exercise.instructions, instructions)
        XCTAssertEqual(exercise.safetyTips, safetyTips)
        XCTAssertEqual(exercise.targetMuscles, targetMuscles)
        XCTAssertEqual(exercise.secondaryMuscles, secondaryMuscles)
        XCTAssertEqual(exercise.difficulty, difficulty)
        XCTAssertEqual(exercise.variations, variations)
        XCTAssertEqual(exercise.sfSymbolName, sfSymbolName)
    }
    
    func testExerciseInitialization_WithDefaultValues_SetsCorrectDefaults() {
        // When
        let exercise = Exercise(
            name: "Test Exercise",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "Test description",
            instructions: ["Test instruction"],
            safetyTips: ["Test safety tip"],
            targetMuscles: ["Test muscle"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )
        
        // Then
        XCTAssertNotNil(exercise.id)
        XCTAssertTrue(exercise.secondaryMuscles.isEmpty)
        XCTAssertTrue(exercise.variations.isEmpty)
    }
    
    func testExerciseEquality_WithSameProperties_ReturnsTrue() {
        // Given
        let id = UUID()
        let exercise1 = Exercise(
            id: id,
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )
        
        let exercise2 = Exercise(
            id: id,
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )
        
        // When & Then
        XCTAssertEqual(exercise1, exercise2)
        XCTAssertEqual(exercise1.hashValue, exercise2.hashValue)
    }
    
    func testExerciseEquality_WithDifferentProperties_ReturnsFalse() {
        // Given
        let exercise1 = Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .beginner,
            sfSymbolName: "figure.strengthtraining.traditional"
        )
        
        let exercise2 = Exercise(
            name: "Pull-up",
            muscleGroup: .back,
            requiredEquipment: ["Pull-up Bar"],
            description: "Test",
            instructions: ["Test"],
            safetyTips: ["Test"],
            targetMuscles: ["Test"],
            difficulty: .advanced,
            sfSymbolName: "figure.climbing"
        )
        
        // When & Then
        XCTAssertNotEqual(exercise1, exercise2)
        XCTAssertNotEqual(exercise1.hashValue, exercise2.hashValue)
    }
    
    // MARK: - ExerciseVariation Tests
    
    func testExerciseVariationInitialization_WithAllProperties_SetsCorrectValues() {
        // Given
        let id = UUID()
        let name = "Knee Push-up"
        let description = "Easier variation performed on knees"
        let difficultyModifier = -1
        let sfSymbolName = "figure.strengthtraining.traditional"
        
        // When
        let variation = ExerciseVariation(
            id: id,
            name: name,
            description: description,
            difficultyModifier: difficultyModifier,
            sfSymbolName: sfSymbolName
        )
        
        // Then
        XCTAssertEqual(variation.id, id)
        XCTAssertEqual(variation.name, name)
        XCTAssertEqual(variation.description, description)
        XCTAssertEqual(variation.difficultyModifier, difficultyModifier)
        XCTAssertEqual(variation.sfSymbolName, sfSymbolName)
    }
    
    func testExerciseVariationInitialization_WithDefaultId_GeneratesUniqueId() {
        // When
        let variation1 = ExerciseVariation(
            name: "Variation 1",
            description: "Test",
            difficultyModifier: 0,
            sfSymbolName: "test"
        )
        
        let variation2 = ExerciseVariation(
            name: "Variation 2",
            description: "Test",
            difficultyModifier: 0,
            sfSymbolName: "test"
        )
        
        // Then
        XCTAssertNotEqual(variation1.id, variation2.id)
    }
    
    func testExerciseVariationEquality_WithSameProperties_ReturnsTrue() {
        // Given
        let id = UUID()
        let variation1 = ExerciseVariation(
            id: id,
            name: "Test Variation",
            description: "Test description",
            difficultyModifier: 1,
            sfSymbolName: "test.symbol"
        )
        
        let variation2 = ExerciseVariation(
            id: id,
            name: "Test Variation",
            description: "Test description",
            difficultyModifier: 1,
            sfSymbolName: "test.symbol"
        )
        
        // When & Then
        XCTAssertEqual(variation1, variation2)
        XCTAssertEqual(variation1.hashValue, variation2.hashValue)
    }
    
    // MARK: - DifficultyLevel Tests
    
    func testDifficultyLevel_AllCases_ContainsExpectedValues() {
        // Given
        let expectedCases: [DifficultyLevel] = [.beginner, .intermediate, .advanced]
        
        // When
        let allCases = DifficultyLevel.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 3)
        XCTAssertEqual(Set(allCases), Set(expectedCases))
    }
    
    func testDifficultyLevel_RawValues_AreCorrect() {
        // When & Then
        XCTAssertEqual(DifficultyLevel.beginner.rawValue, "Beginner")
        XCTAssertEqual(DifficultyLevel.intermediate.rawValue, "Intermediate")
        XCTAssertEqual(DifficultyLevel.advanced.rawValue, "Advanced")
    }
    
    func testDifficultyLevel_Id_ReturnsRawValue() {
        // When & Then
        XCTAssertEqual(DifficultyLevel.beginner.id, "Beginner")
        XCTAssertEqual(DifficultyLevel.intermediate.id, "Intermediate")
        XCTAssertEqual(DifficultyLevel.advanced.id, "Advanced")
    }
    
    // MARK: - MuscleGroup Tests
    
    func testMuscleGroup_AllCases_ContainsExpectedValues() {
        // Given
        let expectedCases: [MuscleGroup] = [.chest, .back, .shoulders, .arms, .legs, .core, .fullBody]
        
        // When
        let allCases = MuscleGroup.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 7)
        XCTAssertEqual(Set(allCases), Set(expectedCases))
    }
    
    func testMuscleGroup_RawValues_AreCorrect() {
        // When & Then
        XCTAssertEqual(MuscleGroup.chest.rawValue, "Chest")
        XCTAssertEqual(MuscleGroup.back.rawValue, "Back")
        XCTAssertEqual(MuscleGroup.shoulders.rawValue, "Shoulders")
        XCTAssertEqual(MuscleGroup.arms.rawValue, "Arms")
        XCTAssertEqual(MuscleGroup.legs.rawValue, "Legs")
        XCTAssertEqual(MuscleGroup.core.rawValue, "Core")
        XCTAssertEqual(MuscleGroup.fullBody.rawValue, "Full Body")
    }
    
    func testMuscleGroup_Id_ReturnsRawValue() {
        // When & Then
        XCTAssertEqual(MuscleGroup.chest.id, "Chest")
        XCTAssertEqual(MuscleGroup.back.id, "Back")
        XCTAssertEqual(MuscleGroup.shoulders.id, "Shoulders")
        XCTAssertEqual(MuscleGroup.arms.id, "Arms")
        XCTAssertEqual(MuscleGroup.legs.id, "Legs")
        XCTAssertEqual(MuscleGroup.core.id, "Core")
        XCTAssertEqual(MuscleGroup.fullBody.id, "Full Body")
    }
    
    // MARK: - Codable Tests
    
    func testExercise_Codable_EncodesAndDecodesCorrectly() throws {
        // Given
        let originalExercise = Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: ["Mat"],
            description: "A fundamental exercise",
            instructions: ["Start in plank", "Lower body", "Push up"],
            safetyTips: ["Keep core engaged"],
            targetMuscles: ["Pectoralis Major"],
            secondaryMuscles: ["Triceps"],
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
        
        // When
        let encodedData = try JSONEncoder().encode(originalExercise)
        let decodedExercise = try JSONDecoder().decode(Exercise.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalExercise, decodedExercise)
    }
    
    func testExerciseVariation_Codable_EncodesAndDecodesCorrectly() throws {
        // Given
        let originalVariation = ExerciseVariation(
            name: "Diamond Push-up",
            description: "Hands in diamond shape",
            difficultyModifier: 1,
            sfSymbolName: "diamond"
        )
        
        // When
        let encodedData = try JSONEncoder().encode(originalVariation)
        let decodedVariation = try JSONDecoder().decode(ExerciseVariation.self, from: encodedData)
        
        // Then
        XCTAssertEqual(originalVariation, decodedVariation)
    }
    
    func testDifficultyLevel_Codable_EncodesAndDecodesCorrectly() throws {
        // Given
        let difficulties: [DifficultyLevel] = [.beginner, .intermediate, .advanced]
        
        for difficulty in difficulties {
            // When
            let encodedData = try JSONEncoder().encode(difficulty)
            let decodedDifficulty = try JSONDecoder().decode(DifficultyLevel.self, from: encodedData)
            
            // Then
            XCTAssertEqual(difficulty, decodedDifficulty)
        }
    }
    
    func testMuscleGroup_Codable_EncodesAndDecodesCorrectly() throws {
        // Given
        let muscleGroups = MuscleGroup.allCases
        
        for muscleGroup in muscleGroups {
            // When
            let encodedData = try JSONEncoder().encode(muscleGroup)
            let decodedMuscleGroup = try JSONDecoder().decode(MuscleGroup.self, from: encodedData)
            
            // Then
            XCTAssertEqual(muscleGroup, decodedMuscleGroup)
        }
    }
}
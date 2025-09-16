//
//  TestDataFactory.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import Foundation
import CoreData
@testable import VoltLift

/// Factory class for creating test data for persistence system tests
/// Provides standardized test data creation and cleanup utilities
@MainActor
class TestDataFactory {
    
    // MARK: - Properties
    
    private var createdEquipmentIds: Set<String> = []
    private var createdPlanIds: Set<UUID> = []
    private var createdExerciseIds: Set<UUID> = []
    
    // MARK: - Equipment Test Data Creation
    
    /// Creates a standard equipment selection for testing
    func createEquipmentSelection() -> [EquipmentItem] {
        let equipment = [
            createEquipmentItem(id: "dumbbells", name: "Dumbbells", category: "Weights", isSelected: true),
            createEquipmentItem(id: "barbell", name: "Barbell", category: "Weights", isSelected: true),
            createEquipmentItem(id: "kettlebell", name: "Kettlebell", category: "Weights", isSelected: false),
            createEquipmentItem(id: "resistance-bands", name: "Resistance Bands", category: "Resistance", isSelected: true),
            createEquipmentItem(id: "yoga-mat", name: "Yoga Mat", category: "Accessories", isSelected: false),
            createEquipmentItem(id: "pull-up-bar", name: "Pull-up Bar", category: "Bodyweight", isSelected: true),
            createEquipmentItem(id: "bench", name: "Weight Bench", category: "Equipment", isSelected: false)
        ]
        
        createdEquipmentIds.formUnion(equipment.map { $0.id })
        return equipment
    }
    
    /// Creates a large equipment set for performance testing
    func createLargeEquipmentSet(count: Int, prefix: String = "equipment") -> [EquipmentItem] {
        let categories = ["Weights", "Cardio", "Resistance", "Accessories", "Bodyweight", "Equipment"]
        
        let equipment = (0..<count).map { index in
            createEquipmentItem(
                id: "\(prefix)_\(index)",
                name: "\(prefix.capitalized) \(index)",
                category: categories[index % categories.count],
                isSelected: index % 3 == 0 // Every third item selected
            )
        }
        
        createdEquipmentIds.formUnion(equipment.map { $0.id })
        return equipment
    }
    
    /// Creates a single equipment item
    func createEquipmentItem(
        id: String,
        name: String? = nil,
        category: String = "Test",
        isSelected: Bool = false
    ) -> EquipmentItem {
        let equipmentName = name ?? id.capitalized
        let item = EquipmentItem(id: id, name: equipmentName, category: category, isSelected: isSelected)
        createdEquipmentIds.insert(id)
        return item
    }
    
    /// Modifies an existing equipment selection for testing updates
    func modifyEquipmentSelection(_ originalEquipment: [EquipmentItem]) -> [EquipmentItem] {
        return originalEquipment.map { equipment in
            // Toggle selection for some items
            let shouldToggle = equipment.id.hashValue % 3 == 0
            return EquipmentItem(
                id: equipment.id,
                name: equipment.name,
                category: equipment.category,
                isSelected: shouldToggle ? !equipment.isSelected : equipment.isSelected
            )
        }
    }
    
    // MARK: - Workout Plan Test Data Creation
    
    /// Creates a single workout plan for testing
    func createWorkoutPlan(
        name: String,
        exerciseCount: Int = 3,
        createdDate: Date? = nil,
        lastUsedDate: Date? = nil
    ) -> WorkoutPlanData {
        let exercises = createExercisesForPlan(count: exerciseCount, planName: name)
        let plan = WorkoutPlanData(
            id: UUID(),
            name: name,
            exercises: exercises,
            createdDate: createdDate ?? Date(),
            lastUsedDate: lastUsedDate
        )
        
        createdPlanIds.insert(plan.id)
        return plan
    }
    
    /// Creates multiple workout plans for testing
    func createMultipleWorkoutPlans(
        count: Int,
        namePrefix: String = "Test Plan",
        exercisesPerPlan: Int = 3
    ) -> [WorkoutPlanData] {
        return (1...count).map { index in
            let createdDate = Date().addingTimeInterval(-Double(index * 3600)) // Spread over hours
            let lastUsedDate = index % 4 == 0 ? Date().addingTimeInterval(-Double(index * 1800)) : nil
            
            return createWorkoutPlan(
                name: "\(namePrefix) \(index)",
                exerciseCount: exercisesPerPlan,
                createdDate: createdDate,
                lastUsedDate: lastUsedDate
            )
        }
    }
    
    /// Creates workout plans based on available equipment
    func createWorkoutPlansForEquipment(_ equipment: [EquipmentItem]) -> [WorkoutPlanData] {
        let selectedEquipment = equipment.filter { $0.isSelected }
        
        guard !selectedEquipment.isEmpty else {
            return [createWorkoutPlan(name: "Bodyweight Only Plan")]
        }
        
        var plans: [WorkoutPlanData] = []
        
        // Create plans based on equipment categories
        let equipmentByCategory = Dictionary(grouping: selectedEquipment) { $0.category }
        
        for (category, categoryEquipment) in equipmentByCategory {
            let planName = "\(category) Workout"
            let exercises = categoryEquipment.flatMap { equipment in
                createExercisesForEquipment(equipment)
            }
            
            if !exercises.isEmpty {
                let plan = WorkoutPlanData(
                    id: UUID(),
                    name: planName,
                    exercises: Array(exercises.prefix(5)), // Limit to 5 exercises per plan
                    createdDate: Date(),
                    lastUsedDate: nil
                )
                plans.append(plan)
                createdPlanIds.insert(plan.id)
            }
        }
        
        return plans
    }
    
    /// Creates a workout plan with specific characteristics for testing
    func createSpecializedWorkoutPlan(
        type: WorkoutPlanType,
        difficulty: WorkoutDifficulty = .intermediate
    ) -> WorkoutPlanData {
        let (name, exercises) = generateSpecializedPlanContent(type: type, difficulty: difficulty)
        let plan = WorkoutPlanData(
            id: UUID(),
            name: name,
            exercises: exercises,
            createdDate: Date(),
            lastUsedDate: nil
        )
        
        createdPlanIds.insert(plan.id)
        return plan
    }
    
    // MARK: - Exercise Test Data Creation
    
    /// Creates exercises for a workout plan
    func createExercisesForPlan(count: Int, planName: String) -> [ExerciseData] {
        let baseExercises = [
            ("Push-ups", 3, 12, 0.0, 60),
            ("Squats", 3, 15, 0.0, 90),
            ("Plank", 3, 30, 0.0, 60),
            ("Lunges", 3, 10, 0.0, 75),
            ("Burpees", 3, 8, 0.0, 120),
            ("Mountain Climbers", 3, 20, 0.0, 45),
            ("Jumping Jacks", 3, 25, 0.0, 30),
            ("Deadlifts", 4, 8, 135.0, 180),
            ("Bench Press", 4, 10, 115.0, 150),
            ("Rows", 3, 12, 95.0, 120)
        ]
        
        let exercises = (0..<count).map { index in
            let baseExercise = baseExercises[index % baseExercises.count]
            let exerciseId = UUID()
            
            let exercise = ExerciseData(
                id: exerciseId,
                name: "\(baseExercise.0) (\(planName))",
                sets: baseExercise.1,
                reps: baseExercise.2,
                weight: baseExercise.3,
                restTime: baseExercise.4,
                orderIndex: index
            )
            
            createdExerciseIds.insert(exerciseId)
            return exercise
        }
        
        return exercises
    }
    
    /// Creates exercises specific to equipment type
    func createExercisesForEquipment(_ equipment: EquipmentItem) -> [ExerciseData] {
        let exercisesByEquipment: [String: [(String, Int, Int, Double, Int)]] = [
            "Dumbbells": [
                ("Dumbbell Press", 3, 10, 25.0, 90),
                ("Dumbbell Rows", 3, 12, 20.0, 75),
                ("Dumbbell Curls", 3, 15, 15.0, 60)
            ],
            "Barbell": [
                ("Barbell Squats", 4, 8, 135.0, 180),
                ("Deadlifts", 4, 6, 185.0, 240),
                ("Barbell Rows", 3, 10, 95.0, 120)
            ],
            "Kettlebell": [
                ("Kettlebell Swings", 3, 20, 35.0, 90),
                ("Goblet Squats", 3, 15, 25.0, 75),
                ("Turkish Get-ups", 3, 5, 20.0, 120)
            ],
            "Resistance Bands": [
                ("Band Pull-aparts", 3, 20, 0.0, 45),
                ("Band Squats", 3, 15, 0.0, 60),
                ("Band Rows", 3, 12, 0.0, 60)
            ]
        ]
        
        let exerciseTemplates = exercisesByEquipment[equipment.name] ?? [
            ("Generic Exercise", 3, 10, 0.0, 60)
        ]
        
        return exerciseTemplates.enumerated().map { index, template in
            let exerciseId = UUID()
            let exercise = ExerciseData(
                id: exerciseId,
                name: template.0,
                sets: template.1,
                reps: template.2,
                weight: template.3,
                restTime: template.4,
                orderIndex: index
            )
            
            createdExerciseIds.insert(exerciseId)
            return exercise
        }
    }
    
    /// Creates a single exercise with specified parameters
    func createExercise(
        name: String,
        sets: Int = 3,
        reps: Int = 10,
        weight: Double = 0.0,
        restTime: Int = 60,
        orderIndex: Int = 0
    ) -> ExerciseData {
        let exerciseId = UUID()
        let exercise = ExerciseData(
            id: exerciseId,
            name: name,
            sets: sets,
            reps: reps,
            weight: weight,
            restTime: restTime,
            orderIndex: orderIndex
        )
        
        createdExerciseIds.insert(exerciseId)
        return exercise
    }
    
    // MARK: - Specialized Test Data
    
    /// Creates test data for performance testing scenarios
    func createPerformanceTestData() -> (equipment: [EquipmentItem], plans: [WorkoutPlanData]) {
        let equipment = createLargeEquipmentSet(count: 100)
        let plans = createMultipleWorkoutPlans(count: 50, exercisesPerPlan: 8)
        return (equipment, plans)
    }
    
    /// Creates test data for stress testing scenarios
    func createStressTestData() -> (equipment: [EquipmentItem], plans: [WorkoutPlanData]) {
        let equipment = createLargeEquipmentSet(count: 500)
        let plans = createMultipleWorkoutPlans(count: 200, exercisesPerPlan: 12)
        return (equipment, plans)
    }
    
    /// Creates test data for edge case testing
    func createEdgeCaseTestData() -> (equipment: [EquipmentItem], plans: [WorkoutPlanData]) {
        var equipment: [EquipmentItem] = []
        var plans: [WorkoutPlanData] = []
        
        // Empty equipment selection
        equipment.append(createEquipmentItem(id: "empty-test", name: "", category: "", isSelected: false))
        
        // Equipment with special characters
        equipment.append(createEquipmentItem(id: "special-chars", name: "Equipment with émojis 🏋️‍♂️", category: "Special", isSelected: true))
        
        // Very long names
        let longName = String(repeating: "Very Long Equipment Name ", count: 10)
        equipment.append(createEquipmentItem(id: "long-name", name: longName, category: "Long", isSelected: true))
        
        // Plan with no exercises
        let emptyPlan = WorkoutPlanData(
            id: UUID(),
            name: "Empty Plan",
            exercises: [],
            createdDate: Date(),
            lastUsedDate: nil
        )
        plans.append(emptyPlan)
        createdPlanIds.insert(emptyPlan.id)
        
        // Plan with many exercises
        let manyExercisesPlan = createWorkoutPlan(name: "Many Exercises Plan", exerciseCount: 50)
        plans.append(manyExercisesPlan)
        
        // Plan with extreme values
        let extremeExercise = createExercise(
            name: "Extreme Exercise",
            sets: 100,
            reps: 1000,
            weight: 999.99,
            restTime: 3600
        )
        let extremePlan = WorkoutPlanData(
            id: UUID(),
            name: "Extreme Plan",
            exercises: [extremeExercise],
            createdDate: Date.distantPast,
            lastUsedDate: Date.distantFuture
        )
        plans.append(extremePlan)
        createdPlanIds.insert(extremePlan.id)
        
        return (equipment, plans)
    }
    
    // MARK: - Cleanup Utilities
    
    /// Cleans up all created test data
    func cleanup() async {
        createdEquipmentIds.removeAll()
        createdPlanIds.removeAll()
        createdExerciseIds.removeAll()
    }
    
    /// Returns the count of created test items for verification
    func getCreatedItemCounts() -> (equipment: Int, plans: Int, exercises: Int) {
        return (
            equipment: createdEquipmentIds.count,
            plans: createdPlanIds.count,
            exercises: createdExerciseIds.count
        )
    }
    
    /// Verifies that all created items have unique IDs
    func verifyDataIntegrity() -> Bool {
        // Check for duplicate equipment IDs
        let equipmentIdCount = createdEquipmentIds.count
        let uniqueEquipmentIds = Set(createdEquipmentIds)
        
        // Check for duplicate plan IDs
        let planIdCount = createdPlanIds.count
        let uniquePlanIds = Set(createdPlanIds)
        
        // Check for duplicate exercise IDs
        let exerciseIdCount = createdExerciseIds.count
        let uniqueExerciseIds = Set(createdExerciseIds)
        
        return equipmentIdCount == uniqueEquipmentIds.count &&
               planIdCount == uniquePlanIds.count &&
               exerciseIdCount == uniqueExerciseIds.count
    }
    
    // MARK: - Private Helper Methods
    
    private func generateSpecializedPlanContent(
        type: WorkoutPlanType,
        difficulty: WorkoutDifficulty
    ) -> (name: String, exercises: [ExerciseData]) {
        let difficultyMultiplier = difficulty.multiplier
        
        switch type {
        case .strength:
            let exercises = [
                createExercise(name: "Squats", sets: 4, reps: Int(8 * difficultyMultiplier), weight: 135.0 * difficultyMultiplier),
                createExercise(name: "Deadlifts", sets: 4, reps: Int(6 * difficultyMultiplier), weight: 185.0 * difficultyMultiplier),
                createExercise(name: "Bench Press", sets: 4, reps: Int(8 * difficultyMultiplier), weight: 115.0 * difficultyMultiplier),
                createExercise(name: "Overhead Press", sets: 3, reps: Int(10 * difficultyMultiplier), weight: 75.0 * difficultyMultiplier)
            ]
            return ("Strength Training - \(difficulty.rawValue.capitalized)", exercises)
            
        case .cardio:
            let exercises = [
                createExercise(name: "Burpees", sets: 3, reps: Int(10 * difficultyMultiplier), restTime: 30),
                createExercise(name: "Mountain Climbers", sets: 3, reps: Int(20 * difficultyMultiplier), restTime: 30),
                createExercise(name: "Jumping Jacks", sets: 3, reps: Int(30 * difficultyMultiplier), restTime: 30),
                createExercise(name: "High Knees", sets: 3, reps: Int(25 * difficultyMultiplier), restTime: 30)
            ]
            return ("Cardio Blast - \(difficulty.rawValue.capitalized)", exercises)
            
        case .flexibility:
            let exercises = [
                createExercise(name: "Forward Fold", sets: 1, reps: 1, restTime: 30),
                createExercise(name: "Pigeon Pose", sets: 1, reps: 1, restTime: 60),
                createExercise(name: "Spinal Twist", sets: 1, reps: 1, restTime: 30),
                createExercise(name: "Child's Pose", sets: 1, reps: 1, restTime: 60)
            ]
            return ("Flexibility Flow - \(difficulty.rawValue.capitalized)", exercises)
            
        case .functional:
            let exercises = [
                createExercise(name: "Farmer's Walk", sets: 3, reps: 1, weight: 50.0 * difficultyMultiplier, restTime: 90),
                createExercise(name: "Turkish Get-ups", sets: 3, reps: Int(5 * difficultyMultiplier), weight: 20.0 * difficultyMultiplier),
                createExercise(name: "Bear Crawl", sets: 3, reps: Int(10 * difficultyMultiplier), restTime: 60),
                createExercise(name: "Single Leg Deadlift", sets: 3, reps: Int(8 * difficultyMultiplier), weight: 25.0 * difficultyMultiplier)
            ]
            return ("Functional Movement - \(difficulty.rawValue.capitalized)", exercises)
        }
    }
}

// MARK: - Supporting Enums

enum WorkoutPlanType {
    case strength
    case cardio
    case flexibility
    case functional
}

enum WorkoutDifficulty: String {
    case beginner
    case intermediate
    case advanced
    
    var multiplier: Double {
        switch self {
        case .beginner: return 0.7
        case .intermediate: return 1.0
        case .advanced: return 1.5
        }
    }
}

// MARK: - Test Data Validation Extensions

extension TestDataFactory {
    
    /// Validates that created workout plans have proper structure
    func validateWorkoutPlans(_ plans: [WorkoutPlanData]) -> [String] {
        var validationErrors: [String] = []
        
        for plan in plans {
            // Check plan name
            if plan.name.isEmpty {
                validationErrors.append("Plan \(plan.id) has empty name")
            }
            
            // Check exercises
            if plan.exercises.isEmpty {
                validationErrors.append("Plan '\(plan.name)' has no exercises")
            }
            
            // Check exercise order
            let expectedOrder = Array(0..<plan.exercises.count)
            let actualOrder = plan.exercises.map { $0.orderIndex }.sorted()
            if expectedOrder != actualOrder {
                validationErrors.append("Plan '\(plan.name)' has incorrect exercise order")
            }
            
            // Check exercise values
            for exercise in plan.exercises {
                if exercise.name.isEmpty {
                    validationErrors.append("Exercise in plan '\(plan.name)' has empty name")
                }
                if exercise.sets.isEmpty {
                    validationErrors.append("Exercise '\(exercise.name)' has no sets")
                }
                if exercise.averageReps <= 0 {
                    validationErrors.append("Exercise '\(exercise.name)' has invalid average reps")
                }
                if exercise.averageWeight < 0 {
                    validationErrors.append("Exercise '\(exercise.name)' has negative average weight")
                }
                if exercise.restTime < 0 {
                    validationErrors.append("Exercise '\(exercise.name)' has negative rest time")
                }
            }
        }
        
        return validationErrors
    }
    
    /// Validates that created equipment has proper structure
    func validateEquipment(_ equipment: [EquipmentItem]) -> [String] {
        var validationErrors: [String] = []
        
        for item in equipment {
            if item.id.isEmpty {
                validationErrors.append("Equipment item has empty ID")
            }
            if item.name.isEmpty {
                validationErrors.append("Equipment item '\(item.id)' has empty name")
            }
            if item.category.isEmpty {
                validationErrors.append("Equipment item '\(item.name)' has empty category")
            }
        }
        
        // Check for duplicate IDs
        let ids = equipment.map { $0.id }
        let uniqueIds = Set(ids)
        if ids.count != uniqueIds.count {
            validationErrors.append("Duplicate equipment IDs found")
        }
        
        return validationErrors
    }
}
import XCTest
@testable import VoltLift

final class UserPreferencesModelsTests: XCTestCase {
    
    // MARK: - EquipmentItem Tests
    
    func testEquipmentItemInitialization() {
        // Given
        let id = "barbell-001"
        let name = "Olympic Barbell"
        let category = "Barbells"
        
        // When
        let equipment = EquipmentItem(id: id, name: name, category: category)
        
        // Then
        XCTAssertEqual(equipment.id, id)
        XCTAssertEqual(equipment.name, name)
        XCTAssertEqual(equipment.category, category)
        XCTAssertFalse(equipment.isSelected) // Default should be false
    }
    
    func testEquipmentItemInitializationWithSelection() {
        // Given
        let id = "dumbbell-001"
        let name = "Adjustable Dumbbells"
        let category = "Dumbbells"
        let isSelected = true
        
        // When
        let equipment = EquipmentItem(id: id, name: name, category: category, isSelected: isSelected)
        
        // Then
        XCTAssertEqual(equipment.id, id)
        XCTAssertEqual(equipment.name, name)
        XCTAssertEqual(equipment.category, category)
        XCTAssertTrue(equipment.isSelected)
    }
    
    func testEquipmentItemCodable() throws {
        // Given
        let originalEquipment = EquipmentItem(
            id: "kettlebell-001",
            name: "16kg Kettlebell",
            category: "Kettlebells",
            isSelected: true
        )
        
        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalEquipment)
        
        // Then - Decode
        let decoder = JSONDecoder()
        let decodedEquipment = try decoder.decode(EquipmentItem.self, from: data)
        
        XCTAssertEqual(originalEquipment, decodedEquipment)
    }
    
    func testEquipmentItemEquality() {
        // Given
        let equipment1 = EquipmentItem(id: "test-001", name: "Test Equipment", category: "Test", isSelected: false)
        let equipment2 = EquipmentItem(id: "test-001", name: "Test Equipment", category: "Test", isSelected: false)
        let equipment3 = EquipmentItem(id: "test-002", name: "Test Equipment", category: "Test", isSelected: false)
        
        // Then
        XCTAssertEqual(equipment1, equipment2)
        XCTAssertNotEqual(equipment1, equipment3)
    }
    
    // MARK: - ExerciseData Tests
    
    func testExerciseDataInitialization() {
        // Given
        let name = "Bench Press"
        let sets = 3
        let reps = 10
        let weight = 80.5
        let restTime = 120
        let orderIndex = 1
        
        // When
        let exercise = ExerciseData(
            name: name,
            sets: sets,
            reps: reps,
            weight: weight,
            restTime: restTime,
            orderIndex: orderIndex
        )
        
        // Then
        XCTAssertNotNil(exercise.id)
        XCTAssertEqual(exercise.name, name)
        XCTAssertEqual(exercise.totalSets, sets)
        XCTAssertEqual(exercise.averageReps, reps)
        XCTAssertEqual(exercise.averageWeight, weight)
        XCTAssertEqual(exercise.restTime, restTime)
        XCTAssertEqual(exercise.orderIndex, orderIndex)
    }
    
    func testExerciseDataDefaultOrderIndex() {
        // When
        let exercise = ExerciseData(
            name: "Squat",
            sets: 4,
            reps: 8,
            weight: 100.0,
            restTime: 180
        )
        
        // Then
        XCTAssertEqual(exercise.orderIndex, 0) // Default should be 0
    }
    
    func testExerciseDataCodable() throws {
        // Given
        let originalExercise = ExerciseData(
            id: UUID(),
            name: "Deadlift",
            sets: 5,
            reps: 5,
            weight: 120.0,
            restTime: 240,
            orderIndex: 2
        )
        
        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalExercise)
        
        // Then - Decode
        let decoder = JSONDecoder()
        let decodedExercise = try decoder.decode(ExerciseData.self, from: data)
        
        XCTAssertEqual(originalExercise, decodedExercise)
    }
    
    // MARK: - WorkoutPlanData Tests
    
    func testWorkoutPlanDataInitialization() {
        // Given
        let name = "Push Day"
        let exercises = [
            ExerciseData(name: "Bench Press", sets: 3, reps: 10, weight: 80.0, restTime: 120, orderIndex: 0),
            ExerciseData(name: "Shoulder Press", sets: 3, reps: 12, weight: 40.0, restTime: 90, orderIndex: 1)
        ]
        let createdDate = Date()
        
        // When
        let plan = WorkoutPlanData(
            name: name,
            exercises: exercises,
            createdDate: createdDate
        )
        
        // Then
        XCTAssertNotNil(plan.id)
        XCTAssertEqual(plan.name, name)
        XCTAssertEqual(plan.exercises, exercises)
        XCTAssertEqual(plan.createdDate, createdDate)
        XCTAssertNil(plan.lastUsedDate)
        XCTAssertEqual(plan.exerciseCount, 2)
    }
    
    func testWorkoutPlanDataExerciseCount() {
        // Given
        let emptyPlan = WorkoutPlanData(name: "Empty Plan", exercises: [])
        let singleExercisePlan = WorkoutPlanData(
            name: "Single Exercise",
            exercises: [ExerciseData(name: "Push-up", sets: 3, reps: 15, weight: 0, restTime: 60)]
        )
        let multiExercisePlan = WorkoutPlanData(
            name: "Multi Exercise",
            exercises: [
                ExerciseData(name: "Exercise 1", sets: 3, reps: 10, weight: 50, restTime: 90),
                ExerciseData(name: "Exercise 2", sets: 4, reps: 8, weight: 60, restTime: 120),
                ExerciseData(name: "Exercise 3", sets: 2, reps: 15, weight: 30, restTime: 60)
            ]
        )
        
        // Then
        XCTAssertEqual(emptyPlan.exerciseCount, 0)
        XCTAssertEqual(singleExercisePlan.exerciseCount, 1)
        XCTAssertEqual(multiExercisePlan.exerciseCount, 3)
    }
    
    func testWorkoutPlanDataCodable() throws {
        // Given
        let exercises = [
            ExerciseData(name: "Squat", sets: 4, reps: 8, weight: 100.0, restTime: 180, orderIndex: 0),
            ExerciseData(name: "Leg Press", sets: 3, reps: 12, weight: 150.0, restTime: 120, orderIndex: 1)
        ]
        let originalPlan = WorkoutPlanData(
            id: UUID(),
            name: "Leg Day",
            exercises: exercises,
            createdDate: Date(),
            lastUsedDate: Date()
        )
        
        // When - Encode
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(originalPlan)
        
        // Then - Decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedPlan = try decoder.decode(WorkoutPlanData.self, from: data)
        
        XCTAssertEqual(originalPlan.id, decodedPlan.id)
        XCTAssertEqual(originalPlan.name, decodedPlan.name)
        XCTAssertEqual(originalPlan.exercises, decodedPlan.exercises)
        XCTAssertEqual(originalPlan.exerciseCount, decodedPlan.exerciseCount)
    }
    
    // MARK: - UserPreferencesError Tests
    
    func testUserPreferencesErrorDescriptions() {
        // Given
        let saveError = UserPreferencesError.saveFailure(underlying: "Core Data error")
        let loadError = UserPreferencesError.loadFailure(underlying: "File not found")
        let corruptionError = UserPreferencesError.dataCorruption
        let invalidDataError = UserPreferencesError.invalidData(field: "exercise name")
        let planNotFoundError = UserPreferencesError.planNotFound(id: UUID())
        let equipmentNotFoundError = UserPreferencesError.equipmentNotFound(id: "test-001")
        
        // Then
        XCTAssertEqual(saveError.errorDescription, "Failed to save your preferences. Please try again.")
        XCTAssertEqual(loadError.errorDescription, "Unable to load your saved data. Using defaults.")
        XCTAssertEqual(corruptionError.errorDescription, "Data corruption detected. Preferences will be reset.")
        XCTAssertEqual(invalidDataError.errorDescription, "Invalid data detected in exercise name. Please check your input.")
        XCTAssertEqual(planNotFoundError.errorDescription, "The requested workout plan could not be found.")
        XCTAssertEqual(equipmentNotFoundError.errorDescription, "The requested equipment item could not be found.")
    }
    
    func testUserPreferencesErrorFailureReasons() {
        // Given
        let saveError = UserPreferencesError.saveFailure(underlying: "Disk full")
        let planId = UUID()
        let planNotFoundError = UserPreferencesError.planNotFound(id: planId)
        
        // Then
        XCTAssertEqual(saveError.failureReason, "Save operation failed: Disk full")
        XCTAssertEqual(planNotFoundError.failureReason, "No workout plan found with ID: \(planId)")
    }
    
    func testUserPreferencesErrorRecoverySuggestions() {
        // Given
        let corruptionError = UserPreferencesError.dataCorruption
        let invalidDataError = UserPreferencesError.invalidData(field: "weight")
        
        // Then
        XCTAssertEqual(corruptionError.recoverySuggestion, "Your preferences will be reset to defaults. You can reconfigure them in Settings.")
        XCTAssertEqual(invalidDataError.recoverySuggestion, "Please verify your input and try again.")
    }
    
    func testUserPreferencesErrorEquality() {
        // Given
        let error1 = UserPreferencesError.dataCorruption
        let error2 = UserPreferencesError.dataCorruption
        let error3 = UserPreferencesError.saveFailure(underlying: "test")
        let error4 = UserPreferencesError.saveFailure(underlying: "test")
        let error5 = UserPreferencesError.saveFailure(underlying: "different")
        
        // Then
        XCTAssertEqual(error1, error2)
        XCTAssertEqual(error3, error4)
        XCTAssertNotEqual(error3, error5)
        XCTAssertNotEqual(error1, error3)
    }
    
    // MARK: - JSON Serialization Edge Cases
    
    func testEquipmentItemJSONWithSpecialCharacters() throws {
        // Given
        let equipment = EquipmentItem(
            id: "special-001",
            name: "Equipment with \"quotes\" and émojis 💪",
            category: "Special/Category",
            isSelected: true
        )
        
        // When - Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(equipment)
        
        // Then - Decode from JSON
        let decoder = JSONDecoder()
        let decodedEquipment = try decoder.decode(EquipmentItem.self, from: data)
        
        XCTAssertEqual(equipment, decodedEquipment)
    }
    
    func testWorkoutPlanDataWithEmptyExercises() throws {
        // Given
        let plan = WorkoutPlanData(name: "Empty Plan", exercises: [])
        
        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(plan)
        
        // Then - Decode
        let decoder = JSONDecoder()
        let decodedPlan = try decoder.decode(WorkoutPlanData.self, from: data)
        
        XCTAssertEqual(plan.name, decodedPlan.name)
        XCTAssertEqual(plan.exercises.count, 0)
        XCTAssertEqual(decodedPlan.exercises.count, 0)
        XCTAssertEqual(plan.exerciseCount, 0)
        XCTAssertEqual(decodedPlan.exerciseCount, 0)
    }
    
    func testExerciseDataWithZeroValues() throws {
        // Given
        let exercise = ExerciseData(
            name: "Bodyweight Exercise",
            sets: 0,
            reps: 0,
            weight: 0.0,
            restTime: 0,
            orderIndex: 0
        )
        
        // When - Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(exercise)
        
        // Then - Decode
        let decoder = JSONDecoder()
        let decodedExercise = try decoder.decode(ExerciseData.self, from: data)
        
        XCTAssertEqual(exercise, decodedExercise)
        XCTAssertEqual(decodedExercise.totalSets, 0)
        XCTAssertEqual(decodedExercise.averageReps, 0)
        XCTAssertEqual(decodedExercise.averageWeight, 0.0)
        XCTAssertEqual(decodedExercise.restTime, 0)
    }
}
import XCTest
import CoreData
@testable import VoltLift

final class ExerciseServiceTests: XCTestCase {
    
    var exerciseService: ExerciseService!
    
    override func setUp() {
        super.setUp()
        
        // Use the shared service for testing
        exerciseService = ExerciseService.shared
    }
    
    override func tearDown() {
        exerciseService = nil
        super.tearDown()
    }
    
    // MARK: - getAllExercises Tests
    
    func testGetAllExercises_ReturnsNonEmptyArray() {
        // When
        let exercises = exerciseService.getAllExercises()
        
        // Then
        XCTAssertFalse(exercises.isEmpty, "Should return non-empty array of exercises")
        XCTAssertGreaterThan(exercises.count, 20, "Should have more than 20 exercises")
    }
    
    func testGetAllExercises_ContainsExpectedExercises() {
        // When
        let exercises = exerciseService.getAllExercises()
        let exerciseNames = exercises.map { $0.name }
        
        // Then
        XCTAssertTrue(exerciseNames.contains("Push-up"), "Should contain Push-up exercise")
        XCTAssertTrue(exerciseNames.contains("Bodyweight Squat"), "Should contain Bodyweight Squat exercise")
        XCTAssertTrue(exerciseNames.contains("Plank"), "Should contain Plank exercise")
    }
    
    // MARK: - getExercises(for:availableEquipment:) Tests
    
    func testGetExercisesForMuscleGroup_WithNoEquipment_ReturnsBodyweightExercises() {
        // Given
        let availableEquipment: Set<String> = []
        
        // When
        let chestExercises = exerciseService.getExercises(for: .chest, availableEquipment: availableEquipment)
        let legExercises = exerciseService.getExercises(for: .legs, availableEquipment: availableEquipment)
        let coreExercises = exerciseService.getExercises(for: .core, availableEquipment: availableEquipment)
        
        // Then
        XCTAssertTrue(chestExercises.contains { $0.name == "Push-up" }, "Should contain Push-up for chest")
        XCTAssertTrue(legExercises.contains { $0.name == "Bodyweight Squat" }, "Should contain Bodyweight Squat for legs")
        XCTAssertTrue(coreExercises.contains { $0.name == "Plank" }, "Should contain Plank for core")
        
        // Verify no equipment-requiring exercises are returned
        for exercise in chestExercises + legExercises + coreExercises {
            XCTAssertTrue(exercise.requiredEquipment.isEmpty, "Exercise \(exercise.name) should not require equipment")
        }
    }
    
    func testGetExercisesForMuscleGroup_WithDumbbells_ReturnsAppropriateExercises() {
        // Given
        let availableEquipment: Set<String> = ["Dumbbells"]
        
        // When
        let chestExercises = exerciseService.getExercises(for: .chest, availableEquipment: availableEquipment)
        let armExercises = exerciseService.getExercises(for: .arms, availableEquipment: availableEquipment)
        
        // Then
        XCTAssertTrue(chestExercises.contains { $0.name == "Push-up" }, "Should contain bodyweight exercises")
        XCTAssertTrue(armExercises.contains { $0.name == "Biceps Curl" }, "Should contain Biceps Curl")
        
        // Verify exercises requiring unavailable equipment are not returned
        XCTAssertFalse(chestExercises.contains { $0.name == "Dumbbell Bench Press" }, "Should not contain exercises requiring bench")
    }
    
    func testGetExercisesForMuscleGroup_ResultsAreSorted() {
        // Given
        let availableEquipment: Set<String> = ["Dumbbells", "Adjustable Bench", "Resistance Bands"]
        
        // When
        let exercises = exerciseService.getExercises(for: .chest, availableEquipment: availableEquipment)
        
        // Then
        let exerciseNames = exercises.map { $0.name }
        let sortedNames = exerciseNames.sorted()
        XCTAssertEqual(exerciseNames, sortedNames, "Exercises should be sorted alphabetically by name")
    }
    
    // MARK: - getExercisesWithEquipmentHints Tests
    
    func testGetExercisesWithEquipmentHints_WithNoEquipment_ShowsAllExercisesWithAvailabilityStatus() {
        // Given
        let availableEquipment: Set<String> = []
        
        // When
        let displayItems = exerciseService.getExercisesWithEquipmentHints(for: .chest, availableEquipment: availableEquipment)
        
        // Then
        XCTAssertFalse(displayItems.isEmpty, "Should return exercises even with no equipment")
        
        let pushUpItem = displayItems.first { $0.exercise.name == "Push-up" }
        XCTAssertNotNil(pushUpItem, "Should contain Push-up")
        XCTAssertTrue(pushUpItem?.isAvailable == true, "Push-up should be available with no equipment")
        XCTAssertTrue(pushUpItem?.missingEquipment.isEmpty == true, "Push-up should have no missing equipment")
        
        let benchPressItem = displayItems.first { $0.exercise.name == "Dumbbell Bench Press" }
        XCTAssertNotNil(benchPressItem, "Should contain Dumbbell Bench Press")
        XCTAssertTrue(benchPressItem?.isAvailable == false, "Dumbbell Bench Press should not be available")
        XCTAssertFalse(benchPressItem?.missingEquipment.isEmpty == true, "Should show missing equipment")
    }
    
    func testGetExercisesWithEquipmentHints_SortsAvailableExercisesFirst() {
        // Given
        let availableEquipment: Set<String> = ["Dumbbells"]
        
        // When
        let displayItems = exerciseService.getExercisesWithEquipmentHints(for: .chest, availableEquipment: availableEquipment)
        
        // Then
        let availableItems = displayItems.filter { $0.isAvailable }
        let unavailableItems = displayItems.filter { !$0.isAvailable }
        
        // Check that available exercises come first
        let firstAvailableIndex = displayItems.firstIndex { $0.isAvailable } ?? -1
        let firstUnavailableIndex = displayItems.firstIndex { !$0.isAvailable } ?? displayItems.count
        
        if !availableItems.isEmpty && !unavailableItems.isEmpty {
            XCTAssertLessThan(firstAvailableIndex, firstUnavailableIndex, "Available exercises should come before unavailable ones")
        }
    }
    
    // MARK: - getExercise(by:) Tests
    
    func testGetExerciseById_WithValidId_ReturnsCorrectExercise() {
        // Given
        let allExercises = exerciseService.getAllExercises()
        guard let firstExercise = allExercises.first else {
            XCTFail("Should have at least one exercise")
            return
        }
        
        // When
        let foundExercise = exerciseService.getExercise(by: firstExercise.id)
        
        // Then
        XCTAssertNotNil(foundExercise, "Should find exercise by valid ID")
        XCTAssertEqual(foundExercise?.id, firstExercise.id, "Should return exercise with matching ID")
        XCTAssertEqual(foundExercise?.name, firstExercise.name, "Should return exercise with matching name")
    }
    
    func testGetExerciseById_WithInvalidId_ReturnsNil() {
        // Given
        let invalidId = UUID()
        
        // When
        let foundExercise = exerciseService.getExercise(by: invalidId)
        
        // Then
        XCTAssertNil(foundExercise, "Should return nil for invalid ID")
    }
    
    // MARK: - getExercises(for:availableEquipment:) Difficulty Tests
    
    func testGetExercisesForDifficulty_ReturnsCorrectExercises() {
        // Given
        let availableEquipment: Set<String> = []
        
        // When
        let beginnerExercises = exerciseService.getExercises(for: .beginner, availableEquipment: availableEquipment)
        let advancedExercises = exerciseService.getExercises(for: .advanced, availableEquipment: availableEquipment)
        
        // Then
        XCTAssertFalse(beginnerExercises.isEmpty, "Should have beginner exercises")
        
        for exercise in beginnerExercises {
            XCTAssertEqual(exercise.difficulty, .beginner, "All returned exercises should be beginner level")
            XCTAssertTrue(exercise.requiredEquipment.isSubset(of: availableEquipment), "Should only return exercises with available equipment")
        }
        
        for exercise in advancedExercises {
            XCTAssertEqual(exercise.difficulty, .advanced, "All returned exercises should be advanced level")
        }
    }
    
    // MARK: - getBodyweightExercises Tests
    
    func testGetBodyweightExercises_ReturnsOnlyEquipmentFreeExercises() {
        // When
        let bodyweightExercises = exerciseService.getBodyweightExercises()
        
        // Then
        XCTAssertFalse(bodyweightExercises.isEmpty, "Should have bodyweight exercises")
        
        for exercise in bodyweightExercises {
            XCTAssertTrue(exercise.requiredEquipment.isEmpty, "Exercise \(exercise.name) should require no equipment")
        }
        
        // Verify specific bodyweight exercises are included
        let exerciseNames = bodyweightExercises.map { $0.name }
        XCTAssertTrue(exerciseNames.contains("Push-up"), "Should contain Push-up")
        XCTAssertTrue(exerciseNames.contains("Bodyweight Squat"), "Should contain Bodyweight Squat")
        XCTAssertTrue(exerciseNames.contains("Plank"), "Should contain Plank")
    }
    
    // MARK: - Legacy Compatibility Tests
    
    func testGetLegacyExercises_ReturnsCompatibleFormat() {
        // Given
        let availableEquipment: Set<String> = ["Dumbbells"]
        
        // When
        let legacyExercises = exerciseService.getLegacyExercises(for: .chest, availableEquipment: availableEquipment)
        
        // Then
        XCTAssertFalse(legacyExercises.isEmpty, "Should return legacy exercises")
        
        for exercise in legacyExercises {
            XCTAssertEqual(exercise.muscleGroup.rawValue, "Chest", "Should have correct muscle group")
            XCTAssertTrue(exercise.requiredEquipment.isSubset(of: availableEquipment), "Should only return available exercises")
        }
    }
    
    func testExerciseCatalogCompatibility_UsesExerciseService() {
        // Given
        let availableEquipment: Set<String> = ["Dumbbells"]
        
        // When
        let catalogExercises = ExerciseCatalog.forGroupLegacy(.chest, availableEquipment: availableEquipment)
        let serviceExercises = exerciseService.getLegacyExercises(for: .chest, availableEquipment: availableEquipment)
        
        // Then
        XCTAssertEqual(catalogExercises.count, serviceExercises.count, "Catalog should return same count as service")
        
        let catalogNames = Set(catalogExercises.map { $0.name })
        let serviceNames = Set(serviceExercises.map { $0.name })
        XCTAssertEqual(catalogNames, serviceNames, "Catalog should return same exercises as service")
    }
    
    func testExerciseCatalogEnhanced_ReturnsExerciseDisplayItems() {
        // Given
        let availableEquipment: Set<String> = ["Dumbbells"]
        
        // When
        let displayItems = ExerciseCatalog.forGroup(.chest, availableEquipment: availableEquipment)
        
        // Then
        XCTAssertFalse(displayItems.isEmpty, "Should return exercise display items")
        
        // Verify all items are ExerciseDisplayItem objects with proper structure
        for item in displayItems {
            XCTAssertFalse(item.exercise.name.isEmpty, "Exercise should have non-empty name")
            XCTAssertEqual(item.exercise.muscleGroup.rawValue, "Chest", "Should have correct muscle group")
            
            // Verify equipment availability logic
            let hasRequiredEquipment = item.exercise.requiredEquipment.isSubset(of: availableEquipment)
            XCTAssertEqual(item.isAvailable, hasRequiredEquipment, "Availability should match equipment requirements")
            
            if !item.isAvailable {
                let expectedMissing = item.exercise.requiredEquipment.subtracting(availableEquipment)
                XCTAssertEqual(item.missingEquipment, expectedMissing, "Missing equipment should be calculated correctly")
            }
        }
        
        // Verify that available exercises come first in the sorted list
        var foundUnavailable = false
        for item in displayItems {
            if foundUnavailable && item.isAvailable {
                XCTFail("Available exercises should come before unavailable ones")
            }
            if !item.isAvailable {
                foundUnavailable = true
            }
        }
    }
    
    // MARK: - Exercise Model Validation Tests
    
    func testAllExercises_HaveRequiredProperties() {
        // When
        let exercises = exerciseService.getAllExercises()
        
        // Then
        for exercise in exercises {
            XCTAssertFalse(exercise.name.isEmpty, "Exercise should have non-empty name")
            XCTAssertFalse(exercise.description.isEmpty, "Exercise should have non-empty description")
            XCTAssertFalse(exercise.instructions.isEmpty, "Exercise should have instructions")
            XCTAssertFalse(exercise.safetyTips.isEmpty, "Exercise should have safety tips")
            XCTAssertFalse(exercise.targetMuscles.isEmpty, "Exercise should have target muscles")
            XCTAssertFalse(exercise.sfSymbolName.isEmpty, "Exercise should have SF Symbol name")
        }
    }
    
    func testAllExercises_HaveValidMuscleGroups() {
        // When
        let exercises = exerciseService.getAllExercises()
        
        // Then
        let validMuscleGroups = Set(MuscleGroup.allCases)
        
        for exercise in exercises {
            XCTAssertTrue(validMuscleGroups.contains(exercise.muscleGroup), 
                         "Exercise \(exercise.name) should have valid muscle group")
        }
    }
    
    func testAllExercises_HaveValidDifficultyLevels() {
        // When
        let exercises = exerciseService.getAllExercises()
        
        // Then
        let validDifficulties = Set(DifficultyLevel.allCases)
        
        for exercise in exercises {
            XCTAssertTrue(validDifficulties.contains(exercise.difficulty), 
                         "Exercise \(exercise.name) should have valid difficulty level")
        }
    }
    
    // MARK: - Exercise Metadata Tests
    
    func testGetRecentlyUsedExercises_ReturnsEmptyArrayInitially() async {
        // When
        let recentExercises = await exerciseService.getRecentlyUsedExercises(limit: 10)
        
        // Then
        XCTAssertTrue(recentExercises.isEmpty, "Should return empty array initially")
    }
    
    func testGetMostUsedExercises_ReturnsEmptyArrayInitially() async {
        // When
        let mostUsedExercises = await exerciseService.getMostUsedExercises(limit: 5)
        
        // Then
        XCTAssertTrue(mostUsedExercises.isEmpty, "Should return empty array initially")
    }
    
    func testRecordExerciseUsage_WithValidId_DoesNotCrash() async {
        // Given
        let exercise = exerciseService.getAllExercises().first!
        
        // When & Then - Should not crash
        await exerciseService.recordExerciseUsage(exerciseId: exercise.id)
    }
    
    func testRecordExerciseUsage_WithInvalidId_DoesNotCrash() async {
        // Given
        let invalidId = UUID()
        
        // When & Then - Should not crash
        await exerciseService.recordExerciseUsage(exerciseId: invalidId)
    }
    
    // MARK: - Enhanced Exercise System Integration Tests
    
    func testExerciseService_IntegratesWithEnhancedCatalog() {
        // Given
        let allExercises = exerciseService.getAllExercises()
        
        // Then
        XCTAssertFalse(allExercises.isEmpty, "Should return exercises from enhanced catalog")
        
        // Verify enhanced properties are present
        for exercise in allExercises.prefix(5) { // Test first 5 for performance
            XCTAssertFalse(exercise.description.isEmpty, "Exercise should have description")
            XCTAssertFalse(exercise.instructions.isEmpty, "Exercise should have instructions")
            XCTAssertFalse(exercise.safetyTips.isEmpty, "Exercise should have safety tips")
            XCTAssertFalse(exercise.targetMuscles.isEmpty, "Exercise should have target muscles")
            XCTAssertFalse(exercise.sfSymbolName.isEmpty, "Exercise should have SF Symbol name")
        }
    }
    
    func testExerciseService_HandlesComplexEquipmentFiltering() {
        // Given
        let complexEquipment: Set<String> = ["Dumbbells", "Adjustable Bench", "Resistance Bands"]
        
        // When
        let chestExercises = exerciseService.getExercises(for: .chest, availableEquipment: complexEquipment)
        let displayItems = exerciseService.getExercisesWithEquipmentHints(for: .chest, availableEquipment: complexEquipment)
        
        // Then
        XCTAssertFalse(chestExercises.isEmpty, "Should return exercises for complex equipment setup")
        XCTAssertFalse(displayItems.isEmpty, "Should return display items for complex equipment setup")
        
        // Verify that all returned exercises can be performed with available equipment
        for exercise in chestExercises {
            XCTAssertTrue(exercise.requiredEquipment.isSubset(of: complexEquipment),
                         "Exercise '\(exercise.name)' should be performable with available equipment")
        }
        
        // Verify display items have correct availability status
        for item in displayItems {
            let expectedAvailability = item.exercise.requiredEquipment.isSubset(of: complexEquipment)
            XCTAssertEqual(item.isAvailable, expectedAvailability,
                          "Display item availability should match equipment requirements")
        }
    }
    
    func testExerciseService_PerformanceWithLargeDataset() {
        // Given
        let allMuscleGroups = MuscleGroup.allCases
        let complexEquipment: Set<String> = ["Dumbbells", "Barbell", "Weight Plates", "Adjustable Bench"]
        
        // When & Then
        measure {
            for muscleGroup in allMuscleGroups {
                _ = exerciseService.getExercisesWithEquipmentHints(for: muscleGroup, availableEquipment: complexEquipment)
            }
        }
    }
    
    func testExerciseService_ConsistentSortingBehavior() {
        // Given
        let availableEquipment: Set<String> = ["Dumbbells"]
        
        // When
        let firstCall = exerciseService.getExercisesWithEquipmentHints(for: .chest, availableEquipment: availableEquipment)
        let secondCall = exerciseService.getExercisesWithEquipmentHints(for: .chest, availableEquipment: availableEquipment)
        
        // Then
        XCTAssertEqual(firstCall.count, secondCall.count, "Should return consistent results")
        
        for (index, item) in firstCall.enumerated() {
            XCTAssertEqual(item.exercise.id, secondCall[index].exercise.id,
                          "Exercise order should be consistent across calls")
            XCTAssertEqual(item.isAvailable, secondCall[index].isAvailable,
                          "Availability should be consistent across calls")
        }
    }
}
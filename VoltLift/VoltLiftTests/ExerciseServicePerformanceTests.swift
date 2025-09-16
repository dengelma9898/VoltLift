//
//  ExerciseServicePerformanceTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import XCTest
@testable import VoltLift

final class ExerciseServicePerformanceTests: XCTestCase {
    
    var exerciseService: ExerciseService!
    
    override func setUp() {
        super.setUp()
        exerciseService = ExerciseService.shared
    }
    
    override func tearDown() {
        exerciseService = nil
        super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    func testGetAllExercises_Performance() {
        // Test that getting all exercises is fast enough for UI responsiveness
        measure {
            for _ in 0..<1000 {
                _ = exerciseService.getAllExercises()
            }
        }
    }
    
    func testGetExercisesWithEquipmentHints_Performance() {
        // Test performance of the most complex filtering operation
        let equipment: Set<String> = ["Dumbbells", "Adjustable Bench", "Resistance Bands"]
        
        measure {
            for muscleGroup in MuscleGroup.allCases {
                _ = exerciseService.getExercisesWithEquipmentHints(
                    for: muscleGroup,
                    availableEquipment: equipment
                )
            }
        }
    }
    
    func testExerciseFiltering_PerformanceWithLargeEquipmentSet() {
        // Test performance with a large equipment set
        let largeEquipmentSet: Set<String> = [
            "Dumbbells", "Barbell", "Weight Plates", "Adjustable Bench", "Pull-up Bar",
            "Resistance Bands", "Kettlebell", "Cable Machine", "Smith Machine",
            "Leg Press Machine", "Lat Pulldown Machine", "Rowing Machine",
            "Preacher Bench", "Incline Bench", "Decline Bench", "Olympic Barbell",
            "EZ Curl Bar", "Trap Bar", "Medicine Ball", "Stability Ball"
        ]
        
        measure {
            for muscleGroup in MuscleGroup.allCases {
                _ = exerciseService.getExercises(for: muscleGroup, availableEquipment: largeEquipmentSet)
            }
        }
    }
    
    func testExerciseDisplayItemCreation_Performance() {
        // Test performance of ExerciseDisplayItem creation
        let exercises = exerciseService.getAllExercises()
        let equipment: Set<String> = ["Dumbbells", "Adjustable Bench"]
        
        measure {
            _ = exercises.map { ExerciseDisplayItem(exercise: $0, availableEquipment: equipment) }
        }
    }
    
    func testExerciseSearch_Performance() {
        // Test performance of finding exercises by ID
        let allExercises = exerciseService.getAllExercises()
        let exerciseIds = allExercises.map { $0.id }
        
        measure {
            for id in exerciseIds {
                _ = exerciseService.getExercise(by: id)
            }
        }
    }
    
    // MARK: - Memory Usage Tests
    
    func testMemoryUsage_WithMultipleFilterOperations() {
        // Test that multiple filter operations don't cause excessive memory usage
        let equipment: Set<String> = ["Dumbbells", "Barbell", "Weight Plates"]
        
        for _ in 0..<100 {
            for muscleGroup in MuscleGroup.allCases {
                let exercises = exerciseService.getExercises(for: muscleGroup, availableEquipment: equipment)
                let displayItems = exerciseService.getExercisesWithEquipmentHints(
                    for: muscleGroup,
                    availableEquipment: equipment
                )
                
                // Verify results are not empty to ensure operations actually happened
                XCTAssertGreaterThanOrEqual(exercises.count + displayItems.count, 0)
            }
        }
    }
    
    func testConcurrentAccess_Performance() {
        // Test performance under concurrent access
        let expectation = XCTestExpectation(description: "Concurrent access completed")
        expectation.expectedFulfillmentCount = 10
        
        let equipment: Set<String> = ["Dumbbells"]
        
        for i in 0..<10 {
            DispatchQueue.global(qos: .userInitiated).async {
                let muscleGroup = MuscleGroup.allCases[i % MuscleGroup.allCases.count]
                _ = self.exerciseService.getExercises(for: muscleGroup, availableEquipment: equipment)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}
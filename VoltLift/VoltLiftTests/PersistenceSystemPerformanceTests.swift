//
//  PersistenceSystemPerformanceTests.swift
//  VoltLiftTests
//
//  Created by Kiro on 15.9.2025.
//

import CoreData
@testable import VoltLift
import XCTest

/// Performance tests for persistence system under various load conditions
/// Tests system behavior with large datasets, concurrent operations, and stress scenarios
final class PersistenceSystemPerformanceTests: XCTestCase {
    // MARK: - Properties

    private var userPreferencesService: UserPreferencesService!
    private var persistenceController: PersistenceController!
    private var testDataFactory: TestDataFactory!

    // MARK: - Setup and Teardown

    override func setUp() async throws {
        try await super.setUp()

        self.persistenceController = PersistenceController(inMemory: true)
        self.userPreferencesService = await UserPreferencesService(persistenceController: self.persistenceController)
        self.testDataFactory = TestDataFactory()
    }

    override func tearDown() async throws {
        await self.testDataFactory.cleanup()
        self.userPreferencesService = nil
        self.persistenceController = nil
        self.testDataFactory = nil
        try await super.tearDown()
    }

    // MARK: - Large Dataset Performance Tests

    /// Tests performance with large equipment datasets
    func testLargeEquipmentDatasetPerformance() async throws {
        let equipmentCounts = [100, 500, 1_000, 2_000]
        var results: [Int: (save: Double, load: Double)] = [:]

        for count in equipmentCounts {
            // Create large equipment dataset
            let equipment = self.testDataFactory.createLargeEquipmentSet(count: count)

            // Measure save performance
            let saveStartTime = CFAbsoluteTimeGetCurrent()
            try await userPreferencesService.saveEquipmentSelection(equipment)
            let saveEndTime = CFAbsoluteTimeGetCurrent()
            let saveTime = saveEndTime - saveStartTime

            // Clear cache to ensure fresh load
            await self.userPreferencesService.clearEquipmentCache()

            // Measure load performance
            let loadStartTime = CFAbsoluteTimeGetCurrent()
            try await userPreferencesService.loadSelectedEquipment()
            let loadEndTime = CFAbsoluteTimeGetCurrent()
            let loadTime = loadEndTime - loadStartTime

            results[count] = (save: saveTime, load: loadTime)

            // Performance assertions
            XCTAssertLessThan(saveTime, Double(count) * 0.01, "Save time should scale linearly with dataset size")
            XCTAssertLessThan(loadTime, Double(count) * 0.005, "Load time should scale sub-linearly with dataset size")

            // Verify data integrity
            XCTAssertEqual(self.userPreferencesService.selectedEquipment.count, count)

            // Clean up for next iteration
            try await self.userPreferencesService.clearAllEquipment()
        }

        // Print performance results
        print("Equipment Dataset Performance Results:")
        for count in equipmentCounts {
            let result = results[count]!
            print(
                "- \(count) items: Save \(String(format: "%.3f", result.save))s, Load \(String(format: "%.3f", result.load))s"
            )
        }
    }

    /// Tests performance with large workout plan datasets
    func testLargeWorkoutPlanDatasetPerformance() async throws {
        let planCounts = [50, 100, 200, 500]
        var results: [Int: (save: Double, load: Double, access: Double)] = [:]

        for count in planCounts {
            // Create large plan dataset
            let plans = self.testDataFactory.createMultipleWorkoutPlans(count: count)

            // Measure bulk save performance
            let saveStartTime = CFAbsoluteTimeGetCurrent()
            for plan in plans {
                try await self.userPreferencesService.savePlan(plan)
            }
            let saveEndTime = CFAbsoluteTimeGetCurrent()
            let saveTime = saveEndTime - saveStartTime

            // Clear cache to ensure fresh load
            await self.userPreferencesService.clearPlanCache()

            // Measure metadata load performance
            let loadStartTime = CFAbsoluteTimeGetCurrent()
            try await userPreferencesService.loadSavedPlans()
            let loadEndTime = CFAbsoluteTimeGetCurrent()
            let loadTime = loadEndTime - loadStartTime

            // Measure individual plan access performance
            let accessStartTime = CFAbsoluteTimeGetCurrent()
            for plan in Array(plans.prefix(10)) {
                _ = try await self.userPreferencesService.loadPlanDetails(plan.id)
            }
            let accessEndTime = CFAbsoluteTimeGetCurrent()
            let accessTime = accessEndTime - accessStartTime

            results[count] = (save: saveTime, load: loadTime, access: accessTime)

            // Performance assertions
            XCTAssertLessThan(saveTime, Double(count) * 0.05, "Save time should scale reasonably with plan count")
            XCTAssertLessThan(loadTime, 2.0, "Metadata load should be fast regardless of plan count")
            XCTAssertLessThan(accessTime, 1.0, "Individual plan access should be fast")

            // Verify data integrity
            XCTAssertEqual(self.userPreferencesService.savedPlans.count, count)

            // Clean up for next iteration
            try await self.userPreferencesService.clearAllPlans()
        }

        // Print performance results
        print("Workout Plan Dataset Performance Results:")
        for count in planCounts {
            let result = results[count]!
            print(
                "- \(count) plans: Save \(String(format: "%.3f", result.save))s, Load \(String(format: "%.3f", result.load))s, Access \(String(format: "%.3f", result.access))s"
            )
        }
    }

    // MARK: - Concurrent Operations Performance Tests

    /// Tests performance under concurrent read operations
    func testConcurrentReadPerformance() async throws {
        // Setup test data
        let equipment = self.testDataFactory.createLargeEquipmentSet(count: 200)
        let plans = self.testDataFactory.createMultipleWorkoutPlans(count: 100)

        try await self.userPreferencesService.saveEquipmentSelection(equipment)
        for plan in plans {
            try await self.userPreferencesService.savePlan(plan)
        }

        let concurrencyLevels = [1, 5, 10, 20]
        var results: [Int: Double] = [:]

        for concurrency in concurrencyLevels {
            // Clear cache to ensure consistent test conditions
            await self.userPreferencesService.clearPlanCache()
            await self.userPreferencesService.clearEquipmentCache()

            let startTime = CFAbsoluteTimeGetCurrent()

            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< concurrency {
                    group.addTask {
                        do {
                            // Perform mixed read operations
                            try await self.userPreferencesService.loadSelectedEquipment()
                            try await self.userPreferencesService.loadSavedPlans()

                            // Access some individual plans
                            let randomPlans = Array(plans.shuffled().prefix(5))
                            for plan in randomPlans {
                                _ = try await self.userPreferencesService.loadPlanDetails(plan.id)
                            }
                        } catch {
                            XCTFail("Concurrent read operation failed: \(error)")
                        }
                    }
                }
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let totalTime = endTime - startTime
            results[concurrency] = totalTime

            // Performance assertions
            XCTAssertLessThan(totalTime, 10.0, "Concurrent reads should complete within 10 seconds")

            print("Concurrency \(concurrency): \(String(format: "%.3f", totalTime))s")
        }

        // Verify that higher concurrency doesn't significantly degrade performance
        let singleThreadTime = results[1]!
        let maxConcurrencyTime = results[concurrencyLevels.max()!]!
        let performanceDegradation = maxConcurrencyTime / singleThreadTime

        XCTAssertLessThan(performanceDegradation, 3.0, "Performance degradation should be reasonable with concurrency")

        print("Concurrent Read Performance Results:")
        for concurrency in concurrencyLevels {
            print("- \(concurrency) threads: \(String(format: "%.3f", results[concurrency]!))s")
        }
    }

    /// Tests performance under concurrent write operations
    func testConcurrentWritePerformance() async throws {
        let concurrencyLevels = [1, 3, 5, 10]
        var results: [Int: Double] = [:]

        for concurrency in concurrencyLevels {
            // Clear data for each test
            try await self.userPreferencesService.clearAllPlans()
            try await self.userPreferencesService.clearAllEquipment()

            let plansPerThread = 20
            let equipmentPerThread = 50

            let startTime = CFAbsoluteTimeGetCurrent()

            await withTaskGroup(of: Void.self) { group in
                for threadIndex in 0 ..< concurrency {
                    group.addTask {
                        do {
                            // Create unique data for each thread
                            let threadPlans = self.testDataFactory.createMultipleWorkoutPlans(
                                count: plansPerThread,
                                namePrefix: "Thread\(threadIndex)"
                            )
                            let threadEquipment = self.testDataFactory.createLargeEquipmentSet(
                                count: equipmentPerThread,
                                prefix: "thread\(threadIndex)"
                            )

                            // Perform write operations
                            for plan in threadPlans {
                                try await self.userPreferencesService.savePlan(plan)
                            }

                            try await self.userPreferencesService.saveEquipmentSelection(threadEquipment)

                            // Perform some updates
                            for plan in Array(threadPlans.prefix(5)) {
                                try await self.userPreferencesService.markPlanAsUsed(plan.id)
                            }
                        } catch {
                            XCTFail("Concurrent write operation failed: \(error)")
                        }
                    }
                }
            }

            let endTime = CFAbsoluteTimeGetCurrent()
            let totalTime = endTime - startTime
            results[concurrency] = totalTime

            // Verify data integrity after concurrent writes
            try await self.userPreferencesService.loadSavedPlans()
            try await self.userPreferencesService.loadSelectedEquipment()

            let expectedPlanCount = concurrency * plansPerThread
            XCTAssertEqual(
                self.userPreferencesService.savedPlans.count,
                expectedPlanCount,
                "All plans should be saved despite concurrent writes"
            )

            // Equipment count might vary due to concurrent updates, but should not be zero
            XCTAssertGreaterThan(
                self.userPreferencesService.selectedEquipment.count,
                0,
                "Equipment should be saved despite concurrent writes"
            )

            print("Concurrency \(concurrency): \(String(format: "%.3f", totalTime))s")
        }

        print("Concurrent Write Performance Results:")
        for concurrency in concurrencyLevels {
            print("- \(concurrency) threads: \(String(format: "%.3f", results[concurrency]!))s")
        }
    }

    // MARK: - Memory Performance Tests

    /// Tests memory usage with large datasets
    func testMemoryUsageWithLargeDatasets() async throws {
        let initialMemory = self.getMemoryUsage()

        // Load large dataset
        let largeEquipmentSet = self.testDataFactory.createLargeEquipmentSet(count: 1_000)
        let largePlanSet = self.testDataFactory.createMultipleWorkoutPlans(count: 500)

        try await self.userPreferencesService.saveEquipmentSelection(largeEquipmentSet)
        for plan in largePlanSet {
            try await self.userPreferencesService.savePlan(plan)
        }

        // Load all data into memory
        try await self.userPreferencesService.loadSelectedEquipment()
        try await self.userPreferencesService.loadSavedPlans()

        // Access many plans to fill cache
        for plan in Array(largePlanSet.prefix(100)) {
            _ = try await self.userPreferencesService.loadPlanDetails(plan.id)
        }

        let peakMemory = self.getMemoryUsage()
        let memoryIncrease = peakMemory - initialMemory

        // Memory increase should be reasonable (less than 100MB for this dataset)
        XCTAssertLessThan(memoryIncrease, 100 * 1_024 * 1_024, "Memory usage should be reasonable")

        // Test memory optimization
        await self.userPreferencesService.optimizeMemoryUsage()

        let optimizedMemory = self.getMemoryUsage()
        let memoryReduction = peakMemory - optimizedMemory

        // Memory optimization should reduce usage
        XCTAssertGreaterThan(memoryReduction, 0, "Memory optimization should reduce memory usage")

        print("Memory Usage Results:")
        print("- Initial: \(self.formatBytes(initialMemory))")
        print("- Peak: \(self.formatBytes(peakMemory))")
        print("- After optimization: \(self.formatBytes(optimizedMemory))")
        print("- Increase: \(self.formatBytes(memoryIncrease))")
        print("- Reduction: \(self.formatBytes(memoryReduction))")
    }

    /// Tests cache performance and memory management
    func testCachePerformanceAndMemoryManagement() async throws {
        // Create test data
        let plans = self.testDataFactory.createMultipleWorkoutPlans(count: 200)
        for plan in plans {
            try await self.userPreferencesService.savePlan(plan)
        }

        // Test cache warming
        let warmupStartTime = CFAbsoluteTimeGetCurrent()
        for plan in Array(plans.prefix(50)) {
            _ = try await self.userPreferencesService.loadPlanDetails(plan.id)
        }
        let warmupEndTime = CFAbsoluteTimeGetCurrent()
        let warmupTime = warmupEndTime - warmupStartTime

        // Test cached access
        let cachedAccessStartTime = CFAbsoluteTimeGetCurrent()
        for plan in Array(plans.prefix(50)) {
            _ = try await self.userPreferencesService.loadPlanDetails(plan.id)
        }
        let cachedAccessEndTime = CFAbsoluteTimeGetCurrent()
        let cachedAccessTime = cachedAccessEndTime - cachedAccessStartTime

        // Cached access should be significantly faster
        let speedup = warmupTime / cachedAccessTime
        XCTAssertGreaterThan(speedup, 2.0, "Cached access should be at least 2x faster")

        // Test cache eviction under memory pressure
        let initialCacheSize = await userPreferencesService.cachedPlansCount
        XCTAssertEqual(initialCacheSize, 50, "Cache should contain 50 plans")

        // Load more plans to trigger cache eviction
        for plan in Array(plans.suffix(100)) {
            _ = try await self.userPreferencesService.loadPlanDetails(plan.id)
        }

        let finalCacheSize = await userPreferencesService.cachedPlansCount
        XCTAssertLessThan(finalCacheSize, 150, "Cache should limit size to prevent memory issues")

        print("Cache Performance Results:")
        print("- Warmup time: \(String(format: "%.3f", warmupTime))s")
        print("- Cached access time: \(String(format: "%.3f", cachedAccessTime))s")
        print("- Speedup: \(String(format: "%.1f", speedup))x")
        print("- Initial cache size: \(initialCacheSize)")
        print("- Final cache size: \(finalCacheSize)")
    }

    // MARK: - Stress Tests

    /// Tests system behavior under extreme load conditions
    func testExtremeLoadConditions() async throws {
        let stressTestDuration: TimeInterval = 30.0 // 30 seconds
        let operationsPerSecond = 10

        // Setup initial data
        let equipment = self.testDataFactory.createLargeEquipmentSet(count: 100)
        let plans = self.testDataFactory.createMultipleWorkoutPlans(count: 50)

        try await self.userPreferencesService.saveEquipmentSelection(equipment)
        for plan in plans {
            try await self.userPreferencesService.savePlan(plan)
        }

        var operationCount = 0
        var errorCount = 0
        let startTime = CFAbsoluteTimeGetCurrent()

        // Run stress test
        while CFAbsoluteTimeGetCurrent() - startTime < stressTestDuration {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0 ..< operationsPerSecond {
                    group.addTask {
                        do {
                            // Perform random operations
                            let operation = Int.random(in: 0 ... 4)
                            switch operation {
                            case 0:
                                try await self.userPreferencesService.loadSelectedEquipment()
                            case 1:
                                try await self.userPreferencesService.loadSavedPlans()
                            case 2:
                                let randomPlan = plans.randomElement()!
                                try await self.userPreferencesService.markPlanAsUsed(randomPlan.id)
                            case 3:
                                let randomPlan = plans.randomElement()!
                                _ = try await self.userPreferencesService.loadPlanDetails(randomPlan.id)
                            case 4:
                                let randomEquipment = equipment.randomElement()!
                                try await self.userPreferencesService.updateEquipmentSelection(
                                    randomEquipment,
                                    isSelected: Bool.random()
                                )
                            default:
                                break
                            }
                            operationCount += 1
                        } catch {
                            errorCount += 1
                        }
                    }
                }
            }

            // Small delay to prevent overwhelming the system
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let actualDuration = endTime - startTime
        let operationsPerSecondActual = Double(operationCount) / actualDuration
        let errorRate = Double(errorCount) / Double(operationCount + errorCount)

        // Performance assertions
        XCTAssertGreaterThan(operationsPerSecondActual, 5.0, "Should maintain reasonable throughput under stress")
        XCTAssertLessThan(errorRate, 0.05, "Error rate should be less than 5% under stress")

        // Verify data integrity after stress test
        try await self.userPreferencesService.loadSelectedEquipment()
        try await self.userPreferencesService.loadSavedPlans()

        XCTAssertEqual(self.userPreferencesService.selectedEquipment.count, equipment.count)
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, plans.count)

        print("Stress Test Results:")
        print("- Duration: \(String(format: "%.1f", actualDuration))s")
        print("- Total operations: \(operationCount)")
        print("- Operations/second: \(String(format: "%.1f", operationsPerSecondActual))")
        print("- Error count: \(errorCount)")
        print("- Error rate: \(String(format: "%.2f", errorRate * 100))%")
    }

    // MARK: - Background Processing Performance Tests

    /// Tests performance of background processing operations
    func testBackgroundProcessingPerformance() async throws {
        let plans = self.testDataFactory.createMultipleWorkoutPlans(count: 100)

        // Test background save performance
        let backgroundSaveStartTime = CFAbsoluteTimeGetCurrent()

        await userPreferencesService.performBackgroundSave {
            for plan in plans {
                try await self.userPreferencesService.savePlan(plan)
            }
        }

        let backgroundSaveEndTime = CFAbsoluteTimeGetCurrent()
        let backgroundSaveTime = backgroundSaveEndTime - backgroundSaveStartTime

        // Background save should return quickly (not wait for completion)
        XCTAssertLessThan(backgroundSaveTime, 1.0, "Background save should return quickly")

        // Wait for background operation to complete
        try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

        // Verify all plans were saved
        try await self.userPreferencesService.loadSavedPlans()
        XCTAssertEqual(self.userPreferencesService.savedPlans.count, plans.count)

        // Test background optimization performance
        let optimizationStartTime = CFAbsoluteTimeGetCurrent()

        await userPreferencesService.performBackgroundOptimization()

        let optimizationEndTime = CFAbsoluteTimeGetCurrent()
        let optimizationTime = optimizationEndTime - optimizationStartTime

        // Background optimization should also return quickly
        XCTAssertLessThan(optimizationTime, 0.5, "Background optimization should return quickly")

        print("Background Processing Performance Results:")
        print("- Background save return time: \(String(format: "%.3f", backgroundSaveTime))s")
        print("- Background optimization return time: \(String(format: "%.3f", optimizationTime))s")
    }

    // MARK: - Helper Methods

    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB, .useBytes]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

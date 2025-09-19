@testable import VoltLift
import XCTest

final class ExecutionValidationTests: XCTestCase {
    func test_weight_stepAndMin() {
        XCTAssertTrue(ExecutionValidation.isValidWeightKg(nil))
        XCTAssertTrue(ExecutionValidation.isValidWeightKg(0))
        XCTAssertTrue(ExecutionValidation.isValidWeightKg(10.5))
        XCTAssertFalse(ExecutionValidation.isValidWeightKg(-0.5))
        XCTAssertFalse(ExecutionValidation.isValidWeightKg(10.3))
    }

    func test_difficulties_rangeAndLength() {
        XCTAssertTrue(ExecutionValidation.isValidDifficulties([1, 10], reps: 2))
        XCTAssertFalse(ExecutionValidation.isValidDifficulties([1], reps: 2))
        XCTAssertFalse(ExecutionValidation.isValidDifficulties([0, 11], reps: 2))
    }
}

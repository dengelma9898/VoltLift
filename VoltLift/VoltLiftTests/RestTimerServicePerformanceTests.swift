@testable import VoltLift
import XCTest

final class RestTimerServicePerformanceTests: XCTestCase {
    func test_timer_ticks_and_completion_under_acceptable_jitter() {
        let sut = RestTimerService()
        let exp = expectation(description: "timer completes")
        var ticks: [Int] = []
        let start = CFAbsoluteTimeGetCurrent()
        sut.start(durationSeconds: 3, onTick: { remaining in
            ticks.append(remaining)
        }, onCompleted: {
            let elapsed = CFAbsoluteTimeGetCurrent() - start
            // 3s +/- 0.7s Tolerance for CI/mac load
            XCTAssertLessThan(abs(elapsed - 3.0), 0.7)
            exp.fulfill()
        })
        wait(for: [exp], timeout: 5.0)
        XCTAssertFalse(ticks.isEmpty)
        XCTAssertTrue(ticks.first == 3)
    }
}

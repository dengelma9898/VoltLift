@testable import VoltLift
import XCTest

final class WorkoutSessionServiceTests: XCTestCase {
    func test_start_createsActiveSession() throws {
        let sut = WorkoutSessionService()
        let planId = UUID()
        let session = try sut.start(planId: planId)
        XCTAssertEqual(session.planId, planId)
        XCTAssertEqual(session.status, .active)
        XCTAssertEqual(session.restDurationSeconds, 120)
    }

    func test_confirmRep_validatesAndStartsRestTimer() throws {
        var session = try WorkoutSessionService().start(planId: UUID())
        var entries: [WorkoutSetEntry] = []
        let exerciseId = UUID()
        XCTAssertNoThrow(try WorkoutSessionService().confirmRep(
            session: &session,
            entries: &entries,
            planExerciseId: exerciseId,
            setIndex: 0,
            repIndex: 0,
            weightKg: nil,
            exerciseUsesEquipment: false,
            difficulties: [1]
        ))
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(session.restTimerRemainingSeconds, 120)
    }
}

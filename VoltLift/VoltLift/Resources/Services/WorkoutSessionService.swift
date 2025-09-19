import Foundation

public enum WorkoutSessionError: Error, Equatable, LocalizedError {
    case notActive
    case sessionAlreadyActive
    case planNotFound
    case invalidValue
    case timerNotRunning
    case noEquipment

    public var errorDescription: String? {
        switch self {
        case .notActive: "Keine aktive Session."
        case .sessionAlreadyActive: "Es läuft bereits eine Session."
        case .planNotFound: "Plan nicht gefunden."
        case .invalidValue: "Ungültiger Wert."
        case .timerNotRunning: "Kein Timer aktiv."
        case .noEquipment: "Übung erfordert kein Equipment – kein Gewicht erfassbar."
        }
    }
}

public protocol WorkoutSessionHandling {
    func start(planId: UUID) throws -> WorkoutSession
    func confirmRep(
        session: inout WorkoutSession,
        entries: inout [WorkoutSetEntry],
        planExerciseId: UUID,
        setIndex: Int,
        repIndex: Int,
        weightKg: Double?,
        exerciseUsesEquipment: Bool,
        difficulties: [Int]
    ) throws
    func restTimerElapsed(session: inout WorkoutSession)
    func autoAdvanceAfterExerciseComplete(session: inout WorkoutSession)
    func cancel(session: inout WorkoutSession)
    func finish(session: inout WorkoutSession)
}

struct WorkoutSessionService: WorkoutSessionHandling {
    private let repository: WorkoutSessionRepository

    init(repository: WorkoutSessionRepository = WorkoutSessionRepository()) {
        self.repository = repository
    }

    func start(planId: UUID) throws -> WorkoutSession {
        // In echter Implementierung: planId prüfen (Repository). Hier nur Domain-Objekt initialisieren.
        let session = WorkoutSession(planId: planId)
        Task { try? await self.repository.createSession(from: session) }
        return session
    }

    func confirmRep(
        session: inout WorkoutSession,
        entries: inout [WorkoutSetEntry],
        planExerciseId: UUID,
        setIndex: Int,
        repIndex: Int,
        weightKg: Double?,
        exerciseUsesEquipment: Bool,
        difficulties: [Int]
    ) throws {
        guard session.status == .active else { throw WorkoutSessionError.notActive }
        guard ExecutionValidation.isValidWeightKg(weightKg) else { throw WorkoutLoggingError.invalidWeight }
        guard ExecutionValidation.isValidDifficulties(difficulties, reps: difficulties.count) else {
            throw WorkoutLoggingError.invalidDifficulties
        }
        if weightKg != nil, !exerciseUsesEquipment {
            throw WorkoutLoggingError.noEquipment
        }

        if let idx = entries.firstIndex(where: { $0.planExerciseId == planExerciseId && $0.setIndex == setIndex }) {
            entries[idx].weightKg = weightKg
            entries[idx].difficulties = difficulties
        } else {
            entries.append(WorkoutSetEntry(
                planExerciseId: planExerciseId,
                setIndex: setIndex,
                weightKg: weightKg,
                difficulties: difficulties
            ))
        }
        session.repIndex = repIndex
        session.restTimerRemainingSeconds = session.restDurationSeconds
        let entryToPersist = entries
            .first(where: { $0.planExerciseId == planExerciseId && $0.setIndex == setIndex }) ??
            WorkoutSetEntry(
                planExerciseId: planExerciseId,
                setIndex: setIndex,
                weightKg: weightKg,
                difficulties: difficulties
            )
        let sessionSnapshot = session
        Task { try? await self.repository.upsertEntry(entryToPersist, sessionId: sessionSnapshot.id) }
        Task { try? await self.repository.updateSession(sessionSnapshot) }
    }

    func restTimerElapsed(session: inout WorkoutSession) {
        session.restTimerRemainingSeconds = 0
        let snapshot = session
        Task { try? await self.repository.updateSession(snapshot) }
    }

    func autoAdvanceAfterExerciseComplete(session: inout WorkoutSession) {
        session.currentExerciseIndex += 1
        session.setIndex = 0
        session.repIndex = 0
        let snapshot = session
        Task { try? await self.repository.updateSession(snapshot) }
    }

    func cancel(session: inout WorkoutSession) {
        session.status = .canceled
        session.finishedAt = Date()
        let snapshot = session
        Task { try? await self.repository.updateSession(snapshot) }
    }

    func finish(session: inout WorkoutSession) {
        session.status = .finished
        session.finishedAt = Date()
        let snapshot = session
        Task { try? await self.repository.updateSession(snapshot) }
    }
}

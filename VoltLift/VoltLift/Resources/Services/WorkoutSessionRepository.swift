import CoreData
import Foundation

public struct WorkoutSessionRepository {
    private let persistence: PersistenceController

    public init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: - Session CRUD

    public func createSession(from session: WorkoutSession) async throws {
        try await self.persistence.performBackgroundTask { context in
            let obj = WorkoutSessionCD(context: context)
            obj.sessionId = session.id
            obj.planId = session.planId
            obj.startedAt = session.startedAt
            obj.finishedAt = session.finishedAt
            obj.status = session.status.rawValue
            obj.currentExerciseIndex = Int32(session.currentExerciseIndex)
            obj.setIndex = Int32(session.setIndex)
            obj.repIndex = Int32(session.repIndex)
            obj.restDurationSeconds = Int32(session.restDurationSeconds)
            obj.restTimerRemainingSeconds = Int32(session.restTimerRemainingSeconds)
            obj.hapticOnTimerEnd = session.hapticOnTimerEnd
        }
    }

    public func updateSession(_ session: WorkoutSession) async throws {
        try await self.persistence.performBackgroundTask { context in
            let request: NSFetchRequest<WorkoutSessionCD> = WorkoutSessionCD.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "sessionId == %@", session.id as CVarArg)
            if let obj = try context.fetch(request).first {
                obj.finishedAt = session.finishedAt
                obj.status = session.status.rawValue
                obj.currentExerciseIndex = Int32(session.currentExerciseIndex)
                obj.setIndex = Int32(session.setIndex)
                obj.repIndex = Int32(session.repIndex)
                obj.restTimerRemainingSeconds = Int32(session.restTimerRemainingSeconds)
                obj.hapticOnTimerEnd = session.hapticOnTimerEnd
            }
        }
    }

    // MARK: - Entries

    public func upsertEntry(_ entry: WorkoutSetEntry, sessionId: UUID) async throws {
        try await self.persistence.performBackgroundTask { context in
            let request: NSFetchRequest<WorkoutSetEntryCD> = WorkoutSetEntryCD.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(
                format: "entryId == %@",
                entry.id as CVarArg
            )
            let obj = try context.fetch(request).first ?? WorkoutSetEntryCD(context: context)
            obj.entryId = entry.id
            obj.sessionId = sessionId
            obj.planExerciseId = entry.planExerciseId
            obj.setIndex = Int32(entry.setIndex)
            obj.repIndex = Int32(entry.difficulties.count)
            obj.weightKg = entry.weightKg as NSNumber?
            obj.timestamp = entry.timestamp
            obj.difficultiesData = try JSONEncoder().encode(entry.difficulties)
        }
    }

    // MARK: - Plan Changes

    public func recordPlanChange(_ change: PlanChangeDuringSession) async throws {
        try await self.persistence.performBackgroundTask { context in
            let obj = PlanChangeDuringSessionCD(context: context)
            obj.changeId = change.id
            obj.sessionId = change.sessionId
            obj.operation = change.operation.rawValue
            obj.payload = change.payload
        }
    }
}

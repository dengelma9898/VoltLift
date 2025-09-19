import CoreData
import Foundation

struct WorkoutSessionRepository {
    private let persistence: PersistenceController

    init(persistence: PersistenceController? = nil) {
        self.persistence = persistence ?? .shared
    }

    // MARK: - Session CRUD

    func createSession(from session: WorkoutSession) async throws {
        // Copy only Sendable primitives to avoid @Sendable capture errors
        let sid = session.id
        let pid = session.planId
        let startedAt = session.startedAt
        let finishedAt = session.finishedAt
        let status = session.status.rawValue
        let currentExerciseIndex = Int32(session.currentExerciseIndex)
        let setIndex = Int32(session.setIndex)
        let repIndex = Int32(session.repIndex)
        let restDurationSeconds = Int32(session.restDurationSeconds)
        let restTimerRemainingSeconds = Int32(session.restTimerRemainingSeconds)
        let hapticOnTimerEnd = session.hapticOnTimerEnd

        try await self.persistence.performBackgroundTask { context in
            let obj = WorkoutSessionCD(context: context)
            obj.sessionId = sid
            obj.planId = pid
            obj.startedAt = startedAt
            obj.finishedAt = finishedAt
            obj.status = status
            obj.currentExerciseIndex = currentExerciseIndex
            obj.setIndex = setIndex
            obj.repIndex = repIndex
            obj.restDurationSeconds = restDurationSeconds
            obj.restTimerRemainingSeconds = restTimerRemainingSeconds
            obj.hapticOnTimerEnd = hapticOnTimerEnd
        }
    }

    func updateSession(_ session: WorkoutSession) async throws {
        let sid = session.id
        let finishedAt = session.finishedAt
        let status = session.status.rawValue
        let currentExerciseIndex = Int32(session.currentExerciseIndex)
        let setIndex = Int32(session.setIndex)
        let repIndex = Int32(session.repIndex)
        let restTimerRemainingSeconds = Int32(session.restTimerRemainingSeconds)
        let hapticOnTimerEnd = session.hapticOnTimerEnd

        try await self.persistence.performBackgroundTask { context in
            let request: NSFetchRequest<WorkoutSessionCD> = WorkoutSessionCD.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "sessionId == %@", sid as CVarArg)
            if let obj = try context.fetch(request).first {
                obj.finishedAt = finishedAt
                obj.status = status
                obj.currentExerciseIndex = currentExerciseIndex
                obj.setIndex = setIndex
                obj.repIndex = repIndex
                obj.restTimerRemainingSeconds = restTimerRemainingSeconds
                obj.hapticOnTimerEnd = hapticOnTimerEnd
            }
        }
    }

    // MARK: - Entries

    func upsertEntry(_ entry: WorkoutSetEntry, sessionId: UUID) async throws {
        let entryId = entry.id
        let planExerciseId = entry.planExerciseId
        let setIndex = Int32(entry.setIndex)
        let repIndex = Int32(entry.difficulties.count)
        let weightKg = entry.weightKg
        let timestamp = entry.timestamp
        let difficulties = entry.difficulties

        try await self.persistence.performBackgroundTask { context in
            let request: NSFetchRequest<WorkoutSetEntryCD> = WorkoutSetEntryCD.fetchRequest()
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "entryId == %@", entryId as CVarArg)
            let obj = try context.fetch(request).first ?? WorkoutSetEntryCD(context: context)
            obj.entryId = entryId
            obj.sessionId = sessionId
            obj.planExerciseId = planExerciseId
            obj.setIndex = setIndex
            obj.repIndex = repIndex
            // Use KVC to allow optional nil for numeric Core Data attribute
            obj.setValue(weightKg, forKey: "weightKg")
            obj.timestamp = timestamp
            obj.difficultiesData = try JSONEncoder().encode(difficulties)
        }
    }

    // MARK: - Plan Changes

    func recordPlanChange(_ change: PlanChangeDuringSession) async throws {
        let changeId = change.id
        let sessionId = change.sessionId
        let operation = change.operation.rawValue
        let payload = change.payload

        try await self.persistence.performBackgroundTask { context in
            let obj = PlanChangeDuringSessionCD(context: context)
            obj.changeId = changeId
            obj.sessionId = sessionId
            obj.operation = operation
            obj.payload = payload
        }
    }
}

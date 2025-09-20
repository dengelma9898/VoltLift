import CoreData
import Foundation

protocol WorkoutHistoryReading {
    func summaries(forPlanId planId: UUID, includeCanceled: Bool, limit: Int?) async throws -> [WorkoutSessionSummary]
}

protocol WorkoutHistoryWriting {
    static func buildSummary(for session: WorkoutSession, entries: [WorkoutSetEntry]) -> WorkoutSessionSummary
}

struct WorkoutHistoryService: WorkoutHistoryReading, WorkoutHistoryWriting {
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    static func buildSummary(for session: WorkoutSession, entries: [WorkoutSetEntry]) -> WorkoutSessionSummary {
        let perExercise = Dictionary(grouping: entries, by: { $0.planExerciseId })
            .map { key, value -> WorkoutSessionSummary.ExerciseAggregate in
                let setsCount = value.count
                let repsCount = value.reduce(0) { $0 + $1.difficulties.count }
                let volume = value.reduce(0.0) { total, entry in
                    total + ((entry.weightKg ?? 0.0) * Double(entry.difficulties.count))
                }
                return .init(id: key, setsCount: setsCount, repsCount: repsCount, volumeKg: volume)
            }

        let totalSets = entries.count
        let totalReps = entries.reduce(0) { $0 + $1.difficulties.count }
        let totalVolume = entries
            .reduce(0.0) { acc, entry in acc + ((entry.weightKg ?? 0.0) * Double(entry.difficulties.count)) }

        return WorkoutSessionSummary(
            id: session.id,
            planId: session.planId,
            startedAt: session.startedAt,
            finishedAt: session.finishedAt,
            status: session.status,
            totalSets: totalSets,
            totalReps: totalReps,
            totalVolumeKg: totalVolume,
            perExercise: perExercise.sorted { $0.id.uuidString < $1.id.uuidString }
        )
    }

    func summaries(
        forPlanId planId: UUID,
        includeCanceled: Bool = false,
        limit: Int? = nil
    ) async throws -> [WorkoutSessionSummary] {
        try await self.persistence.performBackgroundTask { context in
            let req: NSFetchRequest<WorkoutSessionCD> = WorkoutSessionCD.fetchRequest()
            if includeCanceled {
                req.predicate = NSPredicate(
                    format: "planId == %@ AND (status == %@ OR status == %@)",
                    planId as CVarArg,
                    WorkoutSessionStatus.finished.rawValue,
                    WorkoutSessionStatus.canceled.rawValue
                )
            } else {
                req.predicate = NSPredicate(
                    format: "planId == %@ AND status == %@",
                    planId as CVarArg,
                    WorkoutSessionStatus.finished.rawValue
                )
            }
            req.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSessionCD.finishedAt, ascending: false)]
            if let limit { req.fetchLimit = limit }

            let sessions = try context.fetch(req)

            // Fetch entries per session and map
            var result: [WorkoutSessionSummary] = []
            result.reserveCapacity(sessions.count)

            for s in sessions {
                let entriesReq: NSFetchRequest<WorkoutSetEntryCD> = WorkoutSetEntryCD.fetchRequest()
                guard let sessionId = s.sessionId else { continue }
                entriesReq.predicate = NSPredicate(format: "sessionId == %@", sessionId as CVarArg)
                let cdEntries = try context.fetch(entriesReq)
                let decoded: [WorkoutSetEntry] = try cdEntries.map { entryCD in
                    let difficulties = try JSONDecoder().decode([Int].self, from: entryCD.difficultiesData ?? Data())
                    return WorkoutSetEntry(
                        id: entryCD.entryId ?? UUID(),
                        planExerciseId: entryCD.planExerciseId ?? UUID(),
                        setIndex: Int(entryCD.setIndex),
                        weightKg: entryCD.value(forKey: "weightKg") as? Double,
                        difficulties: difficulties,
                        timestamp: entryCD.timestamp ?? Date()
                    )
                }

                let status = WorkoutSessionStatus(rawValue: s.status ?? "active") ?? .active
                let sessionModel = WorkoutSession(
                    id: s.sessionId ?? UUID(),
                    planId: s.planId ?? UUID(),
                    startedAt: s.startedAt ?? Date(),
                    finishedAt: s.finishedAt,
                    status: status,
                    currentExerciseIndex: Int(s.currentExerciseIndex),
                    setIndex: Int(s.setIndex),
                    repIndex: Int(s.repIndex),
                    restDurationSeconds: Int(s.restDurationSeconds),
                    restTimerRemainingSeconds: Int(s.restTimerRemainingSeconds),
                    hapticOnTimerEnd: s.hapticOnTimerEnd
                )

                result.append(WorkoutHistoryService.buildSummary(for: sessionModel, entries: decoded))
            }

            return result
        }
    }

    func insights(forPlanId planId: UUID, limit: Int? = nil) async throws -> PlanInsights {
        try await self.persistence.performBackgroundTask { context in
            let req: NSFetchRequest<WorkoutSessionCD> = WorkoutSessionCD.fetchRequest()
            req.predicate = NSPredicate(
                format: "planId == %@ AND status == %@",
                planId as CVarArg,
                WorkoutSessionStatus.finished.rawValue
            )
            req.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutSessionCD.finishedAt, ascending: false)]

            let sessions = try context.fetch(req)

            var allEntries: [WorkoutSetEntry] = []
            var summaries: [WorkoutSessionSummary] = []
            summaries.reserveCapacity(sessions.count)

            for s in sessions {
                let entriesReq: NSFetchRequest<WorkoutSetEntryCD> = WorkoutSetEntryCD.fetchRequest()
                guard let sessionId = s.sessionId else { continue }
                entriesReq.predicate = NSPredicate(format: "sessionId == %@", sessionId as CVarArg)
                let cdEntries = try context.fetch(entriesReq)
                let decoded: [WorkoutSetEntry] = try cdEntries.map { entryCD in
                    let difficulties = try JSONDecoder().decode([Int].self, from: entryCD.difficultiesData ?? Data())
                    return WorkoutSetEntry(
                        id: entryCD.entryId ?? UUID(),
                        planExerciseId: entryCD.planExerciseId ?? UUID(),
                        setIndex: Int(entryCD.setIndex),
                        weightKg: entryCD.value(forKey: "weightKg") as? Double,
                        difficulties: difficulties,
                        timestamp: entryCD.timestamp ?? Date()
                    )
                }
                allEntries.append(contentsOf: decoded)

                let status = WorkoutSessionStatus(rawValue: s.status ?? "active") ?? .active
                let sessionModel = WorkoutSession(
                    id: s.sessionId ?? UUID(),
                    planId: s.planId ?? UUID(),
                    startedAt: s.startedAt ?? Date(),
                    finishedAt: s.finishedAt,
                    status: status,
                    currentExerciseIndex: Int(s.currentExerciseIndex),
                    setIndex: Int(s.setIndex),
                    repIndex: Int(s.repIndex),
                    restDurationSeconds: Int(s.restDurationSeconds),
                    restTimerRemainingSeconds: Int(s.restTimerRemainingSeconds),
                    hapticOnTimerEnd: s.hapticOnTimerEnd
                )
                summaries.append(WorkoutHistoryService.buildSummary(for: sessionModel, entries: decoded))
            }

            // Aggregate metrics
            let sessionCount = summaries.count
            let totalVolume = summaries.reduce(0.0) { $0 + $1.totalVolumeKg }
            let avgVolumePerSession = sessionCount > 0 ? totalVolume / Double(sessionCount) : 0.0
            let totalSets = summaries.reduce(0) { $0 + $1.totalSets }
            let totalReps = summaries.reduce(0) { $0 + $1.totalReps }
            let avgRepsPerSet = totalSets > 0 ? Double(totalReps) / Double(totalSets) : 0.0

            // Average difficulty across all reps
            let allDifficulties: [Int] = allEntries.flatMap(\.difficulties)
            let avgDifficulty: Double? = allDifficulties
                .isEmpty ? nil : Double(allDifficulties.reduce(0, +)) / Double(allDifficulties.count)

            // Trend calculations: compare last 3 vs previous 3 sessions
            func avg(_ values: [some BinaryFloatingPoint]) -> Double? {
                guard !values.isEmpty else { return nil }
                let sum = values.reduce(0, +)
                return Double(sum) / Double(values.count)
            }

            let recent = Array(summaries.prefix(3))
            let prior = Array(summaries.dropFirst(3).prefix(3))

            // Volume trend
            let volRecent = avg(recent.map(\.totalVolumeKg))
            let volPrior = avg(prior.map(\.totalVolumeKg))
            let volumeTrendDelta: Double? = {
                if let recentAverage = volRecent, let priorAverage = volPrior { return recentAverage - priorAverage }
                return nil
            }()

            // Reps trend (avg reps per set per session)
            let repsPerSetRecent = avg(recent
                .compactMap { $0.totalSets > 0 ? Double($0.totalReps) / Double($0.totalSets) : nil }
            )
            let repsPerSetPrior = avg(prior
                .compactMap { $0.totalSets > 0 ? Double($0.totalReps) / Double($0.totalSets) : nil }
            )
            let repsTrendDelta: Double? = {
                if let recentAverage = repsPerSetRecent,
                   let priorAverage = repsPerSetPrior { return recentAverage - priorAverage }
                return nil
            }()

            // Weight trend: average weight per session (non-nil weights)
            func sessionAvgWeight(_ entries: [WorkoutSetEntry]) -> Double? {
                let weights = entries.compactMap(\.weightKg)
                guard !weights.isEmpty else { return nil }
                return weights.reduce(0.0, +) / Double(weights.count)
            }

            var avgWeightsPerSession: [UUID: Double] = [:]
            // build a map sessionId -> avgWeight using earlier loop data
            for s in sessions {
                let entriesReq: NSFetchRequest<WorkoutSetEntryCD> = WorkoutSetEntryCD.fetchRequest()
                guard let sessionId = s.sessionId else { continue }
                entriesReq.predicate = NSPredicate(format: "sessionId == %@", sessionId as CVarArg)
                let cdEntries = try context.fetch(entriesReq)
                let decoded: [WorkoutSetEntry] = try cdEntries.map { entryCD in
                    let difficulties = try JSONDecoder().decode([Int].self, from: entryCD.difficultiesData ?? Data())
                    return WorkoutSetEntry(
                        id: entryCD.entryId ?? UUID(),
                        planExerciseId: entryCD.planExerciseId ?? UUID(),
                        setIndex: Int(entryCD.setIndex),
                        weightKg: entryCD.value(forKey: "weightKg") as? Double,
                        difficulties: difficulties,
                        timestamp: entryCD.timestamp ?? Date()
                    )
                }
                if let avgWeight = sessionAvgWeight(decoded) {
                    avgWeightsPerSession[sessionId] = avgWeight
                }
            }

            let recentWeights = recent.compactMap { avgWeightsPerSession[$0.id] }
            let priorWeights = prior.compactMap { avgWeightsPerSession[$0.id] }
            let weightTrendDelta: Double? = {
                let recentAverageWeight = avg(recentWeights)
                let priorAverageWeight = avg(priorWeights)
                if let recentAverageWeight, let priorAverageWeight { return recentAverageWeight - priorAverageWeight }
                return nil
            }()

            return PlanInsights(
                sessionCount: sessionCount,
                totalVolumeKg: totalVolume,
                avgVolumePerSession: avgVolumePerSession,
                avgRepsPerSet: avgRepsPerSet,
                avgDifficulty: avgDifficulty,
                volumeTrendDelta: volumeTrendDelta,
                repsTrendDelta: repsTrendDelta,
                weightTrendDelta: weightTrendDelta,
                recentSummaries: Array(summaries.prefix(limit ?? 10))
            )
        }
    }
}

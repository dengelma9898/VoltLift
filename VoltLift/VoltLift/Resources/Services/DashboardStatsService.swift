import CoreData
import Foundation

struct DashboardStats: Sendable, Equatable {
    let workouts: Int
    let activities: Int
    let weekStreak: Int
}

/// Aggregiert Kennzahlen für die Home-Statistik.
struct DashboardStatsService {
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    func load() async throws -> DashboardStats {
        try await self.persistence.performBackgroundTask { context in
            // Workouts: alle beendeten Sessions
            var workoutCountRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "WorkoutSessionCD")
            workoutCountRequest.resultType = .countResultType
            workoutCountRequest.predicate = NSPredicate(
                format: "status == %@",
                WorkoutSessionStatus.finished.rawValue
            )
            let workoutCount = try context.count(for: workoutCountRequest)

            // Outdoor Activities: alle Aktivitäten
            var activityCountRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "OutdoorActivityCD")
            activityCountRequest.resultType = .countResultType
            let activityCount = try context.count(for: activityCountRequest)

            // Week streak: auf Basis von Wochen mit mindestens 1 Workout ODER 1 Outdoor-Aktivität
            let calendar = Calendar.current

            // Sammle Abschlussdaten
            let finishedWorkouts: [Date] = try context
                .fetch(NSFetchRequest<NSManagedObject>(entityName: "WorkoutSessionCD"))
                .compactMap { $0.value(forKey: "finishedAt") as? Date }
            let finishedActivities: [Date] = try context
                .fetch(NSFetchRequest<NSManagedObject>(entityName: "OutdoorActivityCD"))
                .compactMap { $0.value(forKey: "finishedAt") as? Date }

            var completedWeeks: Set<String> = []
            for finishedDate in finishedWorkouts + finishedActivities {
                let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: finishedDate)
                if let week = components.weekOfYear, let year = components.yearForWeekOfYear {
                    completedWeeks.insert("\(year)-\(week)")
                }
            }

            // Zähle rückwärts ab aktuelle Woche
            var streak = 0
            var currentDate = Date()
            while true {
                let components = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: currentDate)
                guard let week = components.weekOfYear, let year = components.yearForWeekOfYear else { break }
                let key = "\(year)-\(week)"
                if completedWeeks.contains(key) {
                    streak += 1
                    if let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentDate) {
                        currentDate = previousWeek
                    } else {
                        break
                    }
                } else {
                    break
                }
            }

            return DashboardStats(
                workouts: max(workoutCount, 0),
                activities: max(activityCount, 0),
                weekStreak: streak
            )
        }
    }
}

import Foundation

@MainActor
final class WorkoutLoggingViewModel: ObservableObject {
    @Published private(set) var entries: [WorkoutSetEntry]
    @Published var lastError: String?

    private let service: WorkoutLoggingService

    init(entries: [WorkoutSetEntry] = [], service: WorkoutLoggingService = WorkoutLoggingService()) {
        self.entries = entries
        self.service = service
    }

    func recordWeight(planExerciseId: UUID, setIndex: Int, weightKg: Double, exerciseUsesEquipment: Bool) {
        do {
            self.entries = try self.service.recordSetWeight(
                entries: self.entries,
                planExerciseId: planExerciseId,
                setIndex: setIndex,
                weightKg: weightKg,
                exerciseUsesEquipment: exerciseUsesEquipment
            )
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func recordDifficulties(planExerciseId: UUID, setIndex: Int, difficulties: [Int], reps: Int) {
        do {
            self.entries = try self.service.recordPerRepDifficulty(
                entries: self.entries,
                planExerciseId: planExerciseId,
                setIndex: setIndex,
                difficulties: difficulties,
                reps: reps
            )
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }
}

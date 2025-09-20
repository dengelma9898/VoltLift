import Foundation

@MainActor
final class PlanEditorViewModel: ObservableObject {
    @Published private(set) var plan: PlanDraft
    @Published var lastError: String?

    private let service: PlanEditorService

    init(plan: PlanDraft, service: PlanEditorService = PlanEditorService()) {
        self.plan = plan
        self.service = service
    }

    func addSet(to exerciseId: UUID, newSet: PlanSetDraft, at index: Int? = nil) {
        do {
            self.plan = try self.service.addSet(to: self.plan, exerciseId: exerciseId, newSet: newSet, at: index)
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func removeSet(from exerciseId: UUID, at index: Int) {
        do {
            self.plan = try self.service.removeSet(from: self.plan, exerciseId: exerciseId, at: index)
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func moveSet(in exerciseId: UUID, from sourceIndex: Int, to destinationIndex: Int) {
        do {
            self.plan = try self.service.moveSet(
                in: self.plan,
                exerciseId: exerciseId,
                from: sourceIndex,
                to: destinationIndex
            )
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func editSetAttributes(
        exerciseId: UUID,
        setIndex: Int,
        reps: Int,
        setType: ExerciseSetType,
        side: ExecutionSide,
        comment: String?
    ) {
        do {
            self.plan = try self.service.editSetAttributes(
                in: self.plan,
                exerciseId: exerciseId,
                setIndex: setIndex,
                reps: reps,
                setType: setType,
                side: side,
                comment: comment
            )
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func savePlan() {
        do {
            self.plan = try self.service.savePlan(self.plan)
            self.lastError = nil
            // Persistenz folgt in separater Task (T027)
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func addExercise(from exercise: Exercise) {
        do {
            self.plan = try self.service.addExercise(to: self.plan, from: exercise)
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    func removeExercise(exerciseId: UUID) {
        do {
            self.plan = try self.service.removeExercise(from: self.plan, exerciseId: exerciseId)
            self.lastError = nil
        } catch {
            self.lastError = error.localizedDescription
        }
    }
}

import Foundation

@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    @Published private(set) var session: WorkoutSession
    @Published private(set) var entries: [WorkoutSetEntry] = []
    @Published var lastError: String?
    @Published var timerRemainingSeconds: Int = 0

    private let sessionService: WorkoutSessionHandling
    private let timerService: RestTimerHandling
    private let haptics: HapticsSignaling

    init(
        planId: UUID,
        sessionService: WorkoutSessionHandling = WorkoutSessionService(),
        timerService: RestTimerHandling = RestTimerService(),
        haptics: HapticsSignaling = HapticsService()
    ) {
        self.sessionService = sessionService
        self.timerService = timerService
        self.haptics = haptics
        // Startet eine neue Session für den Plan
        // In echter App: Fehlerbehandlung bei ungültigem PlanId
        self.session = (try? sessionService.start(planId: planId)) ?? WorkoutSession(planId: planId)
    }

    func confirmRep(
        planExerciseId: UUID,
        setIndex: Int,
        repIndex: Int,
        weightKg: Double?,
        exerciseUsesEquipment: Bool,
        difficulties: [Int]
    ) {
        do {
            try self.sessionService.confirmRep(
                session: &self.session,
                entries: &self.entries,
                planExerciseId: planExerciseId,
                setIndex: setIndex,
                repIndex: repIndex,
                weightKg: weightKg,
                exerciseUsesEquipment: exerciseUsesEquipment,
                difficulties: difficulties
            )
            self.lastError = nil
            self.startRestTimer()
        } catch {
            self.lastError = error.localizedDescription
        }
    }

    private func startRestTimer() {
        let duration = self.session.restDurationSeconds
        self.timerService.start(durationSeconds: duration, onTick: { [weak self] remaining in
            Task { @MainActor in self?.timerRemainingSeconds = remaining }
        }, onCompleted: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.sessionService.restTimerElapsed(session: &self.session)
                self.haptics.signalTimerEnd()
                self.timerRemainingSeconds = 0
            }
        })
    }

    func cancel() {
        self.sessionService.cancel(session: &self.session)
        self.timerService.cancel()
    }

    func finish() {
        self.sessionService.finish(session: &self.session)
        self.timerService.cancel()
    }
}

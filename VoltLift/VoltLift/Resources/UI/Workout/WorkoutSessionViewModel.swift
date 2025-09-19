import Foundation

@MainActor
final class WorkoutSessionViewModel: ObservableObject {
    @Published private(set) var session: WorkoutSession
    @Published private(set) var entries: [WorkoutSetEntry] = []
    @Published var lastError: String?
    @Published var timerRemainingSeconds: Int = 0
    @Published private(set) var timerEndDate: Date?

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

    func autoAdvanceToNextExercise() {
        self.sessionService.autoAdvanceAfterExerciseComplete(session: &self.session)
    }

    private func startRestTimer() {
        let duration = self.session.restDurationSeconds
        // Setze Enddatum einmalig; UI nutzt TimelineView für lokale Aktualisierung
        self.timerEndDate = Date().addingTimeInterval(TimeInterval(duration))
        self.timerRemainingSeconds = duration
        self.timerService.start(durationSeconds: duration, onTick: { _ in
            // keine Sekundenticks mehr ins UI publizieren
        }, onCompleted: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.sessionService.restTimerElapsed(session: &self.session)
                self.haptics.signalTimerEnd()
                self.timerRemainingSeconds = 0
                self.timerEndDate = nil
            }
        })
    }

    func cancel() {
        self.sessionService.cancel(session: &self.session)
        self.timerService.cancel()
        self.timerEndDate = nil
    }

    func finish() {
        self.sessionService.finish(session: &self.session)
        self.timerService.cancel()
        self.timerEndDate = nil
    }
}

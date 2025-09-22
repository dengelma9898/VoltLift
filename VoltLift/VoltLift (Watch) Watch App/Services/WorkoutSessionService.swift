import Combine
import Foundation
import HealthKit

protocol WatchWorkoutSessionServiceProtocol: AnyObject {
    func requestAuthorization() async throws
    func start(activity: HKWorkoutActivityType) throws
    func pause()
    func resume()
    func stop()
}

final class WatchWorkoutSessionService: NSObject, ObservableObject, WatchWorkoutSessionServiceProtocol {
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var isPaused: Bool = false

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    func requestAuthorization() async throws {
        let typesToShare: Set<HKSampleType> = [HKObjectType.workoutType()]
        let readCandidates: [HKObjectType?] = [
            HKObjectType.quantityType(forIdentifier: .heartRate),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        ]
        let typesToRead = Set(readCandidates.compactMap(\.self))
        try await self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
    }

    func start(activity: HKWorkoutActivityType) throws {
        let config = HKWorkoutConfiguration()
        config.activityType = activity

        let newSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        let newBuilder = newSession.associatedWorkoutBuilder()
        newBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: self.healthStore, workoutConfiguration: config)

        newSession.delegate = self
        newBuilder.delegate = self

        let startDate = Date()
        newSession.startActivity(with: startDate)
        newBuilder.beginCollection(withStart: startDate) { _, _ in }

        self.session = newSession
        self.builder = newBuilder
        self.isRunning = true
        self.isPaused = false
    }

    func pause() {
        self.session?.pause()
        self.isPaused = true
    }

    func resume() {
        self.session?.resume()
        self.isPaused = false
    }

    func stop() {
        self.session?.end()
        self.builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.builder?.finishWorkout(completion: { _, _ in })
        }
        self.isRunning = false
        self.isPaused = false
    }
}

extension WatchWorkoutSessionService: HKWorkoutSessionDelegate {
    func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        switch toState {
        case .running:
            self.isRunning = true
            self.isPaused = false
        case .paused:
            self.isPaused = true
        case .ended:
            self.isRunning = false
            self.isPaused = false
        default:
            break
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // TODO: Error handling/logging if needed
    }
}

extension WatchWorkoutSessionService: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {}
}

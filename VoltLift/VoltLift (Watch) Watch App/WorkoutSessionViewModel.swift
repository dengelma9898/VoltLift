import Combine
import Foundation
import SwiftUI
import WatchKit

@MainActor
final class MockWorkoutSessionViewModel: ObservableObject {
    struct Entry: Identifiable {
        let id: UUID
        let name: String
        let defaultReps: Int
        let defaultWeightKg: Double
    }

    enum Difficulty: Int, CaseIterable, Identifiable {
        case d1 = 1, d2, d3, d4, d5, d6, d7, d8, d9, d10
        var id: Int { self.rawValue }
        var label: String { String(self.rawValue) }
    }

    // Input
    let planName: String
    let entries: [Entry]

    // Progress
    @Published private(set) var currentIndex: Int = 0
    @Published var reps: Int = 8
    @Published var weightKg: Double = 40
    @Published var difficulty: Difficulty = .d5

    // Rest state
    @Published private(set) var isResting: Bool = false
    @Published private(set) var restRemainingSeconds: Int = 0

    private var restTimer: Timer?

    init(planName: String, exercises: [StrengthExercise]) {
        self.planName = planName
        self.entries = exercises.map { exercise in
            let first = exercise.sets.first
            let reps = first?.reps ?? 8
            let weight = first?.weightKg ?? 40
            return Entry(id: exercise.id, name: exercise.name, defaultReps: reps, defaultWeightKg: weight)
        }
        if let first = entries.first {
            self.reps = first.defaultReps
            self.weightKg = first.defaultWeightKg
        }
    }

    var isFinished: Bool { self.currentIndex >= self.entries.count }
    var currentName: String { self.isFinished ? "" : self.entries[self.currentIndex].name }

    func confirmCurrent() {
        // Mock: hier würden wir die Ergebnisse persistieren
        self.startRestTimer()
    }

    func cancelWorkout() {
        self.stopTimer()
    }

    private func startRestTimer() {
        self.isResting = true
        self.restRemainingSeconds = 120
        self.stopTimer()
        self.restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                if self.restRemainingSeconds > 0 {
                    self.restRemainingSeconds -= 1
                }
                if self.restRemainingSeconds == 0 {
                    self.restTimer?.invalidate()
                    self.restTimer = nil
                    WKInterfaceDevice.current().play(.notification)
                    self.advanceToNextExercise()
                }
            }
        }
    }

    func skipRest() {
        self.advanceToNextExercise()
    }

    private func advanceToNextExercise() {
        self.isResting = false
        self.currentIndex += 1
        if !self.isFinished {
            let currentEntry = self.entries[self.currentIndex]
            self.reps = currentEntry.defaultReps
            self.weightKg = currentEntry.defaultWeightKg
            self.difficulty = .d5
        } else {
            self.stopTimer()
        }
    }

    private func stopTimer() {
        self.restTimer?.invalidate()
        self.restTimer = nil
    }
}

//
//  WorkoutExecutionView.swift
//  VoltLift
//
//  Created by Kiro on 15.9.2025.
//

import SwiftUI

/// View for executing a workout plan with real-time tracking and plan usage updates
struct WorkoutExecutionView: View {
    let workoutPlan: WorkoutPlanData
    let onWorkoutComplete: () -> Void

    @EnvironmentObject private var userPreferencesService: UserPreferencesService
    @Environment(\.dismiss) private var dismiss

    @State private var currentExerciseIndex = 0
    @State private var currentSet = 1
    @State private var isWorkoutActive = false
    @State private var workoutStartTime: Date?
    @State private var completedSets: Set<String> = []
    @State private var showingCompleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showingError = false

    private var currentExercise: ExerciseData? {
        guard self.currentExerciseIndex < self.workoutPlan.exercises.count else { return nil }
        return self.workoutPlan.exercises[self.currentExerciseIndex]
    }

    private var isWorkoutComplete: Bool {
        self.completedSets.count >= self.totalSetsCount
    }

    private var totalSetsCount: Int {
        self.workoutPlan.exercises.reduce(0) { $0 + $1.totalSets }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.l) {
                if let exercise = currentExercise {
                    self.workoutHeader
                    self.currentExerciseView(exercise)
                    self.exerciseControls
                    self.progressSection
                } else {
                    self.workoutCompleteView
                }
            }
            .padding(DesignSystem.Spacing.l)
            .vlBrandBackground()
            .navigationTitle(self.workoutPlan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End") {
                        self.showingCompleteConfirmation = true
                    }
                    .foregroundColor(DesignSystem.ColorRole.danger)
                }
            }
            .onAppear {
                self.startWorkout()
            }
            .alert("End Workout", isPresented: self.$showingCompleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("End Workout", role: .destructive) {
                    self.completeWorkout()
                }
            } message: {
                Text("Are you sure you want to end this workout? Your progress will be saved.")
            }
            .alert("Error", isPresented: self.$showingError) {
                Button("OK") {
                    self.errorMessage = nil
                }
            } message: {
                if let errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Subviews

    private var workoutHeader: some View {
        VLGlassCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercise \(self.currentExerciseIndex + 1) of \(self.workoutPlan.exercises.count)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)

                    if let startTime = workoutStartTime {
                        Text("Duration: \(self.formatDuration(Date().timeIntervalSince(startTime)))")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Set \(self.currentSet) of \(self.currentExercise?.totalSets ?? 0)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)

                    Text("\(self.completedSets.count)/\(self.totalSetsCount) sets")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.primary)
                }
            }
        }
    }

    private func currentExerciseView(_ exercise: ExerciseData) -> some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text(exercise.name)
                    .font(DesignSystem.Typography.titleM)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                HStack(spacing: DesignSystem.Spacing.xl) {
                    self.exerciseDetail(icon: "repeat", title: "Reps", value: "\(exercise.averageReps)")
                    self.exerciseDetail(icon: "scalemass", title: "Weight", value: "\(Int(exercise.averageWeight)) lbs")
                    self.exerciseDetail(icon: "timer", title: "Rest", value: "\(exercise.restTime)s")
                }
            }
        }
    }

    private func exerciseDetail(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.ColorRole.primary)

            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)

            Text(value)
                .font(DesignSystem.Typography.body.weight(.semibold))
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }

    private var exerciseControls: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Button("Previous") {
                self.previousSet()
            }
            .buttonStyle(VLSecondaryButtonStyle())
            .disabled(self.currentExerciseIndex == 0 && self.currentSet == 1)

            Button("Complete Set") {
                self.completeCurrentSet()
            }
            .buttonStyle(VLPrimaryButtonStyle())

            Button("Next") {
                self.nextSet()
            }
            .buttonStyle(VLSecondaryButtonStyle())
            .disabled(self.isWorkoutComplete)
        }
    }

    private var progressSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Workout Progress")
                    .font(DesignSystem.Typography.titleS)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                ProgressView(value: Double(self.completedSets.count), total: Double(self.totalSetsCount))
                    .tint(DesignSystem.ColorRole.primary)

                Text("\(self.completedSets.count) of \(self.totalSetsCount) sets completed")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
            }
        }
    }

    private var workoutCompleteView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.ColorRole.success)

            VStack(spacing: DesignSystem.Spacing.s) {
                Text("Workout Complete!")
                    .font(DesignSystem.Typography.titleL)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                if let startTime = workoutStartTime {
                    Text("Duration: \(self.formatDuration(Date().timeIntervalSince(startTime)))")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
            }

            Button("Finish") {
                self.completeWorkout()
            }
            .buttonStyle(VLPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func startWorkout() {
        self.isWorkoutActive = true
        self.workoutStartTime = Date()

        // Mark plan as used when workout starts
        Task {
            do {
                try await self.userPreferencesService.markPlanAsUsed(self.workoutPlan.id)
            } catch {
                self.handleError(error, operation: "marking plan as used")
            }
        }
    }

    private func completeCurrentSet() {
        guard let exercise = currentExercise else { return }

        let setId = "\(exercise.id)-\(self.currentSet)"
        self.completedSets.insert(setId)

        // Move to next set or exercise
        if self.currentSet < exercise.totalSets {
            self.currentSet += 1
        } else {
            self.nextExercise()
        }
    }

    private func nextSet() {
        guard let exercise = currentExercise else { return }

        if self.currentSet < exercise.totalSets {
            self.currentSet += 1
        } else {
            self.nextExercise()
        }
    }

    private func previousSet() {
        if self.currentSet > 1 {
            self.currentSet -= 1
        } else if self.currentExerciseIndex > 0 {
            self.currentExerciseIndex -= 1
            self.currentSet = self.workoutPlan.exercises[self.currentExerciseIndex].totalSets
        }
    }

    private func nextExercise() {
        if self.currentExerciseIndex < self.workoutPlan.exercises.count - 1 {
            self.currentExerciseIndex += 1
            self.currentSet = 1
        }
    }

    private func completeWorkout() {
        self.isWorkoutActive = false
        self.onWorkoutComplete()
        self.dismiss()
    }

    private func handleError(_ error: Error, operation: String) {
        if let preferencesError = error as? UserPreferencesError {
            self.errorMessage = preferencesError.localizedDescription
        } else {
            self.errorMessage = "An error occurred while \(operation). Please try again."
        }
        self.showingError = true
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    let samplePlan = WorkoutPlanData(
        name: "Upper Body Strength",
        exercises: [
            ExerciseData(name: "Push-ups", sets: 3, reps: 12, weight: 0, restTime: 60, orderIndex: 0),
            ExerciseData(name: "Pull-ups", sets: 3, reps: 8, weight: 0, restTime: 90, orderIndex: 1),
            ExerciseData(name: "Dumbbell Press", sets: 4, reps: 10, weight: 25, restTime: 120, orderIndex: 2)
        ]
    )

    WorkoutExecutionView(workoutPlan: samplePlan) {
        print("Workout completed")
    }
    .environmentObject(UserPreferencesService())
    .preferredColorScheme(.dark)
}

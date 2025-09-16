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
        guard currentExerciseIndex < workoutPlan.exercises.count else { return nil }
        return workoutPlan.exercises[currentExerciseIndex]
    }
    
    private var isWorkoutComplete: Bool {
        completedSets.count >= totalSetsCount
    }
    
    private var totalSetsCount: Int {
        workoutPlan.exercises.reduce(0) { $0 + $1.totalSets }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.l) {
                if let exercise = currentExercise {
                    workoutHeader
                    currentExerciseView(exercise)
                    exerciseControls
                    progressSection
                } else {
                    workoutCompleteView
                }
            }
            .padding(DesignSystem.Spacing.l)
            .vlBrandBackground()
            .navigationTitle(workoutPlan.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("End") {
                        showingCompleteConfirmation = true
                    }
                    .foregroundColor(DesignSystem.ColorRole.danger)
                }
            }
            .onAppear {
                startWorkout()
            }
            .alert("End Workout", isPresented: $showingCompleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("End Workout", role: .destructive) {
                    completeWorkout()
                }
            } message: {
                Text("Are you sure you want to end this workout? Your progress will be saved.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
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
                    Text("Exercise \(currentExerciseIndex + 1) of \(workoutPlan.exercises.count)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    
                    if let startTime = workoutStartTime {
                        Text("Duration: \(formatDuration(Date().timeIntervalSince(startTime)))")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Set \(currentSet) of \(currentExercise?.totalSets ?? 0)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    
                    Text("\(completedSets.count)/\(totalSetsCount) sets")
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
                    exerciseDetail(icon: "repeat", title: "Reps", value: "\(exercise.averageReps)")
                    exerciseDetail(icon: "scalemass", title: "Weight", value: "\(Int(exercise.averageWeight)) lbs")
                    exerciseDetail(icon: "timer", title: "Rest", value: "\(exercise.restTime)s")
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
                previousSet()
            }
            .buttonStyle(VLSecondaryButtonStyle())
            .disabled(currentExerciseIndex == 0 && currentSet == 1)
            
            Button("Complete Set") {
                completeCurrentSet()
            }
            .buttonStyle(VLPrimaryButtonStyle())
            
            Button("Next") {
                nextSet()
            }
            .buttonStyle(VLSecondaryButtonStyle())
            .disabled(isWorkoutComplete)
        }
    }
    
    private var progressSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("Workout Progress")
                    .font(DesignSystem.Typography.titleS)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                
                ProgressView(value: Double(completedSets.count), total: Double(totalSetsCount))
                    .tint(DesignSystem.ColorRole.primary)
                
                Text("\(completedSets.count) of \(totalSetsCount) sets completed")
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
                    Text("Duration: \(formatDuration(Date().timeIntervalSince(startTime)))")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
            }
            
            Button("Finish") {
                completeWorkout()
            }
            .buttonStyle(VLPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func startWorkout() {
        isWorkoutActive = true
        workoutStartTime = Date()
        
        // Mark plan as used when workout starts
        Task {
            do {
                try await userPreferencesService.markPlanAsUsed(workoutPlan.id)
            } catch {
                handleError(error, operation: "marking plan as used")
            }
        }
    }
    
    private func completeCurrentSet() {
        guard let exercise = currentExercise else { return }
        
        let setId = "\(exercise.id)-\(currentSet)"
        completedSets.insert(setId)
        
        // Move to next set or exercise
        if currentSet < exercise.totalSets {
            currentSet += 1
        } else {
            nextExercise()
        }
    }
    
    private func nextSet() {
        guard let exercise = currentExercise else { return }
        
        if currentSet < exercise.totalSets {
            currentSet += 1
        } else {
            nextExercise()
        }
    }
    
    private func previousSet() {
        if currentSet > 1 {
            currentSet -= 1
        } else if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            currentSet = workoutPlan.exercises[currentExerciseIndex].totalSets
        }
    }
    
    private func nextExercise() {
        if currentExerciseIndex < workoutPlan.exercises.count - 1 {
            currentExerciseIndex += 1
            currentSet = 1
        }
    }
    
    private func completeWorkout() {
        isWorkoutActive = false
        onWorkoutComplete()
        dismiss()
    }
    
    private func handleError(_ error: Error, operation: String) {
        if let preferencesError = error as? UserPreferencesError {
            errorMessage = preferencesError.localizedDescription
        } else {
            errorMessage = "An error occurred while \(operation). Please try again."
        }
        showingError = true
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
//
//  SavedPlansView.swift
//  VoltLift
//
//  Created by Kiro on 15.9.2025.
//

import SwiftUI

/// View for displaying and managing saved workout plans
/// Provides plan selection, rename, and delete functionality with metadata display
struct SavedPlansView: View {
    @StateObject private var userPreferencesService = UserPreferencesService()
    @State private var showingRenameAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedPlan: WorkoutPlanData?
    @State private var selectedPlanForWorkout: WorkoutPlanData?
    @State private var newPlanName = ""
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingWorkoutExecution = false
    @State private var editingPlanDraft: PlanDraft?

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.l) {
                if self.userPreferencesService.savedPlans.isEmpty, !self.userPreferencesService.isLoading {
                    self.emptyStateView
                } else {
                    self.plansList
                }
            }
            .padding(DesignSystem.Spacing.l)
            .background(DesignSystem.ColorRole.background)
            .navigationTitle("Saved Plans")
            .navigationBarTitleDisplayMode(.large)
            .withErrorHandling(self.userPreferencesService)
            .task {
                await self.loadPlans()
            }
            .alert("Rename Plan", isPresented: self.$showingRenameAlert) {
                TextField("Plan name", text: self.$newPlanName)
                Button("Cancel", role: .cancel) {
                    self.resetAlertState()
                }
                Button("Rename") {
                    Task {
                        await self.renamePlan()
                    }
                }
            } message: {
                Text("Enter a new name for your workout plan")
            }
            .alert("Delete Plan", isPresented: self.$showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    self.resetAlertState()
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await self.deletePlan()
                    }
                }
            } message: {
                if let plan = selectedPlan {
                    Text("Are you sure you want to delete '\(plan.name)'? This action cannot be undone.")
                }
            }

            .fullScreenCover(isPresented: self.$showingWorkoutExecution) {
                if let selectedPlanForWorkout {
                    WorkoutExecutionView(workoutPlan: selectedPlanForWorkout) {
                        // Workout completed - refresh plans to update last used date
                        Task {
                            await self.loadPlans()
                        }
                    }
                    .environmentObject(self.userPreferencesService)
                }
            }
            .navigationDestination(item: self.$editingPlanDraft) { draft in
                PlanEditorView(plan: draft)
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.ColorRole.textSecondary)

            VStack(spacing: DesignSystem.Spacing.s) {
                Text("No Saved Plans")
                    .font(DesignSystem.Typography.titleM)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                Text("Your workout plans will appear here once you create them")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var plansList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.m) {
                ForEach(self.userPreferencesService.savedPlans) { plan in
                    self.planRow(plan)
                }
            }
        }
    }

    private func planRow(_ plan: WorkoutPlanData) -> some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                // Plan header with name and menu
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(DesignSystem.Typography.titleS)
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)

                        Text("\(plan.exerciseCount) exercise\(plan.exerciseCount == 1 ? "" : "s")")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }

                    Spacer()

                    Menu {
                        Button {
                            self.selectPlan(plan)
                        } label: {
                            Label("Use Plan", systemImage: "play.fill")
                        }

                        Button {
                            self.editPlan(plan)
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button {
                            self.showRenameAlert(for: plan)
                        } label: {
                            Label("Rename", systemImage: "square.and.pencil")
                        }

                        Button(role: .destructive) {
                            self.showDeleteConfirmation(for: plan)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            .padding(DesignSystem.Spacing.s)
                    }
                    .accessibilityLabel("Plan options for \(plan.name)")
                }

                // Plan metadata
                HStack(spacing: DesignSystem.Spacing.l) {
                    self.metadataItem(
                        icon: "calendar",
                        title: "Created",
                        value: self.formatDate(plan.createdDate)
                    )

                    if let lastUsed = plan.lastUsedDate {
                        self.metadataItem(
                            icon: "clock",
                            title: "Last Used",
                            value: self.formatDate(lastUsed)
                        )
                    }
                }
            }
        }
        .onTapGesture {
            self.selectPlan(plan)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Workout plan \(plan.name)")
        .accessibilityHint("Double tap to use this plan, or use the menu for more options")
    }

    private func metadataItem(icon: String, title: String, value: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                .frame(width: 12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)

                Text(value)
                    .font(DesignSystem.Typography.caption.weight(.medium))
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
            }
        }
    }

    // MARK: - Actions

    private func loadPlans() async {
        do {
            try await self.userPreferencesService.loadSavedPlans()
        } catch {
            self.handleError(error, operation: "loading plans")
        }
    }

    private func selectPlan(_ plan: WorkoutPlanData) {
        // Navigate to workout execution - the WorkoutExecutionView will handle marking the plan as used
        self.selectedPlanForWorkout = plan
        self.showingWorkoutExecution = true
    }

    private func editPlan(_ plan: WorkoutPlanData) {
        // Map WorkoutPlanData to PlanDraft (read-only transform)
        let draft = PlanDraft(
            id: plan.id,
            name: plan.name,
            exercises: plan.exercises.map { ex in
                PlanExerciseDraft(
                    id: ex.id,
                    referenceExerciseId: ex.id.uuidString,
                    displayName: ex.name,
                    allowsUnilateral: false, // kann später mit ExerciseService.allowsUnilateral angereichert werden
                    sets: ex.sets.map { s in
                        PlanSetDraft(
                            id: s.id,
                            reps: s.reps,
                            setType: s.setType == .warmUp ? .warmUp : (s.setType == .coolDown ? .coolDown : .normal),
                            side: .both,
                            comment: nil
                        )
                    }
                )
            }
        )
        self.editingPlanDraft = draft
    }

    private func showRenameAlert(for plan: WorkoutPlanData) {
        self.selectedPlan = plan
        self.newPlanName = plan.name
        self.showingRenameAlert = true
    }

    private func showDeleteConfirmation(for plan: WorkoutPlanData) {
        self.selectedPlan = plan
        self.showingDeleteConfirmation = true
    }

    private func renamePlan() async {
        guard let plan = selectedPlan, !newPlanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.resetAlertState()
            return
        }

        do {
            try await self.userPreferencesService.renamePlan(
                plan.id,
                newName: self.newPlanName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            self.resetAlertState()
        } catch {
            self.resetAlertState()
            self.handleError(error, operation: "renaming plan")
        }
    }

    private func deletePlan() async {
        guard let plan = selectedPlan else {
            self.resetAlertState()
            return
        }

        do {
            try await self.userPreferencesService.deletePlan(plan.id)
            self.resetAlertState()
        } catch {
            self.resetAlertState()
            self.handleError(error, operation: "deleting plan")
        }
    }

    private func resetAlertState() {
        self.selectedPlan = nil
        self.newPlanName = ""
    }

    private func handleError(_ error: Error, operation: String) {
        // Error handling is now managed by the UserPreferencesService
        // The withErrorHandling modifier will display errors automatically
        print("Error in SavedPlansView: \(error.localizedDescription)")
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    SavedPlansView()
        .preferredColorScheme(.dark)
}

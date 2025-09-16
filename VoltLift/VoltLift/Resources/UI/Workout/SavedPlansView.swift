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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.l) {
                if userPreferencesService.savedPlans.isEmpty && !userPreferencesService.isLoading {
                    emptyStateView
                } else {
                    plansList
                }
            }
            .padding(DesignSystem.Spacing.l)
            .background(DesignSystem.ColorRole.background)
            .navigationTitle("Saved Plans")
            .navigationBarTitleDisplayMode(.large)
            .withErrorHandling(userPreferencesService)
            .task {
                await loadPlans()
            }
            .alert("Rename Plan", isPresented: $showingRenameAlert) {
                TextField("Plan name", text: $newPlanName)
                Button("Cancel", role: .cancel) {
                    resetAlertState()
                }
                Button("Rename") {
                    Task {
                        await renamePlan()
                    }
                }
            } message: {
                Text("Enter a new name for your workout plan")
            }
            .alert("Delete Plan", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    resetAlertState()
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await deletePlan()
                    }
                }
            } message: {
                if let plan = selectedPlan {
                    Text("Are you sure you want to delete '\(plan.name)'? This action cannot be undone.")
                }
            }

            .fullScreenCover(isPresented: $showingWorkoutExecution) {
                if let selectedPlanForWorkout = selectedPlanForWorkout {
                    WorkoutExecutionView(workoutPlan: selectedPlanForWorkout) {
                        // Workout completed - refresh plans to update last used date
                        Task {
                            await loadPlans()
                        }
                    }
                    .environmentObject(userPreferencesService)
                }
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
                ForEach(userPreferencesService.savedPlans) { plan in
                    planRow(plan)
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
                            selectPlan(plan)
                        } label: {
                            Label("Use Plan", systemImage: "play.fill")
                        }
                        
                        Button {
                            showRenameAlert(for: plan)
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            showDeleteConfirmation(for: plan)
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
                    metadataItem(
                        icon: "calendar",
                        title: "Created",
                        value: formatDate(plan.createdDate)
                    )
                    
                    if let lastUsed = plan.lastUsedDate {
                        metadataItem(
                            icon: "clock",
                            title: "Last Used",
                            value: formatDate(lastUsed)
                        )
                    }
                }
            }
        }
        .onTapGesture {
            selectPlan(plan)
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
            try await userPreferencesService.loadSavedPlans()
        } catch {
            handleError(error, operation: "loading plans")
        }
    }
    
    private func selectPlan(_ plan: WorkoutPlanData) {
        // Navigate to workout execution - the WorkoutExecutionView will handle marking the plan as used
        selectedPlanForWorkout = plan
        showingWorkoutExecution = true
    }
    
    private func showRenameAlert(for plan: WorkoutPlanData) {
        selectedPlan = plan
        newPlanName = plan.name
        showingRenameAlert = true
    }
    
    private func showDeleteConfirmation(for plan: WorkoutPlanData) {
        selectedPlan = plan
        showingDeleteConfirmation = true
    }
    
    private func renamePlan() async {
        guard let plan = selectedPlan, !newPlanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            resetAlertState()
            return
        }
        
        do {
            try await userPreferencesService.renamePlan(plan.id, newName: newPlanName.trimmingCharacters(in: .whitespacesAndNewlines))
            resetAlertState()
        } catch {
            resetAlertState()
            handleError(error, operation: "renaming plan")
        }
    }
    
    private func deletePlan() async {
        guard let plan = selectedPlan else {
            resetAlertState()
            return
        }
        
        do {
            try await userPreferencesService.deletePlan(plan.id)
            resetAlertState()
        } catch {
            resetAlertState()
            handleError(error, operation: "deleting plan")
        }
    }
    
    private func resetAlertState() {
        selectedPlan = nil
        newPlanName = ""
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
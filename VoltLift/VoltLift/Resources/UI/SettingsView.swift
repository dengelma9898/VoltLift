//
//  SettingsView.swift
//  VoltLift
//
//  Created by Kiro on 15.9.2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var userPreferencesService = UserPreferencesService()
    @State private var showingResetConfirmation = false
    @State private var showingDataValidationAlert = false
    @State private var showingEquipmentManagement = false
    @State private var validationResults: DataValidationResults?
    @State private var isPerformingValidation = false
    @State private var isResettingPreferences = false
    
    var body: some View {
        NavigationStack {
            List {
                equipmentManagementSection
                dataManagementSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await loadData()
            }
            .task {
                await loadData()
            }
            .alert("Reset All Preferences", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    Task {
                        await resetAllPreferences()
                    }
                }
            } message: {
                Text("This will permanently delete all your equipment selections and saved workout plans. This action cannot be undone.")
            }
            .alert("Data Validation Results", isPresented: $showingDataValidationAlert) {
                Button("OK") { }
            } message: {
                if let results = validationResults {
                    Text(results.summary)
                }
            }
            .sheet(isPresented: $showingEquipmentManagement) {
                EquipmentManagementView(userPreferencesService: userPreferencesService)
            }
        }
    }
    
    // MARK: - View Sections
    
    private var equipmentManagementSection: some View {
        Section("Equipment Management") {
            Button {
                showingEquipmentManagement = true
            } label: {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(DesignSystem.ColorRole.primary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manage Equipment")
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                        
                        Text("\(userPreferencesService.selectedEquipment.filter(\.isSelected).count) items selected")
                            .font(.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var dataManagementSection: some View {
        Section("Data Management") {
            Button {
                Task {
                    await validateDataIntegrity()
                }
            } label: {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(DesignSystem.ColorRole.success)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Validate Data Integrity")
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                        
                        Text("Check for data corruption or inconsistencies")
                            .font(.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                    
                    Spacer()
                    
                    if isPerformingValidation {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isPerformingValidation)
            
            Button {
                showingResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(DesignSystem.ColorRole.danger)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset All Preferences")
                            .foregroundColor(DesignSystem.ColorRole.danger)
                        
                        Text("Delete all equipment and workout plan data")
                            .font(.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                    
                    Spacer()
                    
                    if isResettingPreferences {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isResettingPreferences)
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(DesignSystem.ColorRole.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Data Storage")
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    
                    Text("All data is stored locally on your device and never shared")
                        .font(.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "externaldrive.fill")
                    .foregroundColor(DesignSystem.ColorRole.primary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved Plans")
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    
                    Text("\(userPreferencesService.savedPlans.count) workout plans saved")
                        .font(.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadData() async {
        do {
            async let equipmentLoad: Void = userPreferencesService.loadSelectedEquipment()
            async let plansLoad: Void = userPreferencesService.loadSavedPlans()
            
            _ = try await (equipmentLoad, plansLoad)
        } catch {
            // Error handling is managed by the service's published properties
            print("Failed to load settings data: \(error)")
        }
    }
    
    private func validateDataIntegrity() async {
        isPerformingValidation = true
        defer { isPerformingValidation = false }
        
        do {
            let results = try await performDataValidation()
            validationResults = results
            showingDataValidationAlert = true
        } catch {
            validationResults = DataValidationResults(
                isValid: false,
                equipmentIssues: ["Failed to validate equipment data"],
                planIssues: ["Failed to validate plan data"],
                summary: "Validation failed: \(error.localizedDescription)"
            )
            showingDataValidationAlert = true
        }
    }
    
    private func performDataValidation() async throws -> DataValidationResults {
        // Load fresh data for validation
        try await userPreferencesService.loadSelectedEquipment()
        try await userPreferencesService.loadSavedPlans()
        
        var equipmentIssues: [String] = []
        var planIssues: [String] = []
        
        // Validate equipment data
        for equipment in userPreferencesService.selectedEquipment {
            if equipment.id.isEmpty {
                equipmentIssues.append("Equipment with empty ID found")
            }
            if equipment.name.isEmpty {
                equipmentIssues.append("Equipment '\(equipment.id)' has empty name")
            }
            if equipment.category.isEmpty {
                equipmentIssues.append("Equipment '\(equipment.name)' has empty category")
            }
        }
        
        // Validate plan data
        for plan in userPreferencesService.savedPlans {
            if plan.name.isEmpty {
                planIssues.append("Plan with empty name found")
            }
            if plan.exercises.isEmpty {
                planIssues.append("Plan '\(plan.name)' has no exercises")
            }
            if plan.exerciseCount != plan.exercises.count {
                planIssues.append("Plan '\(plan.name)' has mismatched exercise count")
            }
            
            // Validate individual exercises
            for (index, exercise) in plan.exercises.enumerated() {
                if exercise.name.isEmpty {
                    planIssues.append("Exercise \(index + 1) in plan '\(plan.name)' has empty name")
                }
                if exercise.totalSets <= 0 {
                    planIssues.append("Exercise '\(exercise.name)' has invalid sets count")
                }
                if exercise.averageReps <= 0 {
                    planIssues.append("Exercise '\(exercise.name)' has invalid reps count")
                }
                if exercise.averageWeight < 0 {
                    planIssues.append("Exercise '\(exercise.name)' has negative weight")
                }
                if exercise.restTime < 0 {
                    planIssues.append("Exercise '\(exercise.name)' has negative rest time")
                }
            }
        }
        
        let isValid = equipmentIssues.isEmpty && planIssues.isEmpty
        let summary = isValid 
            ? "All data is valid and consistent ✓"
            : "Found \(equipmentIssues.count + planIssues.count) issues that need attention"
        
        return DataValidationResults(
            isValid: isValid,
            equipmentIssues: equipmentIssues,
            planIssues: planIssues,
            summary: summary
        )
    }
    
    private func resetAllPreferences() async {
        isResettingPreferences = true
        defer { isResettingPreferences = false }
        
        do {
            // Delete all saved plans
            for plan in userPreferencesService.savedPlans {
                try await userPreferencesService.deletePlan(plan.id)
            }
            
            // Reset equipment selection
            let unselectedEquipment = userPreferencesService.selectedEquipment.map { equipment in
                EquipmentItem(
                    id: equipment.id,
                    name: equipment.name,
                    category: equipment.category,
                    isSelected: false
                )
            }
            try await userPreferencesService.saveEquipmentSelection(unselectedEquipment)
            
            // Reload data to reflect changes
            await loadData()
            
        } catch {
            print("Failed to reset preferences: \(error)")
        }
    }
}

// MARK: - Data Validation Results

struct DataValidationResults {
    let isValid: Bool
    let equipmentIssues: [String]
    let planIssues: [String]
    let summary: String
}

// MARK: - Preview

#Preview {
    SettingsView()
}
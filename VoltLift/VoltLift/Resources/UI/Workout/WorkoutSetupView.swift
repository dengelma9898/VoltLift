import SwiftUI

struct WorkoutSetupView: View {
    struct Equipment: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let icon: String
    }

    enum MuscleGroup: String, CaseIterable, Identifiable {
        case chest = "Chest"
        case back = "Back"
        case shoulders = "Shoulders"
        case arms = "Arms"
        case legs = "Legs"
        case core = "Core"
        case fullBody = "Full Body"

        var id: String { rawValue }
    }

    struct Exercise: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let muscleGroup: MuscleGroup
        let requiredEquipment: Set<String>
    }

    struct Plan: Identifiable, Hashable {
        let id = UUID()
        let name: String
        var exercises: [Exercise]
    }

    @EnvironmentObject private var userPreferencesService: UserPreferencesService
    @State private var selectedEquipment: [Equipment] = []
    @State private var plans: [Plan] = []
    @State private var isLoadingPreferences = false
    @State private var preferencesError: UserPreferencesError?
    @State private var selectedPlanForWorkout: WorkoutPlanData?
    @State private var showingWorkoutExecution = false
    
    // Computed property to get current selected equipment from service
    private var currentSelectedEquipment: [Equipment] {
        return userPreferencesService.selectedEquipment.compactMap { item in
            guard item.isSelected else { return nil }
            return Equipment(name: item.name, icon: getIconForEquipment(item.name))
        }
    }
    
    // Use service state for UI decisions
    private var hasSelectedEquipment: Bool {
        return !currentSelectedEquipment.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                self.header

                // Show loading state
                if isLoadingPreferences {
                    VLGlassCard {
                        HStack(spacing: DesignSystem.Spacing.m) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading your preferences...")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(DesignSystem.Spacing.m)
                    }
                }

                // Show error state if needed
                if let error = preferencesError {
                    VLGlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(DesignSystem.ColorRole.warning)
                                Text("Preferences Error")
                                    .font(DesignSystem.Typography.titleS)
                                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                            }
                            Text(error.localizedDescription)
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            
                            Button("Retry") {
                                Task {
                                    await loadUserPreferences()
                                }
                            }
                            .buttonStyle(VLSecondaryButtonStyle())
                        }
                    }
                }

                if false && !hasSelectedEquipment && !isLoadingPreferences { // Temporarily disable equipment requirement
                    VLGlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                            Text("Add your equipment")
                                .font(DesignSystem.Typography.titleS)
                                .foregroundColor(DesignSystem.ColorRole.textPrimary)
                            Text("Personalize your workouts by selecting the equipment you have.")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)

                            NavigationLink {
                                EquipmentSetupView(initialSelection: Set(currentSelectedEquipment
                                        .map(\.name)
                                )) { equipment in
                                    Task { @MainActor in
                                        self.selectedEquipment = equipment
                                        await saveEquipmentSelection(equipment)
                                    }
                                }
                            } label: {
                                VLButtonLabel("Add Equipment", style: .primary)
                            }
                        }
                    }
                }

                if self.plans.isEmpty && !isLoadingPreferences { // Allow plan creation without equipment for testing
                    VLGlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                            Text("Create your first plan")
                                .font(DesignSystem.Typography.titleS)
                                .foregroundColor(DesignSystem.ColorRole.textPrimary)
                            Text("We'll generate balanced sessions based on your goals.")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)

                            NavigationLink {
                                PlanCreationView(selectedEquipmentNames: Set(currentSelectedEquipment
                                        .map(\.name)
                                )) { newPlans in
                                    self.plans = newPlans
                                    // Save plans immediately to UserPreferencesService
                                    Task {
                                        await savePlans(newPlans)
                                        // Refresh saved plans to show the newly created plan
                                        try? await userPreferencesService.loadSavedPlans()
                                        // Clear local plans since they're now saved
                                        await MainActor.run {
                                            self.plans = []
                                        }
                                    }
                                }
                            } label: {
                                VLButtonLabel("Add Plan", style: .secondary)
                            }
                        }
                    }
                }

                if !self.plans.isEmpty {
                    self.plansSection
                }
                
                // Saved Plans Section
                if !userPreferencesService.savedPlans.isEmpty {
                    self.savedPlansSection
                }

                if true { // Always show equipment section for testing
                    self.equipmentSection
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.large)
        .vlBrandBackground()
        .task {
            await loadUserPreferences()
        }
        .fullScreenCover(isPresented: $showingWorkoutExecution) {
            if let selectedPlan = selectedPlanForWorkout {
                WorkoutExecutionView(workoutPlan: selectedPlan) {
                    // Workout completed - refresh plans to update last used date
                    Task {
                        await loadUserPreferences()
                    }
                }
                .environmentObject(userPreferencesService)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Get ready")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
            Text("Your Workout Setup")
                .font(DesignSystem.Typography.titleM)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
        }
    }

    private var plansSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                Text("New Plans")
                    .font(DesignSystem.Typography.titleS)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                ForEach(self.plans) { plan in
                    Button {
                        startWorkoutWithNewPlan(plan)
                    } label: {
                        VLListRow(plan.name, subtitle: "\(plan.exercises.count) exercises") {
                            Image(systemName: "list.bullet.rectangle")
                                .foregroundColor(DesignSystem.ColorRole.primary)
                        } trailing: {
                            Image(systemName: "play.fill")
                                .foregroundColor(DesignSystem.ColorRole.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if plan.id != self.plans.last?.id {
                        Divider().opacity(0.2)
                    }
                }
            }
        }
    }
    
    private var savedPlansSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                HStack {
                    Text("Saved Plans")
                        .font(DesignSystem.Typography.titleS)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    
                    Spacer()
                    
                    NavigationLink {
                        SavedPlansView()
                    } label: {
                        Text("View All")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.primary)
                    }
                }

                ForEach(Array(userPreferencesService.savedPlans.prefix(3))) { plan in
                    Button {
                        startWorkoutWithSavedPlan(plan)
                    } label: {
                        VLListRow(plan.name, subtitle: "\(plan.exerciseCount) exercises") {
                            Image(systemName: "bookmark.fill")
                                .foregroundColor(DesignSystem.ColorRole.secondary)
                        } trailing: {
                            VStack(alignment: .trailing, spacing: 2) {
                                Image(systemName: "play.fill")
                                    .foregroundColor(DesignSystem.ColorRole.primary)
                                
                                if let lastUsed = plan.lastUsedDate {
                                    Text(formatRelativeDate(lastUsed))
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if plan.id != userPreferencesService.savedPlans.prefix(3).last?.id {
                        Divider().opacity(0.2)
                    }
                }
            }
        }
    }

    private var equipmentSection: some View {
        NavigationLink {
            EquipmentSetupView(initialSelection: Set(currentSelectedEquipment.map(\.name))) { equipment in
                Task { @MainActor in
                    self.selectedEquipment = equipment
                    await saveEquipmentSelection(equipment)
                }
            }
        } label: {
            VLGlassCard {
                HStack(spacing: DesignSystem.Spacing.m) {
                    Text("Equipment")
                        .font(DesignSystem.Typography.titleS)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Spacer()
                    Text("\(currentSelectedEquipment.count)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    Image(systemName: "pencil.circle")
                        .foregroundColor(DesignSystem.ColorRole.primary)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Private Methods
    
    /// Loads user preferences from UserPreferencesService
    private func loadUserPreferences() async {
        isLoadingPreferences = true
        preferencesError = nil
        
        do {
            // Load equipment preferences
            try await userPreferencesService.loadSelectedEquipment()
            
            // Convert EquipmentItem to local Equipment struct
            selectedEquipment = userPreferencesService.selectedEquipment.compactMap { item in
                guard item.isSelected else { return nil }
                return Equipment(name: item.name, icon: getIconForEquipment(item.name))
            }
            
            // Load saved plans
            try await userPreferencesService.loadSavedPlans()
            
            // Convert WorkoutPlanData to local Plan struct
            plans = userPreferencesService.savedPlans.map { planData in
                let exercises = planData.exercises.map { exerciseData in
                    Exercise(
                        name: exerciseData.name,
                        muscleGroup: MuscleGroup(rawValue: "Chest") ?? .chest, // Default for now
                        requiredEquipment: Set<String>() // Default for now
                    )
                }
                return Plan(name: planData.name, exercises: exercises)
            }
            
        } catch {
            preferencesError = error as? UserPreferencesError ?? 
                UserPreferencesError.loadFailure(underlying: error.localizedDescription)
        }
        
        isLoadingPreferences = false
    }
    
    /// Saves equipment selection to UserPreferencesService
    private func saveEquipmentSelection(_ equipment: [Equipment]) async {
        // Convert local Equipment to EquipmentItem
        let equipmentItems = availableEquipment.map { available in
            EquipmentItem(
                id: available.name,
                name: available.name,
                category: getCategoryForEquipment(available.name),
                isSelected: equipment.contains { $0.name == available.name }
            )
        }
        
        do {
            try await userPreferencesService.saveEquipmentSelection(equipmentItems)
        } catch {
            preferencesError = error as? UserPreferencesError ?? 
                UserPreferencesError.saveFailure(underlying: error.localizedDescription)
        }
    }
    
    /// Saves workout plans to UserPreferencesService
    private func savePlans(_ plans: [Plan]) async {
        for plan in plans {
            let exerciseData = plan.exercises.enumerated().map { index, exercise in
                ExerciseData(
                    name: exercise.name,
                    sets: 3, // Default values
                    reps: 10,
                    weight: 0.0,
                    restTime: 60,
                    orderIndex: index
                )
            }
            
            let planData = WorkoutPlanData(
                name: plan.name,
                exercises: exerciseData
            )
            
            do {
                try await userPreferencesService.savePlan(planData)
            } catch {
                preferencesError = error as? UserPreferencesError ?? 
                    UserPreferencesError.saveFailure(underlying: error.localizedDescription)
            }
        }
    }
    
    /// Starts a workout with a newly created plan (automatically saves it first)
    private func startWorkoutWithNewPlan(_ plan: Plan) {
        Task {
            // Convert Plan to WorkoutPlanData
            let exerciseData = plan.exercises.enumerated().map { index, exercise in
                ExerciseData(
                    name: exercise.name,
                    sets: 3, // Default values - could be made configurable
                    reps: 10,
                    weight: 0.0,
                    restTime: 60,
                    orderIndex: index
                )
            }
            
            let planData = WorkoutPlanData(
                name: plan.name,
                exercises: exerciseData
            )
            
            do {
                // Save the plan first
                try await userPreferencesService.savePlan(planData)
                
                // Start the workout
                await MainActor.run {
                    selectedPlanForWorkout = planData
                    showingWorkoutExecution = true
                }
            } catch {
                preferencesError = error as? UserPreferencesError ?? 
                    UserPreferencesError.saveFailure(underlying: error.localizedDescription)
            }
        }
    }
    
    /// Starts a workout with a saved plan
    private func startWorkoutWithSavedPlan(_ plan: WorkoutPlanData) {
        selectedPlanForWorkout = plan
        showingWorkoutExecution = true
    }
    
    /// Formats a relative date string (e.g., "2 days ago")
    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    /// Gets icon name for equipment
    private func getIconForEquipment(_ name: String) -> String {
        switch name {
        case "Dumbbells": return "dumbbell"
        case "Resistance Bands": return "bolt.horizontal.circle"
        case "Kettlebell": return "circle"
        case "Barbell": return "dumbbell"
        case "Weight Plates": return "circlebadge"
        case "Pull-up Bar": return "figure.climbing"
        case "Adjustable Bench": return "rectangle.portrait"
        case "Yoga Mat": return "rectangle"
        case "Jump Rope": return "figure.walk"
        case "Foam Roller": return "capsule"
        default: return "questionmark.circle"
        }
    }
    
    /// Gets category for equipment
    private func getCategoryForEquipment(_ name: String) -> String {
        switch name {
        case "Dumbbells", "Kettlebell", "Barbell", "Weight Plates": return "Weights"
        case "Resistance Bands": return "Resistance"
        case "Pull-up Bar": return "Bodyweight"
        case "Adjustable Bench": return "Support"
        case "Yoga Mat", "Foam Roller": return "Accessories"
        case "Jump Rope": return "Cardio"
        default: return "Other"
        }
    }
    
    /// Available equipment list for reference
    private let availableEquipment: [Equipment] = [
        .init(name: "Dumbbells", icon: "dumbbell"),
        .init(name: "Resistance Bands", icon: "bolt.horizontal.circle"),
        .init(name: "Kettlebell", icon: "circle"),
        .init(name: "Barbell", icon: "dumbbell"),
        .init(name: "Weight Plates", icon: "circlebadge"),
        .init(name: "Pull-up Bar", icon: "figure.climbing"),
        .init(name: "Adjustable Bench", icon: "rectangle.portrait"),
        .init(name: "Yoga Mat", icon: "rectangle"),
        .init(name: "Jump Rope", icon: "figure.walk"),
        .init(name: "Foam Roller", icon: "capsule")
    ]
}

struct EquipmentSetupView: View {
    let initialSelection: Set<String>
    var onDone: ([WorkoutSetupView.Equipment]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var tempSelection: Set<String>

    init(initialSelection: Set<String> = [], onDone: @escaping ([WorkoutSetupView.Equipment]) -> Void) {
        self.initialSelection = initialSelection
        self.onDone = onDone
        self._tempSelection = State(initialValue: initialSelection)
    }

    private let available: [WorkoutSetupView.Equipment] = [
        .init(name: "Dumbbells", icon: "dumbbell"),
        .init(name: "Resistance Bands", icon: "bolt.horizontal.circle"),
        .init(name: "Kettlebell", icon: "circle"),
        .init(name: "Barbell", icon: "dumbbell"),
        .init(name: "Weight Plates", icon: "circlebadge"),
        .init(name: "Pull-up Bar", icon: "figure.climbing"),
        .init(name: "Adjustable Bench", icon: "rectangle.portrait"),
        .init(name: "Yoga Mat", icon: "rectangle"),
        .init(name: "Jump Rope", icon: "figure.walk"),
        .init(name: "Foam Roller", icon: "capsule")
    ]

    var body: some View {
        List {
            ForEach(self.available) { item in
                HStack {
                    Image(systemName: item.icon)
                        .foregroundColor(DesignSystem.ColorRole.primary)
                    Text(item.name)
                    Spacer()
                    if self.tempSelection.contains(item.name) {
                        Image(systemName: "checkmark")
                            .foregroundColor(DesignSystem.ColorRole.success)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if self.tempSelection.contains(item.name) {
                        self.tempSelection.remove(item.name)
                    } else {
                        self.tempSelection.insert(item.name)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .vlBrandBackground()
        .navigationTitle("Equipment")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    let selected = self.available.filter { self.tempSelection.contains($0.name) }
                    self.onDone(selected)
                    self.dismiss()
                }
            }
        }
    }
}

struct PlanCreationView: View {
    let selectedEquipmentNames: Set<String>
    var onDone: ([WorkoutSetupView.Plan]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var planName: String = ""
    @State private var exercises: [WorkoutSetupView.Exercise] = []
    @State private var showAddExercise: Bool = false
    @State private var currentGroup: WorkoutSetupView.MuscleGroup = .chest

    var body: some View {
        Form {
            Section("Plan") {
                TextField("Name", text: self.$planName)
            }

            Section("Exercises") {
                if self.exercises.isEmpty {
                    Text("No exercises yet").foregroundColor(DesignSystem.ColorRole.textSecondary)
                } else {
                    ForEach(self.exercises) { exercise in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercise.name)
                                Text(exercise.muscleGroup.rawValue).font(.caption)
                                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { idx in self.exercises.remove(atOffsets: idx) }
                }

                Button {
                    self.showAddExercise = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle")
                }
            }

            Section {
                Button("Save") {
                    let name = self.planName.trimmingCharacters(in: .whitespacesAndNewlines)
                    let new = WorkoutSetupView.Plan(name: name.isEmpty ? "My Plan" : name, exercises: self.exercises)
                    self.onDone([new])
                    self.dismiss()
                }
                .disabled(self.planName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .sheet(isPresented: self.$showAddExercise) {
            AddExerciseView(
                availableEquipment: self.selectedEquipmentNames,
                initialGroup: self.currentGroup
            ) { group, added in
                self.currentGroup = group
                self.exercises.append(contentsOf: added)
            }
        }
        .scrollContentBackground(.hidden)
        .vlBrandBackground()
        .navigationTitle("New Plan")
    }
}

struct AddExerciseView: View {
    let availableEquipment: Set<String>
    let initialGroup: WorkoutSetupView.MuscleGroup
    var onAdd: (WorkoutSetupView.MuscleGroup, [WorkoutSetupView.Exercise]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedGroup: WorkoutSetupView.MuscleGroup
    @State private var selectedExercises: Set<UUID> = []
    @State private var showingExerciseDetail = false
    @State private var selectedExerciseForDetail: Exercise?

    init(
        availableEquipment: Set<String>,
        initialGroup: WorkoutSetupView.MuscleGroup,
        onAdd: @escaping (WorkoutSetupView.MuscleGroup, [WorkoutSetupView.Exercise]) -> Void
    ) {
        self.availableEquipment = availableEquipment
        self.initialGroup = initialGroup
        self.onAdd = onAdd
        self._selectedGroup = State(initialValue: initialGroup)
    }

    var exercisesWithHints: [ExerciseDisplayItem] {
        guard let enhancedMuscleGroup = MuscleGroup(rawValue: self.selectedGroup.rawValue) else {
            return []
        }
        return ExerciseService.shared.getExercisesWithEquipmentHints(
            for: enhancedMuscleGroup,
            availableEquipment: self.availableEquipment
        )
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Form {
                    Section("Muscle Group") {
                        Picker("Muscle Group", selection: self.$selectedGroup) {
                            ForEach(WorkoutSetupView.MuscleGroup.allCases) { group in
                                Text(group.rawValue).tag(group)
                            }
                        }
                        .onChange(of: self.selectedGroup) { _, _ in self.selectedExercises.removeAll() }
                    }

                    Section("All Exercises") {
                        if self.exercisesWithHints.isEmpty {
                            Text("No exercises available for this muscle group")
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        } else {
                            ForEach(self.exercisesWithHints) { displayItem in
                                ExerciseRowView(
                                    displayItem: displayItem,
                                    isSelected: self.selectedExercises.contains(displayItem.exercise.id),
                                    onTap: {
                                        if self.selectedExercises.contains(displayItem.exercise.id) {
                                            self.selectedExercises.remove(displayItem.exercise.id)
                                        } else {
                                            self.selectedExercises.insert(displayItem.exercise.id)
                                        }
                                    },
                                    onShowDetail: {
                                        self.selectedExerciseForDetail = displayItem.exercise
                                        self.showingExerciseDetail = true
                                    }
                                )
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Add \(self.selectedExercises.count)") {
                        let selectedDisplayItems = self.exercisesWithHints.filter { 
                            self.selectedExercises.contains($0.exercise.id) 
                        }
                        let legacyExercises = selectedDisplayItems.map { $0.exercise.legacyExercise }
                        self.onAdd(self.selectedGroup, legacyExercises)
                        self.dismiss()
                    }
                    .buttonStyle(VLPrimaryButtonStyle())
                    .disabled(self.selectedExercises.isEmpty)
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Add Exercise")
        }
        .presentationDetents([.large])
        .sheet(isPresented: self.$showingExerciseDetail) {
            if let exercise = self.selectedExerciseForDetail {
                ExerciseDetailView(
                    exercise: exercise,
                    onAddToWorkout: {
                        // Add the exercise to selection and close detail view
                        self.selectedExercises.insert(exercise.id)
                        self.showingExerciseDetail = false
                    }
                )
            }
        }
    }
}

// MARK: - ExerciseRowView

struct ExerciseRowView: View {
    let displayItem: ExerciseDisplayItem
    let isSelected: Bool
    let onTap: () -> Void
    let onShowDetail: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            // Exercise icon
            Image(systemName: displayItem.exercise.sfSymbolName)
                .foregroundColor(displayItem.isAvailable ? DesignSystem.ColorRole.primary : DesignSystem.ColorRole.textSecondary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                // Exercise name
                Text(displayItem.exercise.name)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(displayItem.isAvailable ? DesignSystem.ColorRole.textPrimary : DesignSystem.ColorRole.textSecondary)
                
                // Equipment status
                HStack(spacing: DesignSystem.Spacing.s) {
                    if displayItem.isAvailable {
                        // Available indicator
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignSystem.ColorRole.success)
                                .font(.caption)
                            Text("Available")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.ColorRole.success)
                        }
                    } else if displayItem.exercise.requiredEquipment.isEmpty {
                        // Bodyweight exercise
                        HStack(spacing: 4) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .foregroundColor(DesignSystem.ColorRole.primary)
                                .font(.caption)
                            Text("Bodyweight")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.ColorRole.primary)
                        }
                    } else {
                        // Missing equipment indicator
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(DesignSystem.ColorRole.warning)
                                .font(.caption)
                            Text("Needs: \(displayItem.missingEquipment.sorted().joined(separator: ", "))")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.ColorRole.warning)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Info button for exercise details
            Button(action: onShowDetail) {
                Image(systemName: "info.circle")
                    .foregroundColor(DesignSystem.ColorRole.secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? DesignSystem.ColorRole.primary : DesignSystem.ColorRole.textSecondary)
                .font(.title3)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

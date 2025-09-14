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

    @State private var selectedEquipment: [Equipment] = []
    @State private var plans: [Plan] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                self.header

                if self.selectedEquipment.isEmpty {
                    VLGlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                            Text("Add your equipment")
                                .font(DesignSystem.Typography.titleS)
                                .foregroundColor(DesignSystem.ColorRole.textPrimary)
                            Text("Personalize your workouts by selecting the equipment you have.")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)

                            NavigationLink {
                                EquipmentSetupView(initialSelection: Set(self.selectedEquipment
                                        .map(\.name)
                                )) { equipment in
                                    self.selectedEquipment = equipment
                                }
                            } label: {
                                VLButtonLabel("Add Equipment", style: .primary)
                            }
                        }
                    }
                }

                if self.plans.isEmpty {
                    VLGlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                            Text("Create your first plan")
                                .font(DesignSystem.Typography.titleS)
                                .foregroundColor(DesignSystem.ColorRole.textPrimary)
                            Text("We'll generate balanced sessions based on your goals.")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)

                            NavigationLink {
                                PlanCreationView(selectedEquipmentNames: Set(self.selectedEquipment
                                        .map(\.name)
                                )) { newPlans in
                                    self.plans = newPlans
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

                if !self.selectedEquipment.isEmpty {
                    self.equipmentSection
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.large)
        .vlBrandBackground()
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
                Text("Plans")
                    .font(DesignSystem.Typography.titleS)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                ForEach(self.plans) { plan in
                    VLListRow(plan.name, subtitle: "\(plan.exercises.count) exercises") {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(DesignSystem.ColorRole.primary)
                    } trailing: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                    Divider().opacity(0.2)
                }
            }
        }
    }

    private var equipmentSection: some View {
        NavigationLink {
            EquipmentSetupView(initialSelection: Set(self.selectedEquipment.map(\.name))) { equipment in
                self.selectedEquipment = equipment
            }
        } label: {
            VLGlassCard {
                HStack(spacing: DesignSystem.Spacing.m) {
                    Text("Equipment")
                        .font(DesignSystem.Typography.titleS)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Spacer()
                    Text("\(self.selectedEquipment.count)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    Image(systemName: "pencil.circle")
                        .foregroundColor(DesignSystem.ColorRole.primary)
                }
            }
        }
        .buttonStyle(.plain)
    }
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

    var filtered: [WorkoutSetupView.Exercise] {
        ExerciseCatalog.forGroup(self.selectedGroup, availableEquipment: self.availableEquipment)
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

                    Section("Available Exercises") {
                        if self.filtered.isEmpty {
                            Text("No exercises for your equipment")
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        } else {
                            ForEach(self.filtered) { exercise in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(exercise.name)
                                        Text(exercise.muscleGroup.rawValue).font(.caption)
                                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: self.selectedExercises
                                        .contains(exercise.id) ? "checkmark.circle.fill" : "circle"
                                    )
                                    .foregroundColor(self.selectedExercises.contains(exercise.id) ? DesignSystem
                                        .ColorRole
                                        .primary : DesignSystem.ColorRole.textSecondary
                                    )
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if self.selectedExercises
                                        .contains(exercise.id) { self.selectedExercises.remove(exercise.id) }
                                    else { self.selectedExercises.insert(exercise.id) }
                                }
                            }
                        }
                    }
                }

                HStack {
                    Spacer()
                    Button("Add \(self.selectedExercises.count)") {
                        let added = self.filtered.filter { self.selectedExercises.contains($0.id) }
                        self.onAdd(self.selectedGroup, added)
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
    }
}

import SwiftUI

struct PlanEditorView: View {
    @StateObject private var viewModel: PlanEditorViewModel
    @EnvironmentObject private var userPreferencesService: UserPreferencesService
    @Environment(\.dismiss) private var dismiss

    init(plan: PlanDraft) {
        _viewModel = StateObject(wrappedValue: PlanEditorViewModel(plan: plan))
    }

    @State private var showExercisePicker = false
    @State private var showRemoveExerciseConfirm = false
    @State private var pendingExerciseToRemove: PlanExerciseDraft?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                ForEach(self.viewModel.plan.exercises) { exercise in
                    VLGlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                            // Übungs-Header
                            HStack(spacing: DesignSystem.Spacing.s) {
                                Text(exercise.displayName)
                                    .font(DesignSystem.Typography.titleS)
                                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                                Spacer()
                                Text("\(exercise.sets.count) Sets")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
                                Button(role: .destructive) {
                                    self.pendingExerciseToRemove = exercise
                                    self.showRemoveExerciseConfirm = true
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(DesignSystem.ColorRole.danger)
                            }

                            // Sets edit list
                            ForEach(exercise.sets.indices, id: \.self) { index in
                                let set = exercise.sets[index]
                                VStack(alignment: .leading, spacing: 8) {
                                    SetEditorRow(
                                        exerciseId: exercise.id,
                                        setIndex: index,
                                        allowsUnilateral: exercise.allowsUnilateral,
                                        set: set
                                    ) { reps, type, side, comment in
                                        self.viewModel.editSetAttributes(
                                            exerciseId: exercise.id,
                                            setIndex: index,
                                            reps: reps,
                                            setType: type,
                                            side: side,
                                            comment: comment
                                        )
                                    }

                                    // Set-level actions: delete only
                                    HStack {
                                        Spacer()
                                        Button(role: .destructive) {
                                            self.viewModel.removeSet(from: exercise.id, at: index)
                                        } label: {
                                            Label("Satz löschen", systemImage: "trash")
                                        }
                                        .buttonStyle(.borderless)
                                    }
                                }

                                if index < exercise.sets.count - 1 {
                                    Rectangle()
                                        .fill(DesignSystem.ColorRole.textSecondary.opacity(0.14))
                                        .frame(height: 1)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 6)
                                }
                            }

                            // Add set button
                            Button {
                                let newSet = PlanSetDraft(reps: 10, setType: .normal, side: .both, comment: nil)
                                self.viewModel.addSet(to: exercise.id, newSet: newSet)
                            } label: {
                                Label("Satz hinzufügen", systemImage: "plus.circle")
                            }
                            .tint(DesignSystem.ColorRole.primary)
                        }
                    }
                }
                // Global: Add exercise at bottom
                HStack {
                    Spacer()
                    Button {
                        self.showExercisePicker = true
                    } label: {
                        Label("Übung hinzufügen", systemImage: "plus")
                    }
                    .tint(DesignSystem.ColorRole.primary)
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .vlBrandBackground()
        .navigationTitle("Plan bearbeiten")
        .sheet(isPresented: self.$showExercisePicker) {
            // Equipment-basiert & nach Muskelgruppen gruppiert (bestehender Flow)
            let available = Set(self.userPreferencesService.selectedEquipment.filter(\.isSelected).map(\.name))
            AddExerciseView(
                availableEquipment: available,
                initialGroup: .chest
            ) { _, added in
                // Mappe Legacy-Exercise zu Enhanced Exercise per Namen
                let all = ExerciseService.shared.getAllExercises()
                for legacy in added {
                    if let enhanced = all.first(where: { $0.name.lowercased() == legacy.name.lowercased() }) {
                        self.viewModel.addExercise(from: enhanced)
                    }
                }
            }
        }
        .alert("Übung entfernen?", isPresented: self.$showRemoveExerciseConfirm) {
            Button("Löschen", role: .destructive) {
                if let ex = self.pendingExerciseToRemove { self.viewModel.removeExercise(exerciseId: ex.id) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Speichern") {
                    // 1) Domain-Validierung
                    self.viewModel.savePlan()

                    // 2) Persistenz – PlanDraft → WorkoutPlanData → Core Data via UserPreferencesService
                    let mapped = self.mapToWorkoutPlanData(self.viewModel.plan)
                    Task {
                        do {
                            try await self.userPreferencesService.savePlan(mapped)
                            self.dismiss()
                        } catch {
                            self.viewModel.lastError = (error as? UserPreferencesError)?.localizedDescription
                                ?? error.localizedDescription
                        }
                    }
                }
            }
        }
        .alert(item: Binding(
            get: { self.viewModel.lastError.map { LocalizedErrorWrapper(message: $0) } },
            set: { _ in self.viewModel.lastError = nil }
        )) { wrapper in
            Alert(title: Text("Fehler"), message: Text(wrapper.message), dismissButton: .default(Text("OK")))
        }
    }
}

// MARK: - Mapping

private extension PlanEditorView {
    func mapToWorkoutPlanData(_ plan: PlanDraft) -> WorkoutPlanData {
        let exercises: [ExerciseData] = plan.exercises.enumerated().map { idx, ex in
            let sets: [ExerciseSet] = ex.sets.enumerated().map { setIdx, s in
                let setType: SetType = switch s.setType {
                case .warmUp: .warmUp
                case .normal: .normal
                case .coolDown: .coolDown
                }
                return ExerciseSet(setNumber: setIdx + 1, reps: s.reps, weight: 0.0, setType: setType)
            }

            return ExerciseData(
                id: ex.id,
                name: ex.displayName,
                sets: sets,
                restTime: 60,
                orderIndex: idx
            )
        }

        return WorkoutPlanData(
            id: plan.id,
            name: plan.name,
            exercises: exercises
        )
    }
}

private struct SetEditorRow: View {
    let exerciseId: UUID
    let setIndex: Int
    let allowsUnilateral: Bool
    let set: PlanSetDraft
    let onChange: (Int, ExerciseSetType, ExecutionSide, String?) -> Void

    @State private var reps: Int
    @State private var type: ExerciseSetType
    @State private var side: ExecutionSide
    @State private var comment: String

    init(
        exerciseId: UUID,
        setIndex: Int,
        allowsUnilateral: Bool,
        set: PlanSetDraft,
        onChange: @escaping (Int, ExerciseSetType, ExecutionSide, String?) -> Void
    ) {
        self.exerciseId = exerciseId
        self.setIndex = setIndex
        self.allowsUnilateral = allowsUnilateral
        self.set = set
        self.onChange = onChange
        _reps = State(initialValue: set.reps)
        _type = State(initialValue: set.setType)
        _side = State(initialValue: set.side)
        _comment = State(initialValue: set.comment ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Line 1: Set number ---- <Type of set>
            HStack(alignment: .firstTextBaseline) {
                Text("Satz \(self.setIndex + 1)")
                Spacer()
                Picker(selection: self.$type) {
                    ForEach(ExerciseSetType.allCases, id: \.self) { typeOption in
                        Text(self.displayName(for: typeOption)).tag(typeOption)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(self.displayName(for: self.type))
                        Image(systemName: "chevron.down")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                .pickerStyle(.menu)
                .onChange(of: self.type) { _, newValue in
                    self.emitChange(reps: self.reps, type: newValue, side: self.side, comment: self.comment)
                }
            }

            // Line 2: Reps ---- <Number of reps>
            HStack(alignment: .firstTextBaseline) {
                Text("Reps")
                Spacer()
                Picker(selection: self.$reps) {
                    ForEach(0 ... 200, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("\(self.reps)")
                        Image(systemName: "chevron.down")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                .pickerStyle(.menu)
                .onChange(of: self.reps) { _, newValue in
                    self.emitChange(reps: newValue, type: self.type, side: self.side, comment: self.comment)
                }
            }

            // Line 3: Commentary
            TextField("Kommentar (optional)", text: self.$comment)
                .onSubmit { self.emitChange(reps: self.reps, type: self.type, side: self.side, comment: self.comment) }
        }
    }

    private func emitChange(reps: Int, type: ExerciseSetType, side: ExecutionSide, comment: String?) {
        self.onChange(reps, type, side, (comment?.isEmpty ?? true) ? nil : comment)
    }

    private func displayName(for type: ExerciseSetType) -> String {
        switch type {
        case .warmUp: "Aufwärmen"
        case .normal: "Normal"
        case .coolDown: "Cool-down"
        }
    }
}

private struct LocalizedErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

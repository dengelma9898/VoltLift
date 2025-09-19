import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var viewModel: WorkoutSessionViewModel
    @Environment(\.dismiss) private var dismiss

    let plan: WorkoutPlanData

    init(plan: WorkoutPlanData) {
        self.plan = plan
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(planId: plan.id))
    }

    // Per‑Satz Eingaben/Zustände
    @State private var weightPerSet: [Int: Double] = [:]
    @State private var repsPerSetPerformed: [Int: Int] = [:]
    @State private var difficultyPerSet: [Int: Int] = [:]
    @State private var completedSets: Set<Int> = []
    @State private var pageIndex: Int = 0
    @State private var showSummary = false
    @State private var summaryType: WorkoutSummaryView.CompletionType = .finished
    @State private var showPlanEdit = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Session")
                .font(DesignSystem.Typography.titleM)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)

            TabView(selection: self.$pageIndex) {
                ForEach(Array(self.plan.exercises.enumerated()), id: \.offset) { exerciseIdx, ex in
                    ScrollView {
                        VStack(spacing: 12) {
                            header(for: ex)
                            setsList(for: ex)
                            timerView()
                            sessionActions()
                        }
                        .padding(.horizontal)
                    }
                    .tag(exerciseIdx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
        .padding()
        .vlBrandBackground()
        .navigationTitle("Session")
        .alert(item: Binding(
            get: { self.viewModel.lastError.map { LocalizedErrorWrapper(message: $0) } },
            set: { _ in self.viewModel.lastError = nil }
        )) { wrapper in
            Alert(title: Text("Fehler"), message: Text(wrapper.message), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: self.$showSummary) {
            WorkoutSummaryView(
                completion: self.summaryType,
                entries: self.viewModel.entries,
                onExit: {
                    self.showSummary = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        self.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            self.dismiss()
                        }
                    }
                }
            )
        }
        .sheet(isPresented: self.$showPlanEdit) {
            NavigationStack {
                VStack(spacing: 16) {
                    Text("Planänderungen während der Session")
                        .font(DesignSystem.Typography.titleS)
                    Text("Hier können Sätze/Reps geändert werden. Änderungen werden erst bei Finish übernommen.")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                .padding()
                .navigationTitle("Plan bearbeiten")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) { Button("Fertig") { self.showPlanEdit = false } }
                }
                .vlBrandBackground()
            }
        }
    }
}

private struct LocalizedErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Subviews & Helpers

private extension WorkoutSessionView {
    func header(for ex: ExerciseData) -> some View {
        VStack(spacing: 12) {
            Text(ex.name)
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
            Text(self.exerciseDescription(for: ex))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    func setsList(for ex: ExerciseData) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(ex.sets.enumerated()), id: \.offset) { setIdx, planSet in
                self.setCard(exerciseId: ex.id, setIdx: setIdx, planSet: planSet)
            }
        }
    }

    func setCard(exerciseId: UUID, setIdx: Int, planSet: ExerciseSet) -> some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Satz \(planSet.setNumber) • geplant: \(planSet.reps) Reps")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Spacer()
                    if self.completedSets.contains(setIdx) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(DesignSystem.ColorRole.success)
                    }
                }

                if self.exerciseUsesEquipment(exerciseId: exerciseId) {
                    Stepper(value: self.bindingWeight(for: setIdx), in: 0 ... 1_000, step: 0.5) {
                        Text("Gewicht: \(String(format: "%.1f", self.weightPerSet[setIdx] ?? 0)) kg")
                    }
                } else {
                    Text("Körpergewicht")
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }

                Stepper(value: self.bindingReps(for: setIdx, defaultValue: planSet.reps), in: 0 ... 200) {
                    Text("Ausgeführte Reps: \(self.repsPerSetPerformed[setIdx] ?? planSet.reps)")
                }

                Picker("Schwierigkeit (1–10)", selection: self.bindingDifficulty(for: setIdx)) {
                    ForEach(1 ... 10, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.segmented)

                Button(self.completedSets.contains(setIdx) ? "Erfasst" : "Satz bestätigen") {
                    self.confirmSet(exerciseId: exerciseId, setIdx: setIdx, fallbackReps: planSet.reps)
                }
                .disabled(self.completedSets.contains(setIdx))
            }
        }
    }

    func timerView() -> some View {
        Group {
            if self.viewModel.timerRemainingSeconds > 0 {
                Text("Rest: \(self.viewModel.timerRemainingSeconds)s")
                    .font(DesignSystem.Typography.titleS)
            }
        }
    }

    func sessionActions() -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Button("Plan ändern") { self.showPlanEdit = true }
            Button("Cancel") {
                self.viewModel.cancel()
                self.summaryType = .canceled
                self.showSummary = true
            }
            Button("Finish") {
                self.viewModel.finish()
                self.summaryType = .finished
                self.showSummary = true
            }
        }
    }

    // MARK: Bindings

    func bindingWeight(for setIdx: Int) -> Binding<Double> {
        Binding<Double>(
            get: { self.weightPerSet[setIdx] ?? 0 },
            set: { self.weightPerSet[setIdx] = $0 }
        )
    }

    func bindingReps(for setIdx: Int, defaultValue: Int) -> Binding<Int> {
        Binding<Int>(
            get: { self.repsPerSetPerformed[setIdx] ?? defaultValue },
            set: { self.repsPerSetPerformed[setIdx] = $0 }
        )
    }

    func bindingDifficulty(for setIdx: Int) -> Binding<Int> {
        Binding<Int>(
            get: { self.difficultyPerSet[setIdx] ?? 5 },
            set: { self.difficultyPerSet[setIdx] = $0 }
        )
    }

    // MARK: Actions

    func confirmSet(exerciseId: UUID, setIdx: Int, fallbackReps: Int) {
        let repsDone = self.repsPerSetPerformed[setIdx] ?? fallbackReps
        let diff = self.difficultyPerSet[setIdx] ?? 5
        let diffs = Array(repeating: diff, count: max(0, repsDone))
        let weight = self.exerciseUsesEquipment(exerciseId: exerciseId) ? (self.weightPerSet[setIdx] ?? 0) : nil

        self.viewModel.confirmRep(
            planExerciseId: exerciseId,
            setIndex: setIdx,
            repIndex: repsDone,
            weightKg: weight,
            exerciseUsesEquipment: self.exerciseUsesEquipment(exerciseId: exerciseId),
            difficulties: diffs
        )
        self.completedSets.insert(setIdx)

        if let ex = self.plan.exercises.first(where: { $0.id == exerciseId }),
           self.completedSets.count >= ex.sets.count
        {
            self.viewModel.autoAdvanceToNextExercise()
            self.pageIndex = min(self.pageIndex + 1, self.plan.exercises.count - 1)
            self.completedSets.removeAll(keepingCapacity: false)
            self.weightPerSet.removeAll(keepingCapacity: false)
            self.repsPerSetPerformed.removeAll(keepingCapacity: false)
            self.difficultyPerSet.removeAll(keepingCapacity: false)
        }
    }

    func exerciseDescription(for ex: ExerciseData) -> String {
        if let enhanced = ExerciseService.shared.getExercise(by: ex.id) {
            return enhanced.description
        }
        return ""
    }

    func exerciseUsesEquipment(exerciseId: UUID) -> Bool {
        if let enhanced = ExerciseService.shared.getExercise(by: exerciseId) {
            return !enhanced.requiredEquipment.isEmpty
        }
        return false
    }
}

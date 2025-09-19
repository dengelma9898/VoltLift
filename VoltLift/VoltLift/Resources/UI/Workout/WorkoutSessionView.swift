import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var viewModel: WorkoutSessionViewModel
    @Environment(\.dismiss) private var dismiss

    let plan: WorkoutPlanData

    // Laufzeitkopie des Plans, um Sätze lokal hinzufügen/entfernen zu können
    @State private var planData: WorkoutPlanData

    init(plan: WorkoutPlanData) {
        self.plan = plan
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(planId: plan.id))
        _planData = State(initialValue: plan)
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
    @State private var infoExercise: ExerciseData?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Workout Session")
                    .font(DesignSystem.Typography.titleM)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                Spacer()
                topTimerView()
            }

            TabView(selection: self.$pageIndex) {
                ForEach(Array(self.planData.exercises.enumerated()), id: \.offset) { exerciseIndex, exercise in
                    ScrollView {
                        VStack(spacing: 12) {
                            header(for: exercise)
                            setsList(for: exercise)
                            sessionActions(for: exercise)
                        }
                        .padding(.horizontal)
                    }
                    .tag(exerciseIndex)
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
        .sheet(isPresented: self.$showPlanEdit) { // bleibt vorerst, wird aber nicht mehr verlinkt
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
        .sheet(item: self.$infoExercise) { ex in
            exerciseInfoView(ex)
        }
    }
}

private struct LocalizedErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

// MARK: - Subviews & Helpers

private extension WorkoutSessionView {
    func topTimerView() -> some View {
        let seconds = max(0, self.viewModel.timerRemainingSeconds)
        let timeString = self.formatSeconds(seconds)
        return Text("Rest: \(timeString)")
            .font(DesignSystem.Typography.body)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .foregroundColor(DesignSystem.ColorRole.textPrimary)
    }

    func header(for exercise: ExerciseData) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(exercise.name)
                    .font(DesignSystem.Typography.titleS)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                Button {
                    self.infoExercise = exercise
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                Spacer()
                Button {
                    self.addSet(to: exercise.id)
                } label: {
                    Label("Satz hinzufügen", systemImage: "plus")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
            }

            Text(self.exerciseDescription(for: exercise))
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }

    func setsList(for exercise: ExerciseData) -> some View {
        VStack(spacing: 10) {
            ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, planSet in
                self.setCard(exerciseId: exercise.id, setIdx: setIndex, planSet: planSet)
            }
        }
    }

    func setCard(exerciseId: UUID, setIdx: Int, planSet: ExerciseSet) -> some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Satz \(planSet.setNumber) • geplant: \(planSet.reps) Reps")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Spacer()
                    // Set-Typ Badge
                    Label(planSet.setType.displayName, systemImage: planSet.setType.icon)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06), in: Capsule())
                }

                // Vereinheitlichte Dropdown-Auswahlen mit sichtbaren Labels
                VStack(alignment: .leading, spacing: 12) {
                    if self.exerciseUsesEquipment(exerciseId: exerciseId) {
                        Text("Gewicht")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        Picker(selection: self.bindingWeight(for: setIdx)) {
                            ForEach(self.weightOptions(), id: \.self) { value in
                                Text(String(format: "%.1f kg", value)).tag(value as Double)
                            }
                        } label: {
                            HStack { Text(String(format: "%.1f kg", self.weightPerSet[setIdx] ?? 0))
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                        }
                        .pickerStyle(.menu)
                    } else {
                        Text("Körpergewicht")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }

                    Text("Reps")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    Picker(selection: self.bindingReps(for: setIdx, defaultValue: planSet.reps)) {
                        ForEach(self.repOptions(planned: planSet.reps), id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    } label: {
                        HStack { Text("\(self.repsPerSetPerformed[setIdx] ?? planSet.reps)")
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                    }
                    .pickerStyle(.menu)

                    Text("Schwierigkeit")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    Picker(selection: self.bindingDifficulty(for: setIdx)) {
                        ForEach(1 ... 10, id: \.self) { value in
                            Text("\(value)")
                                .tag(value)
                        }
                    } label: {
                        let currentDifficulty = self.difficultyPerSet[setIdx] ?? 5
                        HStack { Text("\(currentDifficulty) (\(self.difficultyDescriptor(for: currentDifficulty)))")
                            Spacer()
                            Image(systemName: "chevron.down")
                        }
                    }
                    .pickerStyle(.menu)

                    Text("1 = zu leicht • 10 = keine Wiederholung mehr möglich")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }

                HStack {
                    Button(self.completedSets.contains(setIdx) ? "Erfasst" : "Satz bestätigen") {
                        self.confirmSet(exerciseId: exerciseId, setIdx: setIdx, fallbackReps: planSet.reps)
                    }
                    .disabled(self.completedSets.contains(setIdx))

                    Spacer()

                    Button(role: .destructive) {
                        self.removeSet(from: exerciseId, setIndex: setIdx)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(self.planData.exercises.first(where: { $0.id == exerciseId })?.sets.count ?? 0 <= 1)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                .fill(DesignSystem.ColorRole.success.opacity(0.17))
                .opacity(self.completedSets.contains(setIdx) ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: self.completedSets)
        )
        .shadow(
            color: DesignSystem.ColorRole.success.opacity(self.completedSets.contains(setIdx) ? 0.25 : 0),
            radius: 14,
            y: 6
        )
    }

    func sessionActions(for exercise: ExerciseData) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            // Entfernt: Button "Plan ändern"
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

    // MARK: Options & Descriptions

    func weightOptions() -> [Double] {
        stride(from: 0.0, through: 200.0, by: 0.5).map { Double($0) }
    }

    func repOptions(planned: Int) -> [Int] {
        let maxReps = max(20, planned + 20)
        return Array(0 ... maxReps)
    }

    func difficultyDescriptor(for value: Int) -> String {
        switch value {
        case ...1: "zu leicht"
        case 2: "leicht"
        case 3: "moderat"
        case 4: "mittelschwer"
        case 5: "fordernd"
        case 6: "sehr fordernd"
        case 7: "hart"
        case 8: "sehr hart"
        case 9: "nahe Muskelversagen"
        default: "keine Wiederholung mehr möglich"
        }
    }

    func formatSeconds(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
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

        if let exercise = self.planData.exercises.first(where: { $0.id == exerciseId }),
           self.completedSets.count >= exercise.sets.count
        {
            self.viewModel.autoAdvanceToNextExercise()
            self.pageIndex = min(self.pageIndex + 1, self.planData.exercises.count - 1)
            self.completedSets.removeAll(keepingCapacity: false)
            self.weightPerSet.removeAll(keepingCapacity: false)
            self.repsPerSetPerformed.removeAll(keepingCapacity: false)
            self.difficultyPerSet.removeAll(keepingCapacity: false)
        }
    }

    func addSet(to exerciseId: UUID) {
        guard let index = self.planData.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        var exercise = self.planData.exercises[index]
        let last = exercise.sets.sorted { $0.setNumber < $1.setNumber }.last
        let newSetNumber = (exercise.sets.map(\.setNumber).max() ?? 0) + 1
        let defaultReps = last?.reps ?? 10
        let defaultWeight = (last?.weight ?? 0.0) + 2.5
        let defaultType = last?.setType ?? .normal
        let newSet = ExerciseSet(
            setNumber: newSetNumber,
            reps: defaultReps,
            weight: defaultWeight,
            setType: defaultType
        )
        var newSets = exercise.sets + [newSet]
        newSets = newSets.enumerated().map { idx, s in s.withSetNumber(idx + 1) }
        exercise = exercise.withUpdatedSets(newSets)
        var exercises = self.planData.exercises
        exercises[index] = exercise
        self.planData = WorkoutPlanData(
            id: self.planData.id,
            name: self.planData.name,
            exercises: exercises,
            createdDate: self.planData.createdDate,
            lastUsedDate: self.planData.lastUsedDate
        )
    }

    func removeSet(from exerciseId: UUID, setIndex: Int) {
        guard let exIndex = self.planData.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        var exercise = self.planData.exercises[exIndex]
        guard exercise.sets.indices.contains(setIndex), exercise.sets.count > 1 else { return }
        var sets = exercise.sets
        sets.remove(at: setIndex)
        sets = sets.enumerated().map { idx, s in s.withSetNumber(idx + 1) }
        exercise = exercise.withUpdatedSets(sets)
        var exercises = self.planData.exercises
        exercises[exIndex] = exercise
        self.planData = WorkoutPlanData(
            id: self.planData.id,
            name: self.planData.name,
            exercises: exercises,
            createdDate: self.planData.createdDate,
            lastUsedDate: self.planData.lastUsedDate
        )
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

    func exerciseInfoView(_ ex: ExerciseData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ex.name).font(DesignSystem.Typography.titleS)
            if let info = ExerciseService.shared.getExercise(by: ex.id) {
                Text(info.description)
                if !info.instructions.isEmpty {
                    Text("Anleitung").font(DesignSystem.Typography.body.weight(.semibold))
                    ForEach(info.instructions, id: \.self) { step in Text("• \(step)") }
                }
                if !info.safetyTips.isEmpty {
                    Text("Sicherheitshinweise").font(DesignSystem.Typography.body.weight(.semibold))
                    ForEach(info.safetyTips, id: \.self) { tip in Text("• \(tip)") }
                }
            }
            Spacer(minLength: 0)
        }
        .padding()
        .navigationTitle("Übungsinfo")
        .vlBrandBackground()
    }
}

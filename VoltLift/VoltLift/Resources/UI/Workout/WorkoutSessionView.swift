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
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 12) {
                                header(for: exercise)
                                setsList(for: exercise)
                                sessionActions(for: exercise)
                            }
                            .padding(.horizontal)
                            .id("top-\(exercise.id)")
                        }
                        .onChange(of: self.pageIndex) { _, newIndex in
                            if newIndex == exerciseIndex {
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo("top-\(exercise.id)", anchor: .top)
                                }
                            }
                        }
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
                },
                planExercises: self.planData.exercises
            )
            .interactiveDismissDisabled(true)
            .presentationDragIndicator(.hidden)
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
        .sheet(item: self.$infoExercise) { selectedExercise in
            exerciseInfoView(selectedExercise)
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
        RestTimerPill(endDate: self.viewModel.timerEndDate, fallbackSeconds: self.viewModel.timerRemainingSeconds)
    }

    struct RestTimerPill: View {
        let endDate: Date?
        let fallbackSeconds: Int

        @State private var now: Date = .init()
        private let ticker = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

        var body: some View {
            let remaining = self.computeRemainingSeconds()
            let timeString = self.formatSeconds(remaining)
            return Text("Rest: \(timeString)")
                .font(DesignSystem.Typography.body)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
                .onReceive(self.ticker) { date in
                    self.now = date
                }
        }

        private func computeRemainingSeconds() -> Int {
            if let endDate {
                return max(0, Int(endDate.timeIntervalSince(self.now).rounded()))
            }
            return max(0, self.fallbackSeconds)
        }

        private func formatSeconds(_ totalSeconds: Int) -> String {
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    func header(for exercise: ExerciseData) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(exercise.name)
                    .font(DesignSystem.Typography.titleS)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                Button { self.infoExercise = exercise } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                Spacer()
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

            Button {
                self.addSet(to: exercise.id)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Satz hinzufügen")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(DesignSystem.ColorRole.primary)
            .padding(.top, DesignSystem.Spacing.s)
        }
    }

    func setCard(exerciseId: UUID, setIdx: Int, planSet: ExerciseSet) -> some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text("Satz \(planSet.setNumber) • geplant: \(planSet.reps) Reps")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Spacer()

                    // Satztyp-Auswahl per Menü
                    Menu {
                        ForEach(SetType.allCases, id: \.self) { choice in
                            Button(action: { self.updateSetType(
                                exerciseId: exerciseId,
                                setIndex: setIdx,
                                newType: choice
                            ) }) {
                                Label(choice.displayName, systemImage: choice.icon)
                            }
                        }
                    } label: {
                        Label(planSet.setType.displayName, systemImage: planSet.setType.icon)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.ColorRole.textPrimary.opacity(0.06), in: Capsule())
                    }
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
                    .disabled(self.planData.exercises.first(where: { $0.id == exerciseId })?.sets.isEmpty == true)
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
            Button("Cancel") {
                self.viewModel.cancel()
                self.summaryType = .canceled
                self.showSummary = true
            }
            Button("Finish") {
                Task { @MainActor in
                    do {
                        // Übernehme bestätigte Einträge in den Plan (Reps & ggf. Satztyp)
                        var exercises = self.planData.exercises
                        for (index, ex) in exercises.enumerated() {
                            let confirmedForExercise = self.viewModel.entries
                                .filter { $0.planExerciseId == ex.id }
                            guard !confirmedForExercise.isEmpty else { continue }
                            var updatedSets = ex.sets
                            for entry in confirmedForExercise {
                                if entry.setIndex >= 0, entry.setIndex < updatedSets.count {
                                    // Aktualisiere Reps aus der Anzahl der bestätigten Schwierigkeiten
                                    let newReps = entry.difficulties.count
                                    let current = updatedSets[entry.setIndex]
                                    updatedSets[entry.setIndex] = ExerciseSet(
                                        setNumber: current.setNumber,
                                        reps: newReps,
                                        weight: current.weight,
                                        setType: current.setType
                                    )
                                }
                            }
                            exercises[index] = ex.withUpdatedSets(updatedSets)
                        }
                        self.planData = WorkoutPlanData(
                            id: self.planData.id,
                            name: self.planData.name,
                            exercises: exercises,
                            createdDate: self.planData.createdDate,
                            lastUsedDate: self.planData.lastUsedDate
                        )

                        let prefs = UserPreferencesService()
                        try await prefs.savePlan(self.planData)

                        // Markiere Planverwendung und berechne Summary für Historie
                        try await prefs.markPlanAsUsed(self.planData.id)
                        _ = WorkoutHistoryService.buildSummary(
                            for: self.viewModel.session,
                            entries: self.viewModel.entries
                        )

                        self.viewModel.finish()
                        self.summaryType = .finished
                        self.showSummary = true
                    } catch {
                        self.viewModel.lastError = error.localizedDescription
                    }
                }
            }
            .disabled(!self.allExercisesCompleted())
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

        // Auto-Advance nur, wenn es eine nächste Übung gibt. Auf der letzten Seite Markierungen behalten.
        if let exercise = self.planData.exercises.first(where: { $0.id == exerciseId }),
           self.completedSets.count >= exercise.sets.count
        {
            guard let currentIndex = self.planData.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
            let isLastExercise = currentIndex >= (self.planData.exercises.count - 1)
            if !isLastExercise {
                self.viewModel.autoAdvanceToNextExercise()
                withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.85)) {
                    self.pageIndex = min(self.pageIndex + 1, self.planData.exercises.count - 1)
                }
                // Für die neue Übung lokale Eingaben zurücksetzen
                self.completedSets.removeAll(keepingCapacity: false)
                self.weightPerSet.removeAll(keepingCapacity: false)
                self.repsPerSetPerformed.removeAll(keepingCapacity: false)
                self.difficultyPerSet.removeAll(keepingCapacity: false)
            }
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
        guard let exerciseIndex = self.planData.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        var exercise = self.planData.exercises[exerciseIndex]
        guard exercise.sets.indices.contains(setIndex), exercise.sets.count > 1 else { return }
        var sets = exercise.sets
        sets.remove(at: setIndex)
        sets = sets.enumerated().map { idx, s in s.withSetNumber(idx + 1) }
        exercise = exercise.withUpdatedSets(sets)
        var exercises = self.planData.exercises
        exercises[exerciseIndex] = exercise
        self.planData = WorkoutPlanData(
            id: self.planData.id,
            name: self.planData.name,
            exercises: exercises,
            createdDate: self.planData.createdDate,
            lastUsedDate: self.planData.lastUsedDate
        )
    }

    func updateSetType(exerciseId: UUID, setIndex: Int, newType: SetType) {
        guard let exerciseIndex = self.planData.exercises.firstIndex(where: { $0.id == exerciseId }) else { return }
        var exercise = self.planData.exercises[exerciseIndex]
        guard exercise.sets.indices.contains(setIndex) else { return }
        var sets = exercise.sets
        sets[setIndex] = sets[setIndex].withUpdatedParameters(setType: newType)
        exercise = exercise.withUpdatedSets(sets)
        var exercises = self.planData.exercises
        exercises[exerciseIndex] = exercise
        self.planData = WorkoutPlanData(
            id: self.planData.id,
            name: self.planData.name,
            exercises: exercises,
            createdDate: self.planData.createdDate,
            lastUsedDate: self.planData.lastUsedDate
        )
    }

    // Info helpers
    func enhancedExercise(for exercise: ExerciseData) -> Exercise? {
        if let exerciseExact = ExerciseService.shared.getExercise(by: exercise.id) { return exerciseExact }
        // Fallback: Name-Match (case-insensitive)
        return ExerciseService.shared.getAllExercises().first { $0.name.lowercased() == exercise.name.lowercased() }
    }

    func exerciseDescription(for exercise: ExerciseData) -> String {
        if let enhanced = enhancedExercise(for: exercise) {
            return enhanced.description
        }
        return ""
    }

    func exerciseUsesEquipment(exerciseId: UUID) -> Bool {
        if let enhanced = ExerciseService.shared.getExercise(by: exerciseId) {
            return !enhanced.requiredEquipment.isEmpty
        }
        // Fallback by name (find in current page)
        if let exercise = self.planData.exercises.first(where: { $0.id == exerciseId }),
           let enhanced = enhancedExercise(for: exercise)
        {
            return !enhanced.requiredEquipment.isEmpty
        }
        return false
    }

    // MARK: Completion Helpers

    func isExerciseCompleted(_ exercise: ExerciseData) -> Bool {
        let confirmedSetIndices = Set(self.viewModel.entries.filter { $0.planExerciseId == exercise.id }
            .map(\.setIndex)
        )
        return !exercise.sets.isEmpty && confirmedSetIndices.count >= exercise.sets.count
    }

    func allExercisesCompleted() -> Bool {
        !self.planData.exercises.isEmpty && self.planData.exercises.allSatisfy { self.isExerciseCompleted($0) }
    }

    func exerciseInfoView(_ exercise: ExerciseData) -> some View {
        let info = self.enhancedExercise(for: exercise)
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: info?.sfSymbolName ?? "figure.strengthtraining.traditional")
                        Text(exercise.name).font(DesignSystem.Typography.titleS)
                    }
                    if let info {
                        if !info.targetMuscles.isEmpty {
                            Text("Zielmuskeln").font(DesignSystem.Typography.body.weight(.semibold))
                            Text(info.targetMuscles.joined(separator: ", "))
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        }
                        if !info.secondaryMuscles.isEmpty {
                            Text("Sekundäre Muskeln").font(DesignSystem.Typography.body.weight(.semibold))
                            Text(info.secondaryMuscles.joined(separator: ", "))
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        }
                        Text("Beschreibung").font(DesignSystem.Typography.body.weight(.semibold))
                        Text(info.description)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        if !info.instructions.isEmpty {
                            Text("Anleitung").font(DesignSystem.Typography.body.weight(.semibold))
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(info.instructions, id: \.self) { step in Text("• \(step)") }
                            }
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        }
                        if !info.safetyTips.isEmpty {
                            Text("Sicherheitshinweise").font(DesignSystem.Typography.body.weight(.semibold))
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(info.safetyTips, id: \.self) { tip in Text("• \(tip)") }
                            }
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        }
                        if !info.requiredEquipment.isEmpty {
                            Text("Equipment").font(DesignSystem.Typography.body.weight(.semibold))
                            Text(Array(info.requiredEquipment).sorted().joined(separator: ", "))
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        }
                    } else {
                        Text("Keine weiteren Informationen gefunden.")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Übungsinfo")
            .vlBrandBackground()
        }
    }
}

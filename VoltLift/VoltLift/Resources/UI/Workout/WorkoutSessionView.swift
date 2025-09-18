import SwiftUI

struct WorkoutSessionView: View {
    @StateObject private var viewModel: WorkoutSessionViewModel

    let planId: UUID
    let firstExerciseId: UUID
    let exerciseUsesEquipment: Bool

    init(planId: UUID, firstExerciseId: UUID, exerciseUsesEquipment: Bool) {
        self.planId = planId
        self.firstExerciseId = firstExerciseId
        self.exerciseUsesEquipment = exerciseUsesEquipment
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(planId: planId))
    }

    @State private var setIndex: Int = 0
    @State private var repIndex: Int = 0
    @State private var weightKg: Double = 0
    @State private var reps: Int = 0
    @State private var difficulties: [Int] = []
    @State private var showSummary = false
    @State private var summaryType: WorkoutSummaryView.CompletionType = .finished
    @State private var showPlanEdit = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Session")
                .font(DesignSystem.Typography.titleM)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)

            // Gewicht
            if self.exerciseUsesEquipment {
                Stepper(value: self.$weightKg, in: 0 ... 1_000, step: 0.5) {
                    Text("Gewicht: \(String(format: "%.1f", self.weightKg)) kg")
                }
            } else {
                Text("Körpergewicht")
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
            }

            // Reps + Schwierigkeiten
            Stepper(value: self.$reps, in: 0 ... 200) {
                Text("Wiederholungen: \(self.reps)")
            }
            if self.reps > 0 {
                Section("Schwierigkeit je Wiederholung (1–10)") {
                    ForEach(0 ..< self.reps, id: \.self) { i in
                        Picker("Wdh. \(i + 1)", selection: Binding(
                            get: { self.difficulties.indices.contains(i) ? self.difficulties[i] : 1 },
                            set: { newValue in
                                if self.difficulties.count <= i {
                                    self.difficulties.append(contentsOf: Array(
                                        repeating: 1,
                                        count: i - self.difficulties.count + 1
                                    ))
                                }
                                self.difficulties[i] = newValue
                            }
                        )) {
                            ForEach(1 ... 10, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                    }
                }
            }

            // Timer Anzeige
            if self.viewModel.timerRemainingSeconds > 0 {
                Text("Rest: \(self.viewModel.timerRemainingSeconds)s")
                    .font(DesignSystem.Typography.titleS)
            }

            HStack(spacing: DesignSystem.Spacing.m) {
                Button("Bestätigen") {
                    self.viewModel.confirmRep(
                        planExerciseId: self.firstExerciseId,
                        setIndex: self.setIndex,
                        repIndex: self.repIndex,
                        weightKg: self.exerciseUsesEquipment ? self.weightKg : nil,
                        exerciseUsesEquipment: self.exerciseUsesEquipment,
                        difficulties: self.difficulties
                    )
                    self.repIndex += 1
                }
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
            WorkoutSummaryView(completion: self.summaryType, entries: self.viewModel.entries)
        }
        .sheet(isPresented: self.$showPlanEdit) {
            // Minimaler Platzhalter für Plan-Edit-Overlay während der Session
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

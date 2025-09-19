import SwiftUI

struct WorkoutSummaryView: View {
    enum CompletionType {
        case finished
        case canceled
    }

    let completion: CompletionType
    let entries: [WorkoutSetEntry]
    let onExit: (() -> Void)?
    let planExercises: [ExerciseData]

    init(
        completion: CompletionType,
        entries: [WorkoutSetEntry],
        onExit: (() -> Void)? = nil,
        planExercises: [ExerciseData] = []
    ) {
        self.completion = completion
        self.entries = entries
        self.onExit = onExit
        self.planExercises = planExercises
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Text(self.title)
                .font(DesignSystem.Typography.titleM)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)

            if self.entries.isEmpty {
                Text("Keine Einträge erfasst.")
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
            } else {
                summaryHeader

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.m) {
                        // Reihenfolge gemäß Plan beibehalten; nur Übungen mit Einträgen anzeigen
                        ForEach(self.planExercises, id: \.id) { exercise in
                            if let group = self.groupedByExercise[exercise.id] {
                                sectionCard(for: exercise.id, sets: group)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }

            Button(action: { self.onExit?() }) {
                Text("Zur Übersicht")
                    .font(DesignSystem.Typography.body)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .vlBrandBackground()
    }

    private var title: String {
        switch self.completion {
        case .finished: "Workout abgeschlossen"
        case .canceled: "Workout abgebrochen"
        }
    }
}

private extension WorkoutSummaryView {
    var groupedByExercise: [UUID: [WorkoutSetEntry]] {
        Dictionary(grouping: self.entries, by: { $0.planExerciseId })
    }

    var totalSets: Int { self.entries.count }

    var totalReps: Int { self.entries.reduce(0) { $0 + $1.difficulties.count } }

    var totalVolumeKg: Double {
        self.entries.reduce(0) { acc, entry in
            let reps = entry.difficulties.count
            let weight = entry.weightKg ?? 0
            return acc + (weight * Double(reps))
        }
    }

    var summaryHeader: some View {
        VLGlassCard {
            HStack(spacing: DesignSystem.Spacing.l) {
                self.statView(title: "Sätze", value: "\(self.totalSets)")
                self.statView(title: "Reps", value: "\(self.totalReps)")
                self.statView(title: "Volumen", value: String(format: "%.0f kg", self.totalVolumeKg))
            }
        }
    }

    func statView(title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    func sectionCard(for exerciseId: UUID, sets: [WorkoutSetEntry]) -> some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                HStack {
                    Text(self.exerciseName(for: exerciseId))
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Spacer()
                    Text("\(sets.count) Sätze")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                Divider()
                ForEach(sets.sorted(by: { $0.setIndex < $1.setIndex })) { entry in
                    self.setRow(entry)
                    if entry.id != sets.sorted(by: { $0.setIndex < $1.setIndex }).last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    func setRow(_ entry: WorkoutSetEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.m) {
            Text("Set \(entry.setIndex + 1)")
                .frame(width: 56, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 12) {
                    Text(entry.weightKg.map { String(format: "%.1f kg", $0) } ?? "Körpergewicht")
                    Text("Reps: \(entry.difficulties.count)")
                    Text("Ø Schwierigkeit: \(self.averageDifficulty(of: entry))")
                    if let setType = self.setTypeDisplay(for: entry) {
                        Text(setType)
                    }
                }
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
            }
            Spacer()
        }
    }

    func exerciseName(for id: UUID) -> String {
        if let planName = self.planExercises.first(where: { $0.id == id })?.name { return planName }
        if let ex = ExerciseService.shared.getExercise(by: id) { return ex.name }
        return "Exercise: \(id.uuidString.prefix(6))…"
    }

    func setTypeDisplay(for entry: WorkoutSetEntry) -> String? {
        guard let exercise = self.planExercises.first(where: { $0.id == entry.planExerciseId }) else { return nil }
        guard entry.setIndex >= 0, entry.setIndex < exercise.sets.count else { return nil }
        return exercise.sets[entry.setIndex].setType.displayName
    }

    func averageDifficulty(of entry: WorkoutSetEntry) -> String {
        guard !entry.difficulties.isEmpty else { return "-" }
        let avg = Double(entry.difficulties.reduce(0, +)) / Double(entry.difficulties.count)
        return String(format: "%.1f", avg)
    }
}

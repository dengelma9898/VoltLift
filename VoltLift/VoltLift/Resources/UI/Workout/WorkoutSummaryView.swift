import SwiftUI

struct WorkoutSummaryView: View {
    enum CompletionType {
        case finished
        case canceled
    }

    let completion: CompletionType
    let entries: [WorkoutSetEntry]

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            Text(self.title)
                .font(DesignSystem.Typography.titleM)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)

            if self.entries.isEmpty {
                Text("Keine Einträge erfasst.")
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
            } else {
                List(self.entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Exercise: \(entry.planExerciseId.uuidString.prefix(6))…  •  Set \(entry.setIndex)")
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                        HStack(spacing: 8) {
                            Text("Gewicht: \(entry.weightKg.map { String(format: "%.1f kg", $0) } ?? "Körpergewicht")")
                            Text("Schwierigkeiten: \(entry.difficulties.map(String.init).joined(separator: ", "))")
                        }
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                }
                .listStyle(.plain)
            }
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

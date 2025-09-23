import SwiftUI

struct StrengthExerciseSet: Identifiable {
    enum SetType: String {
        case warmup = "mock_warmup"
        case normal = "mock_normal"
        case cooldown = "mock_cooldown"
    }

    let id: UUID
    let type: SetType
    let reps: Int
    let weightKg: Double
}

struct StrengthExercise: Identifiable {
    let id: UUID
    let name: String
    let sets: [StrengthExerciseSet]
}

struct StrengthPlanDetailView: View {
    let planName: String
    let mockExercises: [StrengthExercise]

    var body: some View {
        List {
            ForEach(self.mockExercises) { exercise in
                Section(exercise.name) {
                    ForEach(exercise.sets) { set in
                        HStack {
                            Text(self.localizedSetType(set.type))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundColor(.secondary)
                            Text("\(set.reps)x")
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0f kg", set.weightKg))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(self.planName)
        .safeAreaInset(edge: .bottom) {
            NavigationLink(destination: WorkoutSessionView(viewModel: MockWorkoutSessionViewModel(
                planName: self.planName,
                exercises: self.mockExercises
            ))) {
                Text(String(localized: "action.start"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(VLPrimaryButtonStyle())
            .padding(.horizontal, DesignSystem.Spacing.m)
            .padding(.bottom, DesignSystem.Spacing.m)
        }
    }

    private func localizedSetType(_ type: StrengthExerciseSet.SetType) -> String {
        switch type {
        case .warmup: String(localized: "set_type.warmup")
        case .normal: String(localized: "set_type.normal")
        case .cooldown: String(localized: "set_type.cooldown")
        }
    }

    private var totalExercises: Int { self.mockExercises.count }
    private var totalSets: Int { self.mockExercises.flatMap(\.sets).count }
}

#Preview {
    StrengthPlanDetailView(
        planName: "mock_Push Day",
        mockExercises: [
            StrengthExercise(
                id: UUID(),
                name: "mock_Bench Press",
                sets: [
                    StrengthExerciseSet(id: UUID(), type: .warmup, reps: 8, weightKg: 40),
                    StrengthExerciseSet(id: UUID(), type: .normal, reps: 6, weightKg: 60),
                    StrengthExerciseSet(id: UUID(), type: .normal, reps: 6, weightKg: 60),
                    StrengthExerciseSet(id: UUID(), type: .cooldown, reps: 8, weightKg: 40)
                ]
            ),
            StrengthExercise(
                id: UUID(),
                name: "mock_OHP",
                sets: [
                    StrengthExerciseSet(id: UUID(), type: .warmup, reps: 10, weightKg: 20),
                    StrengthExerciseSet(id: UUID(), type: .normal, reps: 6, weightKg: 35)
                ]
            )
        ]
    )
}

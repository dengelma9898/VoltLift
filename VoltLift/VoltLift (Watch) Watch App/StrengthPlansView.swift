import Foundation
import SwiftUI

struct StrengthPlan: Identifiable {
    let id: UUID
    let name: String
    let muscleGroups: [String]
    let exerciseCount: Int
}

struct StrengthPlansView: View {
    private let mockPlans: [StrengthPlan] = [
        StrengthPlan(
            id: UUID(),
            name: "mock_Strength Base",
            muscleGroups: ["mock_chest", "mock_back", "mock_legs"],
            exerciseCount: 9
        ),
        StrengthPlan(
            id: UUID(),
            name: "mock_Push Day",
            muscleGroups: ["mock_chest", "mock_shoulders", "mock_triceps"],
            exerciseCount: 7
        ),
        StrengthPlan(
            id: UUID(),
            name: "mock_Pull Day",
            muscleGroups: ["mock_back", "mock_biceps", "mock_rearDelts"],
            exerciseCount: 8
        )
    ]

    var body: some View {
        List {
            ForEach(self.mockPlans, id: \.id) { plan in
                NavigationLink {
                    StrengthPlanDetailView(
                        planName: plan.name,
                        mockExercises: [
                            StrengthExercise(
                                id: UUID(),
                                name: "mock_Squat",
                                sets: [
                                    StrengthExerciseSet(id: UUID(), type: .warmup, reps: 8, weightKg: 40),
                                    StrengthExerciseSet(id: UUID(), type: .normal, reps: 5, weightKg: 80)
                                ]
                            ),
                            StrengthExercise(
                                id: UUID(),
                                name: "mock_RDL",
                                sets: [
                                    StrengthExerciseSet(id: UUID(), type: .normal, reps: 8, weightKg: 60)
                                ]
                            )
                        ]
                    )
                } label: {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text(plan.name)
                            .font(DesignSystem.Typography.titleS)

                        Text(plan.muscleGroups.joined(separator: ", "))
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.secondary)

                        Text(String(format: String(localized: "plans.exercise_count_format"), plan.exerciseCount))
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, DesignSystem.Spacing.s)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(String(localized: "title.strength_plans"))
    }
}

#Preview {
    StrengthPlansView()
}

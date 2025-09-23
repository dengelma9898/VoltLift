import SwiftUI

struct WorkoutSessionView: View {
    @StateObject var viewModel: MockWorkoutSessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            if self.viewModel.isFinished {
                WorkoutFinishView(planName: self.viewModel.planName)
            } else if self.viewModel.isResting {
                VStack(spacing: DesignSystem.Spacing.m) {
                    Text(String(localized: "session.rest_title"))
                        .font(DesignSystem.Typography.titleS)
                    Text("\(self.viewModel.restRemainingSeconds)s")
                        .font(DesignSystem.Typography.titleL)
                    Button(String(localized: "session.skip_rest")) { self.viewModel.skipRest() }
                        .buttonStyle(VLPrimaryButtonStyle())
                }
            } else {
                List {
                    Section(self.viewModel.currentName) {
                        Picker(String(localized: "session.reps"), selection: self.$viewModel.reps) {
                            ForEach(1 ... 50, id: \.self) { repsValue in
                                Text("\(repsValue)").tag(repsValue)
                            }
                        }
                        .pickerStyle(.navigationLink)

                        Picker(String(localized: "session.weight"), selection: self.$viewModel.weightKg) {
                            ForEach(0 ..< 601, id: \.self) { idx in
                                let val = Double(idx) * 0.5
                                Text(String(format: "%.1f kg", val)).tag(val)
                            }
                        }
                        .pickerStyle(.navigationLink)

                        Picker(String(localized: "session.difficulty"), selection: self.$viewModel.difficulty) {
                            ForEach(MockWorkoutSessionViewModel.Difficulty.allCases) { difficultyCase in
                                Text(difficultyCase.label).tag(difficultyCase)
                            }
                        }
                        .pickerStyle(.navigationLink)

                        Button(String(localized: "session.confirm_exercise")) { self.viewModel.confirmCurrent() }
                            .buttonStyle(VLPrimaryButtonStyle())
                        Button(String(localized: "action.cancel")) { self.viewModel.cancelWorkout()
                            self.dismiss()
                        }
                        .tint(.red)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "title.workout"))
    }
}

struct WorkoutFinishView: View {
    let planName: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.m) {
            Text(String(localized: "finish.title"))
                .font(DesignSystem.Typography.titleS)
            Text(self.planName)
            Button(String(localized: "finish.done_to_home")) { self.dismiss() }
                .buttonStyle(VLPrimaryButtonStyle())
        }
        .navigationTitle(String(localized: "finish.title"))
    }
}

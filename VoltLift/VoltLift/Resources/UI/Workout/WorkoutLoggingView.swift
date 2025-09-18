import SwiftUI

struct WorkoutLoggingView: View {
    @StateObject private var viewModel = WorkoutLoggingViewModel()

    let planExerciseId: UUID
    let setIndex: Int
    let usesEquipment: Bool
    @State private var weight: Double = 0
    @State private var reps: Int = 0
    @State private var difficulties: [Int] = []

    var body: some View {
        Form {
            if self.usesEquipment {
                Stepper(value: self.$weight, in: 0 ... 1_000, step: 0.5) {
                    Text("Gewicht: \(String(format: "%.1f", self.weight)) kg")
                }
            } else {
                Text("Körpergewicht")
                    .foregroundColor(.secondary)
            }

            Stepper(value: self.$reps, in: 0 ... 200) {
                Text("Wiederholungen: \(self.reps)")
            }

            if self.reps > 0 {
                Section("Schwierigkeit je Wiederholung (1–10)") {
                    ForEach(0 ..< self.reps, id: \.self) { i in
                        Picker("Wdh. \(i + 1)", selection: Binding(
                            get: { self.difficulties.indices.contains(i) ? self.difficulties[i] : 1 },
                            set: { newValue in
                                if self.difficulties.count <= i { self.difficulties.append(contentsOf: Array(
                                    repeating: 1,
                                    count: i - self.difficulties.count + 1
                                )) }
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

            Button("Speichern") {
                if self.usesEquipment {
                    self.viewModel.recordWeight(
                        planExerciseId: self.planExerciseId,
                        setIndex: self.setIndex,
                        weightKg: self.weight,
                        exerciseUsesEquipment: true
                    )
                }
                self.viewModel.recordDifficulties(
                    planExerciseId: self.planExerciseId,
                    setIndex: self.setIndex,
                    difficulties: self.difficulties,
                    reps: self.reps
                )
            }
        }
        .navigationTitle("Satz erfassen")
        .alert(item: Binding(
            get: { self.viewModel.lastError.map { LocalizedErrorWrapper(message: $0) } },
            set: { _ in self.viewModel.lastError = nil }
        )) { wrapper in
            Alert(title: Text("Fehler"), message: Text(wrapper.message), dismissButton: .default(Text("OK")))
        }
    }
}

private struct LocalizedErrorWrapper: Identifiable {
    let id = UUID()
    let message: String
}

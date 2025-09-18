import SwiftUI

struct PlanEditorView: View {
    @StateObject private var viewModel: PlanEditorViewModel

    init(plan: PlanDraft) {
        _viewModel = StateObject(wrappedValue: PlanEditorViewModel(plan: plan))
    }

    var body: some View {
        List {
            ForEach(self.viewModel.plan.exercises) { exercise in
                Section(exercise.displayName) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Satz \(index + 1)")
                            Spacer()
                            Text("\(set.reps)x")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Plan bearbeiten")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Speichern") { self.viewModel.savePlan() }
            }
        }
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

import SwiftUI

struct PlanDetailView: View {
    let plan: WorkoutPlanData
    var onStart: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @EnvironmentObject private var userPreferencesService: UserPreferencesService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    private var exerciseCountText: String {
        "\(self.plan.exerciseCount) exercises"
    }

    var body: some View {
        List {
            self.headerSection
            self.exercisesSection
        }
        .scrollContentBackground(.hidden)
        .vlBrandBackground()
        .navigationTitle("Plan")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Rename", systemImage: "pencil") {
                        // Optional: Rename flow (später)
                    }
                    Button("Duplicate", systemImage: "plus.square.on.square") {
                        Task { await self.duplicatePlan() }
                    }
                    Divider()
                    Button(role: .destructive) {
                        self.showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: DesignSystem.Spacing.m) {
                Button {
                    self.onEdit?()
                } label: {
                    VLButtonLabel("Edit Plan", style: .secondary)
                }

                Button {
                    self.onStart?()
                } label: {
                    VLButtonLabel("Start Workout", style: .primary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .alert("Delete this plan?", isPresented: self.$showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                self.onDelete?()
                self.dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var headerSection: some View {
        let relativeFormatter = RelativeDateTimeFormatter()
        return Section {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.plan.name)
                        .font(DesignSystem.Typography.titleM)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Text(self.exerciseCountText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    if let last = self.plan.lastUsedDate {
                        let relative = relativeFormatter.localizedString(for: last, relativeTo: Date())
                        Text("Last used: " + relative)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                }
                Spacer()
            }
        }
    }

    private var exercisesSection: some View {
        Section("Exercises") {
            ForEach(self.plan.exercises, id: \.id) { exercise in
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Text("\(exercise.totalSets) x \(exercise.averageReps)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
            }
        }
    }

    private func duplicatePlan() async {
        // Simple duplicate by saving with a new UUID and name suffix
        let dup = WorkoutPlanData(
            id: UUID(),
            name: self.plan.name + " Copy",
            exercises: self.plan.exercises,
            createdDate: Date(),
            lastUsedDate: nil
        )
        do {
            try await self.userPreferencesService.savePlan(dup)
        } catch {
            // Error surfaced via service.lastError
        }
    }
}

import SwiftUI

struct PlanDetailView: View {
    let plan: WorkoutPlanData
    var onStart: (() -> Void)?
    var onEdit: (() -> Void)?
    var onDelete: (() -> Void)?

    @EnvironmentObject private var userPreferencesService: UserPreferencesService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false
    @State private var goToEditor = false
    @State private var showRenameSheet = false
    @State private var pendingName: String = ""
    @State private var overrideName: String?
    @State private var goToSession = false
    @State private var summaries: [WorkoutSessionSummary] = []
    @State private var isLoadingHistory = false
    @State private var infoExercise: ExerciseData?

    private var exerciseCountText: String {
        "\(self.plan.exerciseCount) exercises"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                self.headerCard
                self.exercisesList
                self.insightsEntry
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .vlBrandBackground()
        .navigationTitle("Plan")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Rename", systemImage: "pencil") {
                        self.pendingName = self.overrideName ?? self.plan.name
                        self.showRenameSheet = true
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
                Button { self.goToEditor = true } label: { VLButtonLabel("Edit Plan", style: .secondary) }
                Button {
                    // Starte neue Session für die erste Übung dieses Plans
                    self.goToSession = true
                } label: { VLButtonLabel("Start Workout", style: .primary) }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
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
        .background(
            NavigationLink(
                "",
                destination: PlanEditorView(plan: self.mapToDraft(self.plan))
                    .environmentObject(self.userPreferencesService),
                isActive: self.$goToEditor
            )
            .hidden()
        )
        .background(
            NavigationLink(isActive: self.$goToSession) {
                if self.plan.exercises.isEmpty {
                    Text("No exercises in plan")
                } else {
                    WorkoutSessionView(plan: self.plan)
                }
            } label: { EmptyView() }
                .hidden()
        )
        .sheet(isPresented: self.$showRenameSheet) {
            NavigationStack {
                Form {
                    Section("Name") {
                        TextField("Plan name", text: self.$pendingName)
                    }
                }
                .navigationTitle("Rename Plan")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { self.showRenameSheet = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let trimmed = self.pendingName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { self.showRenameSheet = false
                                return
                            }
                            Task { @MainActor in
                                do {
                                    try await self.userPreferencesService.renamePlan(self.plan.id, newName: trimmed)
                                    self.overrideName = trimmed
                                    self.showRenameSheet = false
                                } catch {
                                    self.showRenameSheet = false
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: self.$infoExercise) { selected in
            self.exerciseInfoView(selected)
        }
    }

    private var headerCard: some View {
        let relativeFormatter = RelativeDateTimeFormatter()
        return VLGlassCard {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(self.overrideName ?? self.plan.name)
                        .font(DesignSystem.Typography.titleM)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Text(self.exerciseCountText)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    Text("Created: " + self.formatCreated(self.plan.createdDate))
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

    private var exercisesList: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Exercises")
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)

            ForEach(self.plan.exercises, id: \.id) { exercise in
                VLGlassCard {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(exercise.name)
                                .foregroundColor(DesignSystem.ColorRole.textPrimary)
                            Button { self.infoExercise = exercise } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            }
                            Spacer()
                        }
                        Text(self.exerciseSubtitle(exercise))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                }
            }
        }
    }

    private var insightsEntry: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Verlauf & Insights")
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
            NavigationLink {
                PlanInsightsView(plan: self.plan)
            } label: {
                VLGlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Öffne Insights")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.ColorRole.textPrimary)
                            Text("Verlauf, Volumen, Trends und mehr")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
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

    private func mapToDraft(_ plan: WorkoutPlanData) -> PlanDraft {
        PlanDraft(
            id: plan.id,
            name: plan.name,
            exercises: plan.exercises.map { exercise in
                PlanExerciseDraft(
                    id: exercise.id,
                    referenceExerciseId: exercise.id.uuidString,
                    displayName: exercise.name,
                    allowsUnilateral: false,
                    sets: exercise.sets.map { set in
                        let mappedType: ExerciseSetType = switch set.setType {
                        case .warmUp: .warmUp
                        case .normal: .normal
                        case .coolDown: .coolDown
                        }
                        return PlanSetDraft(reps: set.reps, setType: mappedType, side: .both, comment: nil)
                    }
                )
            }
        )
    }

    private func formatCreated(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }

    // MARK: - Summaries

    private func exerciseSubtitle(_ exercise: ExerciseData) -> String {
        let warm = exercise.sets.count(where: { $0.setType == .warmUp })
        let normal = exercise.sets.count(where: { $0.setType == .normal })
        let cool = exercise.sets.count(where: { $0.setType == .coolDown })
        var parts: [String] = []
        if warm > 0 { parts.append("Warm-up: \(warm)") }
        if normal > 0 { parts.append("Working: \(normal)") }
        if cool > 0 { parts.append("Cool-down: \(cool)") }

        let reps = exercise.sets.map(\.reps)
        if let minR = reps.min(), let maxR = reps.max() {
            let repsStr = (minR == maxR) ? "Reps: \(minR)" : "Reps: \(minR)–\(maxR) (avg \(exercise.averageReps))"
            parts.append(repsStr)
        }

        parts.append("Rest: \(exercise.restTime)s")
        return parts.joined(separator: "  •  ")
    }

    // MARK: - Exercise Info Sheet

    @ViewBuilder
    private func exerciseInfoView(_ exercise: ExerciseData) -> some View {
        let info = self.enhancedExercise(for: exercise)
        NavigationStack {
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

    private func enhancedExercise(for exercise: ExerciseData) -> Exercise? {
        if let exerciseExact = ExerciseService.shared.getExercise(by: exercise.id) { return exerciseExact }
        // Fallback: Name-Match (case-insensitive)
        return ExerciseService.shared.getAllExercises().first { $0.name.lowercased() == exercise.name.lowercased() }
    }
}

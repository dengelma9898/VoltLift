import SwiftUI

struct ExerciseDetailView: View {
    let exercise: Exercise
    let onAddToWorkout: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xl) {
                    // Header Section
                    self.headerSection

                    // Description Section
                    self.descriptionSection

                    // Instructions Section
                    self.instructionsSection

                    // Safety Tips Section
                    self.safetyTipsSection

                    // Muscle Groups Section
                    self.muscleGroupsSection

                    // Variations Section
                    if !self.exercise.variations.isEmpty {
                        self.variationsSection
                    }

                    // Add to Workout Button
                    self.addToWorkoutButton
                }
                .padding(DesignSystem.Spacing.l)
            }
            .background(DesignSystem.ColorRole.background)
            .navigationTitle(self.exercise.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        self.dismiss()
                    }
                    .foregroundColor(DesignSystem.ColorRole.primary)
                }
            }
        }
        .vlBrandBackground()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                HStack {
                    Image(systemName: self.exercise.sfSymbolName)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(DesignSystem.ColorRole.primary)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        VLThemedText(
                            self.exercise.name,
                            font: DesignSystem.Typography.titleM,
                            color: DesignSystem.ColorRole.textPrimary
                        )

                        HStack {
                            self.difficultyBadge
                            self.muscleGroupBadge
                        }
                    }

                    Spacer()
                }

                if !self.exercise.requiredEquipment.isEmpty {
                    self.equipmentSection
                }
            }
        }
    }

    private var difficultyBadge: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            Image(systemName: self.difficultyIcon)
                .font(.caption)
                .foregroundColor(self.difficultyColor)

            Text(self.exercise.difficulty.rawValue)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(self.difficultyColor)
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                .fill(self.difficultyColor.opacity(0.15))
        )
    }

    private var muscleGroupBadge: some View {
        HStack(spacing: DesignSystem.Spacing.s) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.caption)
                .foregroundColor(DesignSystem.ColorRole.secondary)

            Text(self.exercise.muscleGroup.rawValue)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.s)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.pill)
                .fill(DesignSystem.ColorRole.secondary.opacity(0.15))
        )
    }

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .font(.caption)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)

                VLThemedText(
                    "Required Equipment",
                    font: DesignSystem.Typography.caption.weight(.semibold),
                    color: DesignSystem.ColorRole.textSecondary
                )
            }

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: DesignSystem.Spacing.s)
            ], spacing: DesignSystem.Spacing.s) {
                ForEach(Array(self.exercise.requiredEquipment), id: \.self) { equipment in
                    HStack(spacing: DesignSystem.Spacing.s) {
                        Image(systemName: self.equipmentIcon(for: equipment))
                            .font(.caption2)
                            .foregroundColor(DesignSystem.ColorRole.primary)

                        Text(equipment)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.s)
                            .fill(DesignSystem.ColorRole.primary.opacity(0.1))
                    )
                }
            }
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                self.sectionHeader(
                    title: "Description",
                    icon: "text.alignleft"
                )

                VLThemedText(
                    self.exercise.description,
                    font: DesignSystem.Typography.body,
                    color: DesignSystem.ColorRole.textPrimary
                )
            }
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                self.sectionHeader(
                    title: "Instructions",
                    icon: "list.number"
                )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    ForEach(Array(self.exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.m) {
                            Text("\(index + 1)")
                                .font(DesignSystem.Typography.callout.weight(.semibold))
                                .foregroundColor(DesignSystem.ColorRole.primary)
                                .frame(width: 24, height: 24)
                                .background(
                                    Circle()
                                        .fill(DesignSystem.ColorRole.primary.opacity(0.15))
                                )

                            VLThemedText(
                                instruction,
                                font: DesignSystem.Typography.body,
                                color: DesignSystem.ColorRole.textPrimary
                            )

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Safety Tips Section

    private var safetyTipsSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                self.sectionHeader(
                    title: "Safety Tips",
                    icon: "exclamationmark.shield"
                )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                    ForEach(Array(self.exercise.safetyTips.enumerated()), id: \.offset) { _, tip in
                        HStack(alignment: .top, spacing: DesignSystem.Spacing.m) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.callout)
                                .foregroundColor(DesignSystem.ColorRole.success)

                            VLThemedText(
                                tip,
                                font: DesignSystem.Typography.body,
                                color: DesignSystem.ColorRole.textPrimary
                            )

                            Spacer()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Muscle Groups Section

    private var muscleGroupsSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                self.sectionHeader(
                    title: "Target Muscles",
                    icon: "figure.strengthtraining.traditional"
                )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                    // Primary muscles
                    self.muscleGroupList(
                        title: "Primary",
                        muscles: self.exercise.targetMuscles,
                        color: DesignSystem.ColorRole.primary
                    )

                    // Secondary muscles
                    if !self.exercise.secondaryMuscles.isEmpty {
                        self.muscleGroupList(
                            title: "Secondary",
                            muscles: self.exercise.secondaryMuscles,
                            color: DesignSystem.ColorRole.secondary
                        )
                    }
                }
            }
        }
    }

    private func muscleGroupList(title: String, muscles: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            VLThemedText(
                title,
                font: DesignSystem.Typography.callout.weight(.semibold),
                color: DesignSystem.ColorRole.textSecondary
            )

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 140), spacing: DesignSystem.Spacing.s)
            ], spacing: DesignSystem.Spacing.s) {
                ForEach(muscles, id: \.self) { muscle in
                    HStack(spacing: DesignSystem.Spacing.s) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)

                        Text(muscle)
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.s)
                            .fill(color.opacity(0.1))
                    )
                }
            }
        }
    }

    // MARK: - Variations Section

    private var variationsSection: some View {
        VLGlassCard {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                self.sectionHeader(
                    title: "Variations",
                    icon: "arrow.triangle.branch"
                )

                VStack(spacing: DesignSystem.Spacing.m) {
                    ForEach(self.exercise.variations) { variation in
                        self.variationCard(variation)
                    }
                }
            }
        }
    }

    private func variationCard(_ variation: ExerciseVariation) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: variation.sfSymbolName)
                .font(.title3)
                .foregroundColor(self.variationColor(for: variation.difficultyModifier))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                HStack {
                    VLThemedText(
                        variation.name,
                        font: DesignSystem.Typography.callout.weight(.semibold),
                        color: DesignSystem.ColorRole.textPrimary
                    )

                    Spacer()

                    self.difficultyIndicator(for: variation.difficultyModifier)
                }

                VLThemedText(
                    variation.description,
                    font: DesignSystem.Typography.caption,
                    color: DesignSystem.ColorRole.textSecondary
                )
            }
        }
        .padding(DesignSystem.Spacing.m)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.m)
                .fill(self.variationColor(for: variation.difficultyModifier).opacity(0.08))
        )
    }

    // MARK: - Add to Workout Button

    private var addToWorkoutButton: some View {
        VLButton("Add to Workout", style: .primary) {
            self.onAddToWorkout()
            self.dismiss()
        }
        .padding(.top, DesignSystem.Spacing.l)
    }

    // MARK: - Helper Views

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(DesignSystem.ColorRole.primary)

            VLThemedText(
                title,
                font: DesignSystem.Typography.titleS,
                color: DesignSystem.ColorRole.textPrimary
            )

            Spacer()
        }
    }

    private func difficultyIndicator(for modifier: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0 ..< 3, id: \.self) { index in
                let isActive = (modifier == -1 && index == 0) ||
                    (modifier == 0 && index == 1) ||
                    (modifier == 1 && index == 2)

                Circle()
                    .fill(isActive ? self.variationColor(for: modifier) : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    // MARK: - Helper Properties

    private var difficultyIcon: String {
        switch self.exercise.difficulty {
        case .beginner:
            "1.circle.fill"
        case .intermediate:
            "2.circle.fill"
        case .advanced:
            "3.circle.fill"
        }
    }

    private var difficultyColor: Color {
        switch self.exercise.difficulty {
        case .beginner:
            DesignSystem.ColorRole.success
        case .intermediate:
            DesignSystem.ColorRole.warning
        case .advanced:
            DesignSystem.ColorRole.danger
        }
    }

    private func variationColor(for modifier: Int) -> Color {
        switch modifier {
        case -1:
            DesignSystem.ColorRole.success
        case 0:
            DesignSystem.ColorRole.secondary
        case 1:
            DesignSystem.ColorRole.warning
        default:
            DesignSystem.ColorRole.secondary
        }
    }

    private func equipmentIcon(for equipment: String) -> String {
        switch equipment.lowercased() {
        case let eq where eq.contains("dumbbell"):
            "dumbbell"
        case let eq where eq.contains("barbell"):
            "dumbbell"
        case let eq where eq.contains("kettlebell"):
            "circle"
        case let eq where eq.contains("band"):
            "bolt.horizontal.circle"
        case let eq where eq.contains("bench"):
            "rectangle.portrait"
        case let eq where eq.contains("pull"):
            "figure.climbing"
        case let eq where eq.contains("cable"):
            "cable.connector"
        default:
            "wrench.and.screwdriver"
        }
    }
}

// MARK: - Preview

#Preview {
    ExerciseDetailView(
        exercise: Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "A fundamental upper body exercise that targets the chest, shoulders, and triceps using body weight.",
            instructions: [
                "Start in a plank position with hands shoulder-width apart",
                "Lower your body until your chest nearly touches the ground",
                "Push back up to the starting position",
                "Keep your core engaged throughout the movement"
            ],
            safetyTips: [
                "Maintain a straight line from head to heels",
                "Don't let your hips sag or pike up",
                "Control the descent - don't drop down quickly"
            ],
            targetMuscles: ["Pectoralis Major", "Anterior Deltoid", "Triceps Brachii"],
            secondaryMuscles: ["Core", "Serratus Anterior"],
            difficulty: .beginner,
            variations: [
                ExerciseVariation(
                    name: "Knee Push-up",
                    description: "Easier variation performed on knees",
                    difficultyModifier: -1,
                    sfSymbolName: "figure.strengthtraining.traditional"
                ),
                ExerciseVariation(
                    name: "Diamond Push-up",
                    description: "Hands form diamond shape for increased triceps focus",
                    difficultyModifier: 1,
                    sfSymbolName: "diamond"
                )
            ],
            sfSymbolName: "figure.strengthtraining.traditional"
        ),
        onAddToWorkout: {}
    )
    .preferredColorScheme(.dark)
}

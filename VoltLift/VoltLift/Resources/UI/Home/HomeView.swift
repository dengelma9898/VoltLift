import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                HStack(spacing: DesignSystem.Spacing.m) {
                    Circle()
                        .fill(DesignSystem.Gradient.primary)
                        .frame(width: 44, height: 44)
                        .overlay(Image(systemName: "bolt.fill").foregroundColor(.white))
                    VLWordmark(size: .l)
                    Spacer()
                }
                .padding(.top, DesignSystem.Spacing.l)

                Text("Ready to energize your day?")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(DesignSystem.ColorRole.textSecondary)

                // Stats Row
                HStack(spacing: DesignSystem.Spacing.m) {
                    VLStatCard(value: "15", label: "Workouts")
                    VLStatCard(value: "42", label: "Activities")
                    VLStatCard(value: "7", label: "Day Streak")
                }

                // Actions
                VStack(spacing: DesignSystem.Spacing.l) {
                    NavigationLink {
                        WorkoutSetupView()
                    } label: {
                        VLActionCard(
                            icon: "dumbbell.fill",
                            title: "Start Workout",
                            subtitle: "Build strength & power",
                            gradient: DesignSystem.Gradient.bluePurple
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        OutdoorActivityView()
                    } label: {
                        VLActionCard(
                            icon: "tree.fill",
                            title: "Outdoor Activity",
                            subtitle: "Connect with nature",
                            gradient: DesignSystem.Gradient.tealBlue
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        OutdoorHistoryView()
                    } label: {
                        VLActionCard(
                            icon: "map.fill",
                            title: String(localized: "title.outdoor_history"),
                            subtitle: String(localized: "subtitle.outdoor_history"),
                            gradient: DesignSystem.Gradient.tealBlue
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Placeholder for sections
                VLGlassCard {
                    Text("Today's Progress")
                        .font(DesignSystem.Typography.titleS)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .vlBrandBackground()
    }
}

private struct VLStatCard: View {
    let value: String
    let label: String

    var body: some View {
        VLGlassCard {
            VStack(spacing: 4) {
                Text(self.value)
                    .font(DesignSystem.Typography.titleM)
                    .foregroundColor(.white)
                Text(self.label)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct VLActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            Circle()
                .fill(self.gradient)
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: self.icon).foregroundColor(.white))

            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(DesignSystem.Typography.titleS)
                    .foregroundColor(.white)
                Text(self.subtitle)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(DesignSystem.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10))
        )
    }
}

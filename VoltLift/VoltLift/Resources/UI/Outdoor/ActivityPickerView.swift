import SwiftUI

enum ActivityType: CaseIterable, Identifiable, Equatable {
    case running
    case biking
    case hiking

    var id: String { self.title }

    var title: String {
        switch self {
        case .running: String(localized: "activity.running")
        case .biking: String(localized: "activity.biking")
        case .hiking: String(localized: "activity.hiking")
        }
    }

    var symbolName: String {
        switch self {
        case .running: "figure.run"
        case .biking: "bicycle"
        case .hiking: "figure.hiking"
        }
    }

    static var defaultSet: [ActivityType] { [.running, .biking, .hiking] }
}

struct ActivityPickerView: View {
    let activities: [ActivityType]
    @Binding var selected: ActivityType
    var onSelect: ((ActivityType) -> Void)?

    var body: some View {
        VLGlassCard {
            HStack(spacing: DesignSystem.Spacing.m) {
                ForEach(self.activities) { activity in
                    Button(action: {
                        self.selected = activity
                        self.onSelect?(activity)
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: activity.symbolName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(self.iconColor(isSelected: activity == self.selected))
                            Text(activity.title)
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(self.textColor(isSelected: activity == self.selected))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.m, style: .continuous)
                                .fill(self.background(isSelected: activity == self.selected))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.m, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func background(isSelected: Bool) -> some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(DesignSystem.Gradient.tealBlue)
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [Color.white.opacity(0.06), Color.white.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        }
    }

    private func iconColor(isSelected: Bool) -> Color {
        isSelected ? .white : DesignSystem.ColorRole.textPrimary
    }

    private func textColor(isSelected: Bool) -> Color {
        isSelected ? .white : DesignSystem.ColorRole.textSecondary
    }
}

#Preview {
    @Previewable @State var selected: ActivityType = .running
    return ActivityPickerView(activities: ActivityType.defaultSet, selected: $selected)
        .padding()
        .preferredColorScheme(.dark)
        .background(DesignSystem.ColorRole.background)
}

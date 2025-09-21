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
        HStack(spacing: DesignSystem.Spacing.m) {
            ForEach(self.activities) { activity in
                Button(action: {
                    self.selected = activity
                    self.onSelect?(activity)
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: activity.symbolName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text(activity.title)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.vertical, DesignSystem.Spacing.m)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                            .fill(DesignSystem.Gradient.tealBlue)
                    )
                    .shadow(
                        color: DesignSystem.Shadow.smallColor,
                        radius: DesignSystem.Shadow.smallRadius,
                        y: DesignSystem.Shadow.smallY
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(activity.title))
            }
        }
    }
}

#Preview {
    @Previewable @State var selected: ActivityType = .running
    return ActivityPickerView(activities: ActivityType.defaultSet, selected: $selected)
        .padding()
        .preferredColorScheme(.dark)
        .background(DesignSystem.ColorRole.background)
}

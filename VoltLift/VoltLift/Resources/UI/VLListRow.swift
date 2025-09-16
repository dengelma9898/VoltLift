import SwiftUI

public struct VLListRow<Leading: View, Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let leading: Leading
    private let trailing: Trailing

    public init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: DesignSystem.Spacing.m) {
            self.leading

            VStack(alignment: .leading, spacing: 2) {
                Text(self.title)
                    .font(DesignSystem.Typography.body.weight(.semibold))
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
            }

            Spacer(minLength: DesignSystem.Spacing.l)

            self.trailing
        }
        .padding(.vertical, DesignSystem.Spacing.m)
    }
}


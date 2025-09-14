import SwiftUI

public struct VLButton: View {
    public enum Style {
        case primary
        case secondary
        case destructive
    }

    private let title: String
    private let style: Style
    private let action: () -> Void

    public init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    public var body: some View {
        self.styledButton()
            .accessibilityLabel(Text(self.title))
    }

    @ViewBuilder
    private func styledButton() -> some View {
        if self.style == .primary {
            Button(self.title) { self.action() }
                .buttonStyle(VLPrimaryButtonStyle())
        } else if self.style == .secondary {
            Button(self.title) { self.action() }
                .buttonStyle(VLSecondaryButtonStyle())
        } else {
            Button(self.title) { self.action() }
                .buttonStyle(VLDestructiveButtonStyle())
        }
    }
}

public struct VLButtonLabel: View {
    public enum Style {
        case primary
        case secondary
        case destructive
    }

    private let title: String
    private let style: Style

    public init(_ title: String, style: Style = .primary) {
        self.title = title
        self.style = style
    }

    public var body: some View {
        self.styledLabel()
            .accessibilityLabel(Text(self.title))
    }

    @ViewBuilder
    private func styledLabel() -> some View {
        switch self.style {
        case .primary:
            Text(self.title)
                .font(DesignSystem.Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                        .fill(DesignSystem.Gradient.primary)
                )
                .shadow(
                    color: DesignSystem.Shadow.smallColor,
                    radius: DesignSystem.Shadow.smallRadius,
                    y: DesignSystem.Shadow.smallY
                )

        case .secondary:
            Text(self.title)
                .font(DesignSystem.Typography.body.weight(.semibold))
                .foregroundColor(DesignSystem.ColorRole.primary)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                        .fill(DesignSystem.ColorRole.primary.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                        .strokeBorder(DesignSystem.ColorRole.primary.opacity(0.35))
                )

        case .destructive:
            Text(self.title)
                .font(DesignSystem.Typography.body.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.m)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                        .fill(DesignSystem.ColorRole.danger)
                )
                .shadow(
                    color: DesignSystem.Shadow.smallColor,
                    radius: DesignSystem.Shadow.smallRadius,
                    y: DesignSystem.Shadow.smallY
                )
        }
    }
}

private struct VLDestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                    .fill(DesignSystem.ColorRole.danger)
            )
            .shadow(
                color: DesignSystem.Shadow.smallColor,
                radius: DesignSystem.Shadow.smallRadius,
                y: DesignSystem.Shadow.smallY
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

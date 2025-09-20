import SwiftUI

public struct VLIconButtonStyle: ButtonStyle {
    private let size: CGFloat

    public init(size: CGFloat = 36) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(DesignSystem.ColorRole.primary)
            .frame(width: self.size, height: self.size)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                    .fill(DesignSystem.ColorRole.primary.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                    .strokeBorder(DesignSystem.ColorRole.primary.opacity(0.35))
            )
            .shadow(
                color: DesignSystem.Shadow.smallColor,
                radius: DesignSystem.Shadow.smallRadius,
                y: DesignSystem.Shadow.smallY
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

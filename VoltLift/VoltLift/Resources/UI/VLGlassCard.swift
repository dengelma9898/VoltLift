import SwiftUI

public struct VLGlassCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        self.content
            .padding(DesignSystem.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                DesignSystem.ColorRole.textPrimary.opacity(0.06),
                                DesignSystem.ColorRole.textPrimary.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                    .strokeBorder(DesignSystem.ColorRole.textPrimary.opacity(0.10))
            )
            .shadow(
                color: DesignSystem.Shadow.smallColor,
                radius: DesignSystem.Shadow.smallRadius,
                y: DesignSystem.Shadow.smallY
            )
    }
}

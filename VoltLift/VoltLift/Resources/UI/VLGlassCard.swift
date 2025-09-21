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
            .background(DesignSystem.Glass.backgroundMaterial)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Glass.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Glass.tintStart, DesignSystem.Glass.tintEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Glass.cornerRadius, style: .continuous)
                    .strokeBorder(DesignSystem.Glass.borderColor, lineWidth: DesignSystem.Glass.borderWidth)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Glass.cornerRadius, style: .continuous)
                    .stroke(DesignSystem.Glass.highlightColor, lineWidth: DesignSystem.Glass.highlightWidth)
                    .blendMode(.overlay)
                    .mask(
                        LinearGradient(
                            colors: [Color.white, Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Glass.cornerRadius, style: .continuous))
            .shadow(
                color: DesignSystem.Shadow.smallColor,
                radius: DesignSystem.Shadow.smallRadius,
                y: DesignSystem.Shadow.smallY
            )
    }
}

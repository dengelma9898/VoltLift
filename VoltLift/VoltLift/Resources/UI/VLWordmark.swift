import SwiftUI

public struct VLWordmark: View {
    public enum Size { case l, xl }

    private let size: Size

    public init(size: Size = .xl) {
        self.size = size
    }

    public var body: some View {
        let baseFont: Font = self.size == .xl ? DesignSystem.Typography.titleXL : DesignSystem.Typography.titleL

        Text("Volt")
            .font(baseFont)
            .foregroundStyle(DesignSystem.ColorRole.textPrimary)
            .kerning(-0.5)
            .overlay(alignment: .trailing) {
                Text("Lift")
                    .font(baseFont)
                    .foregroundStyle(DesignSystem.Gradient.primary)
                    .kerning(-0.5)
                    .offset(x: 0)
            }
            .accessibilityLabel(Text("VoltLift"))
    }
}

import SwiftUI

public struct VLWordmark: View {
    public enum Size { case l, xl }

    private let size: Size

    public init(size: Size = .xl) {
        self.size = size
    }

    public var body: some View {
        let baseFont: Font = self.size == .xl ? DesignSystem.Typography.titleXL : DesignSystem.Typography.titleL

        let volt = Text("Volt")
            .font(baseFont)
            .foregroundStyle(DesignSystem.ColorRole.textPrimary)

        let lift = Text("Lift")
            .font(baseFont)
            .foregroundStyle(DesignSystem.Gradient.primary)

        (volt + lift)
            .kerning(-0.5)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .allowsTightening(true)
            .layoutPriority(1)
            .accessibilityLabel(Text("VoltLift"))
    }
}

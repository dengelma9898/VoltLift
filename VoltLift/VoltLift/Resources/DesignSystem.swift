import SwiftUI

public enum DesignSystem {
    public enum ColorRole {
        public static var primary: Color { Color("VLPrimary") }
        public static var secondary: Color { Color("VLSecondary") }
        // Brand background (aus Assets, Light/Dark via ColorSet)
        public static var background: Color { Color("VLBackground") }
        public static var surface: Color { Color("VLSurface") }
        // Textfarben aus Assets (Light/Dark abgestimmt)
        public static var textPrimary: Color { Color("VLTextPrimary") }
        public static var textSecondary: Color { Color("VLTextSecondary") }
        public static var success: Color { Color("VLSuccess") }
        public static var warning: Color { Color("VLWarning") }
        public static var danger: Color { Color("VLDanger") }
    }

    public enum Typography {
        public static var titleXL: Font { .largeTitle.weight(.bold) }
        public static var titleL: Font { .title.weight(.bold) }
        public static var titleM: Font { .title2.weight(.semibold) }
        public static var titleS: Font { .title3.weight(.semibold) }
        public static var body: Font { .body }
        public static var callout: Font { .callout }
        public static var caption: Font { .caption }
    }

    public enum Spacing {
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    public enum Radius {
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let pill: CGFloat = 999
    }

    public enum Shadow {
        public static var smallColor: Color { Color.black.opacity(0.08) }
        public static let smallRadius: CGFloat = 8
        public static let smallY: CGFloat = 4

        public static var mediumColor: Color { Color.black.opacity(0.12) }
        public static let mediumRadius: CGFloat = 16
        public static let mediumY: CGFloat = 8
    }

    public enum Gradient {
        private static var brandPurple: Color { DesignSystem.ColorRole.secondary }
        private static var brandIndigo: Color { DesignSystem.ColorRole.primary }
        private static var brandTeal: Color { DesignSystem.ColorRole.primary }

        public static var primary: LinearGradient { // purple → indigo
            LinearGradient(colors: [brandPurple, brandIndigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        public static var bluePurple: LinearGradient { // indigo → purple
            LinearGradient(colors: [brandIndigo, brandPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }

        public static var tealBlue: LinearGradient { // teal → indigo
            LinearGradient(colors: [brandTeal, brandIndigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

public struct VLThemedText: View {
    private let text: String
    private let font: Font
    private let color: Color

    public init(
        _ text: String,
        font: Font = DesignSystem.Typography.body,
        color: Color = DesignSystem.ColorRole.textPrimary
    ) {
        self.text = text
        self.font = font
        self.color = color
    }

    public var body: some View {
        Text(self.text)
            .font(self.font)
            .foregroundColor(self.color)
    }
}

public struct VLPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

public struct VLSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
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
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

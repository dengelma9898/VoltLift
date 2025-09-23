import SwiftUI

// Minimales Design-System für die Watch-App (Liquid‑Glass gemäß Docs/DESIGN_SYSTEM.md)
enum DesignSystem {
    enum ColorRole {
        // Werte gemäß Docs/DESIGN_SYSTEM.md (Dark)
        // VLPrimary Dark: #2DD4BF
        static var primary: Color { Color(red: 0.176, green: 0.831, blue: 0.749) }
        // VLSecondary Dark: ~#A88CFB (nah an #8B5CF6)
        static var secondary: Color { Color(red: 0.658, green: 0.549, blue: 0.984) }
        // VLBackground Dark: #0B1229
        static var background: Color { Color(red: 0.043, green: 0.071, blue: 0.161) }
        // VLTextPrimary Dark: #F5F7FA
        static var textPrimary: Color { Color(red: 0.961, green: 0.969, blue: 0.980) }
        // VLTextSecondary Dark: #CBD5E1
        static var textSecondary: Color { Color(red: 0.800, green: 0.835, blue: 0.882) }
    }

    enum Typography {
        static var titleL: Font { .title.weight(.bold) }
        static var titleS: Font { .title3.weight(.semibold) }
        static var body: Font { .body }
        static var footnote: Font { .footnote }
    }

    enum Spacing {
        static let s: CGFloat = 6
        static let m: CGFloat = 10
        static let l: CGFloat = 14
        static let xl: CGFloat = 18
    }

    enum Radius {
        static let l: CGFloat = 16
    }

    enum Glass {
        static var backgroundMaterial: Material { .ultraThinMaterial }
        static var cornerRadius: CGFloat { DesignSystem.Radius.l }
        static var tintStart: Color { DesignSystem.ColorRole.secondary.opacity(0.10) }
        static var tintEnd: Color { DesignSystem.ColorRole.primary.opacity(0.06) }
        static var borderColor: Color { DesignSystem.ColorRole.textPrimary.opacity(0.12) }
        static var borderWidth: CGFloat { 1.0 }
        static var highlightColor: Color { .white.opacity(0.35) }
        static var highlightWidth: CGFloat { 0.5 }
    }
}

struct VLGlassCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        self.content
            .padding(DesignSystem.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Glass.cornerRadius, style: .continuous)
                    .fill(DesignSystem.Glass.backgroundMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Glass.cornerRadius, style: .continuous)
                    .stroke(DesignSystem.Glass.borderColor, lineWidth: DesignSystem.Glass.borderWidth)
            )
    }
}

struct VLPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.m)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                    .fill(LinearGradient(
                        colors: [DesignSystem.ColorRole.secondary, DesignSystem.ColorRole.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

extension View {
    func vlBrandBackground() -> some View {
        self
            .background(
                LinearGradient(
                    colors: [
                        DesignSystem.ColorRole.background.opacity(1.0),
                        DesignSystem.ColorRole.background.opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
}

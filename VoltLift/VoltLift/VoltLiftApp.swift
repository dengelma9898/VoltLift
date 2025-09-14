import SwiftUI

@main
struct VoltLiftApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .tint(DesignSystem.ColorRole.primary)
                .preferredColorScheme(.dark)
                .onAppear { VLAppearance.applyBrandAppearance() }
        }
    }
}

@MainActor
private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

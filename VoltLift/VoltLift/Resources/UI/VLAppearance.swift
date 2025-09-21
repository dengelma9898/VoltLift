import SwiftUI

enum VLAppearance {
    @MainActor
    static func applyBrandAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(DesignSystem.ColorRole.background)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.ColorRole.textPrimary)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(DesignSystem.ColorRole.textPrimary)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(DesignSystem.ColorRole.primary)

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(DesignSystem.ColorRole.background)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = UIColor(DesignSystem.ColorRole.primary)
        UITabBar.appearance().unselectedItemTintColor = UIColor(DesignSystem.ColorRole.textSecondary)
    }
}

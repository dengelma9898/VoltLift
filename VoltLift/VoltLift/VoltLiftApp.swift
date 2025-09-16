import SwiftUI

@main
struct VoltLiftApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var userPreferencesService = UserPreferencesService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, self.persistenceController.container.viewContext)
                .environmentObject(self.userPreferencesService)
                .tint(DesignSystem.ColorRole.primary)
                .preferredColorScheme(.dark)
                .onAppear {
                    VLAppearance.applyBrandAppearance()
                    Task {
                        await self.loadInitialPreferences()
                    }
                }
        }
    }

    /// Loads initial user preferences on app launch
    private func loadInitialPreferences() async {
        do {
            // Check if setup is complete
            let isSetupComplete = try await userPreferencesService.checkSetupCompletion()

            if isSetupComplete {
                // Load equipment and plans if setup is complete
                try await self.userPreferencesService.loadSelectedEquipment()
                try await self.userPreferencesService.loadSavedPlans()
            }
        } catch {
            // Handle errors gracefully - the UI will show appropriate error states
            print("Failed to load initial preferences: \(error)")
        }
    }
}

@MainActor
private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

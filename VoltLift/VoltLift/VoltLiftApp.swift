import SwiftUI

@main
struct VoltLiftApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var userPreferencesService = UserPreferencesService()
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(userPreferencesService)
                .tint(DesignSystem.ColorRole.primary)
                .preferredColorScheme(.dark)
                .onAppear { 
                    VLAppearance.applyBrandAppearance()
                    Task {
                        await loadInitialPreferences()
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
                try await userPreferencesService.loadSelectedEquipment()
                try await userPreferencesService.loadSavedPlans()
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

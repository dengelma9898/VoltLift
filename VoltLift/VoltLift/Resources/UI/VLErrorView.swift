//
//  VLErrorView.swift
//  VoltLift
//
//  Created by Kiro on 15.9.2025.
//

import SwiftUI

/// A reusable error display component with recovery options
struct VLErrorView: View {
    let error: UserPreferencesError
    let recoveryOptions: [ErrorRecoveryOption]
    let onDismiss: () -> Void
    
    @State private var showingRecoveryOptions = false
    
    var body: some View {
        VLGlassCard {
            VStack(spacing: DesignSystem.Spacing.l) {
                // Error icon and title
                HStack(spacing: DesignSystem.Spacing.m) {
                    Image(systemName: iconForSeverity(error.severity))
                        .font(.title2)
                        .foregroundColor(colorForSeverity(error.severity))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(titleForSeverity(error.severity))
                            .font(DesignSystem.Typography.titleS)
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                        
                        Text(error.localizedDescription)
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                    
                    Spacer()
                }
                
                // Recovery suggestion
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Action buttons
                HStack(spacing: DesignSystem.Spacing.m) {
                    if recoveryOptions.count > 1 {
                        VLButton(
                            "Options",
                            style: .secondary
                        ) {
                            showingRecoveryOptions = true
                        }
                    }
                    
                    Spacer()
                    
                    VLButton(
                        "Dismiss",
                        style: .secondary
                    ) {
                        onDismiss()
                    }
                    
                    // Show primary recovery action if available
                    if let primaryOption = recoveryOptions.first(where: { !$0.isDestructive }) {
                        VLButton(
                            primaryOption.title,
                            style: .primary
                        ) {
                            Task {
                                await primaryOption.action()
                            }
                        }
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingRecoveryOptions) {
            ActionSheet(
                title: Text("Recovery Options"),
                message: Text("Choose how to handle this error"),
                buttons: recoveryOptions.map { option in
                    if option.isDestructive {
                        return .destructive(Text(option.title)) {
                            Task {
                                await option.action()
                            }
                        }
                    } else {
                        return .default(Text(option.title)) {
                            Task {
                                await option.action()
                            }
                        }
                    }
                } + [.cancel()]
            )
        }
    }
    
    // MARK: - Helpers
    
    private func iconForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.circle.fill"
        case .critical:
            return "exclamationmark.octagon.fill"
        }
    }
    
    private func colorForSeverity(_ severity: ErrorSeverity) -> Color {
        switch severity {
        case .warning:
            return DesignSystem.ColorRole.warning
        case .error:
            return DesignSystem.ColorRole.danger
        case .critical:
            return DesignSystem.ColorRole.danger
        }
    }
    
    private func titleForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .warning:
            return "Warning"
        case .error:
            return "Error"
        case .critical:
            return "Critical Error"
        }
    }
}

/// A loading state view with progress indicator and message
struct VLLoadingView: View {
    let message: String
    let showProgress: Bool
    
    init(message: String = "Loading...", showProgress: Bool = true) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.l) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(DesignSystem.ColorRole.primary)
            }
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.ColorRole.background)
    }
}

/// A view modifier that shows error states and loading states
struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject var userPreferencesService: UserPreferencesService
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(userPreferencesService.isLoading)
            
            // Loading overlay
            if userPreferencesService.isLoading {
                VLLoadingView(message: userPreferencesService.loadingMessage)
                    .background(DesignSystem.ColorRole.background.opacity(0.8))
                    .transition(.opacity)
            }
            
            // Error overlay
            if let error = userPreferencesService.lastError,
               userPreferencesService.showingErrorAlert {
                VStack {
                    Spacer()
                    
                    VLErrorView(
                        error: error,
                        recoveryOptions: userPreferencesService.errorRecoveryOptions
                    ) {
                        Task { @MainActor in
                            userPreferencesService.showingErrorAlert = false
                            userPreferencesService.lastError = nil
                        }
                    }
                    .padding(DesignSystem.Spacing.l)
                    
                    Spacer()
                }
                .background(DesignSystem.ColorRole.background.opacity(0.9))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: userPreferencesService.isLoading)
        .animation(.easeInOut(duration: 0.3), value: userPreferencesService.showingErrorAlert)
    }
}

extension View {
    /// Adds error handling and loading state support
    /// - Parameter userPreferencesService: The service to observe for errors and loading states
    /// - Returns: A view with error handling capabilities
    func withErrorHandling(_ userPreferencesService: UserPreferencesService) -> some View {
        modifier(ErrorHandlingModifier(userPreferencesService: userPreferencesService))
    }
}

// MARK: - Preview

#Preview("Error View - Warning") {
    VLErrorView(
        error: .networkUnavailable,
        recoveryOptions: [
            ErrorRecoveryOption(title: "Retry", description: "Try again") { },
            ErrorRecoveryOption(title: "Dismiss", description: "Close") { }
        ]
    ) { }
    .padding()
    .background(DesignSystem.ColorRole.background)
    .preferredColorScheme(.dark)
}

#Preview("Error View - Critical") {
    VLErrorView(
        error: .dataCorruption,
        recoveryOptions: [
            ErrorRecoveryOption(title: "Reset Data", description: "Clear all data", isDestructive: true) { },
            ErrorRecoveryOption(title: "Dismiss", description: "Close") { }
        ]
    ) { }
    .padding()
    .background(DesignSystem.ColorRole.background)
    .preferredColorScheme(.dark)
}

#Preview("Loading View") {
    VLLoadingView(message: "Loading your workout plans...")
        .preferredColorScheme(.dark)
}
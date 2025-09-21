import SwiftUI

struct OutdoorCountdownView: View {
    @Environment(\.dismiss) private var dismiss

    let activity: ActivityType
    let initialSeconds: Int
    var onStart: (() -> Void)?

    @State private var secondsRemaining: Int
    @State private var isActive = true

    init(activity: ActivityType, initialSeconds: Int = 20, onStart: (() -> Void)? = nil) {
        self.activity = activity
        self.initialSeconds = initialSeconds
        self.onStart = onStart
        self._secondsRemaining = State(initialValue: initialSeconds)
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Text(String(localized: "title.outdoor_countdown"))
                .font(DesignSystem.Typography.titleM)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)

            Text("\(self.secondsRemaining)s")
                .font(DesignSystem.Typography.titleXL)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)

            HStack(spacing: DesignSystem.Spacing.m) {
                Button(String(localized: "action.add_10s")) {
                    self.secondsRemaining += 10
                }
                .buttonStyle(VLSecondaryButtonStyle())

                Button(String(localized: "action.skip_countdown")) {
                    self.startNow()
                }
                .buttonStyle(VLPrimaryButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                .fill(DesignSystem.ColorRole.surface.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous)
                .strokeBorder(DesignSystem.ColorRole.textPrimary.opacity(0.1))
        )
        .padding(DesignSystem.Spacing.xl)
        .onAppear { self.startTimer() }
        .onDisappear { self.isActive = false }
    }

    private func startTimer() {
        self.isActive = true
        Task { @MainActor in
            while self.isActive, self.secondsRemaining > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !self.isActive { break }
                self.secondsRemaining -= 1
            }
            if self.isActive {
                self.startNow()
            }
        }
    }

    private func startNow() {
        self.isActive = false
        self.onStart?()
        self.dismiss()
    }
}

#Preview {
    OutdoorCountdownView(activity: .running) {}
        .preferredColorScheme(.dark)
}

import SwiftUI

struct OutdoorActivitySummary: Identifiable {
    let id = UUID()
    let activity: ActivityType
    let totalSeconds: Int
    let totalMeters: Double
    let perKmSeconds: [Int] // only full kilometers
    let lastPartialSeconds: Int?
    let startDate: Date
}

struct OutdoorSummaryView: View {
    let summary: OutdoorActivitySummary
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
            HStack {
                Text(self.summary.activity.title)
                    .font(DesignSystem.Typography.titleM)
                    .foregroundColor(.white)
                Spacer()
                Button(String(localized: "action.close")) { self.onClose() }
                    .buttonStyle(VLSecondaryButtonStyle())
            }

            HStack(spacing: DesignSystem.Spacing.xl) {
                self.metric(
                    title: String(localized: "label.elapsed_time"),
                    value: self.formattedDuration(self.summary.totalSeconds)
                )
                self.metric(
                    title: String(localized: "label.distance"),
                    value: self.formattedDistance(self.summary.totalMeters)
                )
                self.metric(
                    title: String(localized: "label.pace"),
                    value: self.formattedPace(seconds: self.summary.totalSeconds, meters: self.summary.totalMeters)
                )
            }

            Text(String(localized: "label.splits"))
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(.white)

            VStack(spacing: DesignSystem.Spacing.m) {
                ForEach(Array(self.summary.perKmSeconds.enumerated()), id: \.offset) { index, sec in
                    HStack {
                        Text("\(index + 1) km")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        Spacer()
                        Text(self.formattedDuration(sec)).monospacedDigit().foregroundColor(.white)
                    }
                }
                if let last = summary.lastPartialSeconds {
                    HStack {
                        Text(String(localized: "label.partial"))
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        Spacer()
                        Text(self.formattedDuration(last)).monospacedDigit().foregroundColor(.white)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.xl)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
            Text(value)
                .font(DesignSystem.Typography.titleS.monospacedDigit())
                .foregroundColor(.white)
        }
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let hrs = seconds / 3_600
        let mins = (seconds % 3_600) / 60
        let secs = seconds % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }

    private func formattedDistance(_ meters: Double) -> String {
        let km = meters / 1_000.0
        return String(format: "%.2f km", km)
    }

    private func formattedPace(seconds: Int, meters: Double) -> String {
        let km = meters / 1_000.0
        guard km > 0 else { return "-" }
        let paceSecPerKm = Int(Double(seconds) / km)
        let mins = paceSecPerKm / 60
        let secs = paceSecPerKm % 60
        return String(format: "%d:%02d /km", mins, secs)
    }
}

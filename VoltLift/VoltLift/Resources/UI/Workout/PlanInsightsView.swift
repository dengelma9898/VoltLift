import SwiftUI

struct PlanInsightsView: View {
    let plan: WorkoutPlanData

    @State private var insights: PlanInsights?
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                if let insights {
                    self.statsGrid(insights)
                    self.historyList(insights.recentSummaries)
                } else if self.isLoading {
                    ProgressView().progressViewStyle(.circular)
                } else if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        .font(DesignSystem.Typography.caption)
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .navigationTitle("Insights")
        .vlBrandBackground()
        .task { await self.loadInsights() }
    }

    private func statsGrid(_ i: PlanInsights) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Übersicht")
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
            VLGlassCard {
                VStack(spacing: DesignSystem.Spacing.m) {
                    HStack(spacing: DesignSystem.Spacing.l) {
                        self.stat("Sessions", value: "\(i.sessionCount)")
                        self.stat("Gesamtvolumen", value: String(format: "%.0f kg", i.totalVolumeKg))
                        self.stat("Ø Vol./Session", value: String(format: "%.0f kg", i.avgVolumePerSession))
                    }
                    HStack(spacing: DesignSystem.Spacing.l) {
                        self.stat("Ø Reps/Satz", value: String(format: "%.2f", i.avgRepsPerSet))
                        self.stat("Ø Schwierigkeit", value: i.avgDifficulty.map { String(format: "%.1f", $0) } ?? "-")
                    }
                }
            }

            Text("Trends (letzte 3 vs. vorherige 3)")
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
            VLGlassCard {
                VStack(spacing: DesignSystem.Spacing.m) {
                    self.trendRow(title: "Volumen", delta: i.volumeTrendDelta, unit: "kg")
                    self.trendRow(title: "Reps/Satz", delta: i.repsTrendDelta, unit: nil)
                    self.trendRow(title: "Ø Gewicht", delta: i.weightTrendDelta, unit: "kg")
                }
            }
        }
    }

    private func historyList(_ summaries: [WorkoutSessionSummary]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
            Text("Verlauf")
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
            VStack(spacing: DesignSystem.Spacing.s) {
                ForEach(summaries, id: \.id) { s in
                    VLGlassCard {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(self.historyTitle(s))
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                                Text(self.historySubtitle(s))
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            }
                            Spacer()
                            Text(self.historyBadge(s.status))
                                .font(DesignSystem.Typography.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06), in: Capsule())
                                .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private func stat(_ title: String, value: String) -> some View {
        VStack {
            Text(value)
                .font(DesignSystem.Typography.titleS)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.ColorRole.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func trendRow(title: String, delta: Double?, unit: String?) -> some View {
        HStack {
            Text(title)
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
            Spacer()
            let formatted = delta.map { String(format: "%+.2f", $0) } ?? "-"
            let unitText = unit ?? ""
            Text(unit != nil ? "\(formatted) \(unitText)" : formatted)
                .foregroundColor(delta
                    .flatMap { $0 >= 0 ? DesignSystem.ColorRole.success : DesignSystem.ColorRole.danger } ??
                    DesignSystem.ColorRole.textSecondary
                )
        }
    }

    private func loadInsights() async {
        self.isLoading = true
        defer { self.isLoading = false }
        do {
            let service = WorkoutHistoryService()
            self.insights = try await service.insights(forPlanId: self.plan.id, limit: 20)
        } catch {
            self.errorMessage = "Konnte Insights nicht laden."
        }
    }

    private func historyTitle(_ s: WorkoutSessionSummary) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let when = s.finishedAt ?? s.startedAt
        return df.string(from: when)
    }

    private func historySubtitle(_ s: WorkoutSessionSummary) -> String {
        let vol = String(format: "%.0f kg", s.totalVolumeKg)
        return "Sätze: \(s.totalSets)  •  Reps: \(s.totalReps)  •  Volumen: \(vol)"
    }

    private func historyBadge(_ status: WorkoutSessionStatus) -> String {
        switch status {
        case .finished: "done"
        case .canceled: "canceled"
        case .active: "active"
        }
    }
}

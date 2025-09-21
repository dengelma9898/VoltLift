import MapKit
import SwiftUI

struct OutdoorHistoryView: View {
    @State private var records: [OutdoorActivityRecord] = []
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            if self.isLoading {
                ProgressView()
                    .tint(.white)
                    .padding()
            }

            if self.records.isEmpty, !self.isLoading {
                VLGlassCard {
                    VStack(spacing: DesignSystem.Spacing.s) {
                        Text(String(localized: "empty.outdoor_history.title"))
                            .font(DesignSystem.Typography.titleS)
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                        Text(String(localized: "empty.outdoor_history.message"))
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(DesignSystem.Spacing.l)
            } else {
                List {
                    ForEach(self.records) { record in
                        NavigationLink {
                            OutdoorHistoryDetailView(record: record)
                        } label: {
                            self.row(record)
                        }
                        .listRowBackground(DesignSystem.ColorRole.surface)
                    }
                    .onDelete(perform: self.onDelete)
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
        }
        .navigationTitle(String(localized: "title.outdoor_history"))
        .navigationBarTitleDisplayMode(.inline)
        .vlBrandBackground()
        .task { await self.reload() }
    }

    private func row(_ record: OutdoorActivityRecord) -> some View {
        VLGlassCard {
            HStack(spacing: DesignSystem.Spacing.m) {
                Image(systemName: "map.fill").foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.title(for: record))
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.ColorRole.textPrimary)
                    Text(self.subtitle(for: record))
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.ColorRole.textSecondary)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    private func title(for record: OutdoorActivityRecord) -> String {
        let activityTitle: String = switch record.activityType {
        case "running": String(localized: "activity.running")
        case "biking": String(localized: "activity.biking")
        case "hiking": String(localized: "activity.hiking")
        default: record.activityType
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(activityTitle) – \(formatter.string(from: record.finishedAt))"
    }

    private func subtitle(for record: OutdoorActivityRecord) -> String {
        let distanceKm = record.totalMeters / 1_000.0
        let minutes = record.totalSeconds / 60
        let seconds = record.totalSeconds % 60
        let distanceString = String(format: "%.2f", distanceKm)
        let durationString = String(format: "%d:%02d", minutes, seconds)
        let format = String(localized: "label.distance_time_format")
        return String(format: format, locale: Locale.current, distanceString, durationString)
    }

    private func onDelete(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let id = self.records[index].id
                try? await OutdoorActivityHistoryService().delete(id: id)
            }
            await self.reload()
        }
    }

    private func reload() async {
        self.isLoading = true
        defer { self.isLoading = false }
        do {
            self.records = try await OutdoorActivityHistoryService().list(limit: nil)
        } catch {
            self.records = []
        }
    }
}

struct OutdoorHistoryDetailView: View {
    let record: OutdoorActivityRecord

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                Text(self.title)
                    .font(DesignSystem.Typography.titleM)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                if let region = self.region() {
                    Map(coordinateRegion: .constant(region))
                        .overlay(self.routeOverlay())
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous))
                }

                HStack(spacing: DesignSystem.Spacing.xl) {
                    self.metric(String(localized: "label.elapsed_time"), self.formatDuration(self.record.totalSeconds))
                    self.metric(String(localized: "label.distance"), self.formatDistance(self.record.totalMeters))
                    self.metric(
                        String(localized: "label.pace"),
                        self.formatPace(seconds: self.record.totalSeconds, meters: self.record.totalMeters)
                    )
                }

                Text(String(localized: "label.splits"))
                    .font(DesignSystem.Typography.titleS)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)

                ForEach(Array(self.record.perKmSeconds.enumerated()), id: \.offset) { index, seconds in
                    VLGlassCard {
                        HStack {
                            Text("\(index + 1) km")
                                .foregroundColor(.white)
                            Spacer()
                            Text(self.formatDuration(seconds))
                                .foregroundColor(.white)
                        }
                    }
                }

                if let last = record.lastPartialSeconds, record.totalMeters > 0 {
                    VLGlassCard {
                        HStack {
                            Text(String(localized: "label.partial_km"))
                                .foregroundColor(.white)
                            Spacer()
                            Text(self.formatDuration(last))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .vlBrandBackground()
        .navigationTitle(String(localized: "title.outdoor_history_detail"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        switch self.record.activityType {
        case "running": String(localized: "activity.running")
        case "biking": String(localized: "activity.biking")
        case "hiking": String(localized: "activity.hiking")
        default: self.record.activityType
        }
    }

    private func region() -> MKCoordinateRegion? {
        guard !self.record.track.isEmpty else { return nil }
        let lats = self.record.track.map(\.latitude)
        let lons = self.record.track.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(), let minLon = lons.min(),
              let maxLon = lons.max() else { return nil }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2.0, longitude: (minLon + maxLon) / 2.0)
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3 + 0.01,
            longitudeDelta: (maxLon - minLon) * 1.3 + 0.01
        )
        return MKCoordinateRegion(center: center, span: span)
    }

    @ViewBuilder private func routeOverlay() -> some View {
        if self.record.track.count >= 2 {
            let polyline = MKPolyline(coordinates: record.track, count: self.record.track.count)
            MapOverlayPolyline(polyline: polyline)
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).foregroundColor(DesignSystem.ColorRole.textSecondary)
            Text(value).foregroundColor(.white)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func formatDistance(_ meters: Double) -> String {
        String(format: "%.2f km", meters / 1_000.0)
    }

    private func formatPace(seconds: Int, meters: Double) -> String {
        guard meters > 0 else { return "–" }
        let pace = Double(seconds) / (meters / 1_000.0)
        let m = Int(pace) / 60
        let s = Int(pace) % 60
        return String(format: "%d:%02d /km", m, s)
    }
}

private struct MapOverlayPolyline: UIViewRepresentable {
    let polyline: MKPolyline

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlay(self.polyline)
        if uiView.overlays.count == 1 {
            uiView.setVisibleMapRect(
                self.polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                animated: false
            )
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let pl = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: pl)
                renderer.strokeColor = .systemTeal
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

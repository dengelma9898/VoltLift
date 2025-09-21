import SwiftUI

import MapKit

struct OutdoorActivitySummary: Identifiable {
    let id = UUID()
    let activity: ActivityType
    let totalSeconds: Int
    let totalMeters: Double
    let perKmSeconds: [Int] // only full kilometers
    let lastPartialSeconds: Int?
    let startDate: Date
    let track: [CLLocationCoordinate2D]
}

struct OutdoorSummaryView: View {
    let summary: OutdoorActivitySummary
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
            HStack {
                Text(self.summary.activity.title)
                    .font(DesignSystem.Typography.titleM)
                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                Spacer()
                Button(String(localized: "action.close")) { self.onClose() }
                    .buttonStyle(VLSecondaryButtonStyle())
            }

            // Route preview
            if let region = self.routeRegion() {
                Map(initialPosition: .region(region))
                    .overlay(self.routeOverlay())
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous))
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
                .foregroundColor(DesignSystem.ColorRole.textPrimary)

            VStack(spacing: DesignSystem.Spacing.m) {
                ForEach(Array(self.summary.perKmSeconds.enumerated()), id: \.offset) { index, sec in
                    let speed = self.formattedSpeedKmh(seconds: sec, meters: 1_000)
                    HStack {
                        Text("\(index + 1) km")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(speed) km/h")
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text(self.formattedDuration(sec))
                            .monospacedDigit()
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                if let last = summary.lastPartialSeconds {
                    HStack {
                        Text(String(localized: "label.partial"))
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                        Spacer()
                        Text(self.formattedDuration(last)).monospacedDigit()
                            .foregroundColor(DesignSystem.ColorRole.textPrimary)
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
                .foregroundColor(DesignSystem.ColorRole.textPrimary)
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

    private func formattedSpeedKmh(seconds: Int, meters: Double) -> String {
        guard seconds > 0 else { return "-" }
        let hours = Double(seconds) / 3_600.0
        let km = meters / 1_000.0
        let kmh = km / hours
        return String(format: "%.1f", kmh)
    }

    // MARK: - Route helpers

    private func routeRegion() -> MKCoordinateRegion? {
        let coords = self.summary.track
        guard !coords.isEmpty else { return nil }
        guard let first = coords.first else { return nil }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for coord in coords {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.002, (maxLat - minLat) * 1.3),
            longitudeDelta: max(0.002, (maxLon - minLon) * 1.3)
        )
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2.0, longitude: (minLon + maxLon) / 2.0)
        return MKCoordinateRegion(center: center, span: span)
    }

    private func routeOverlay() -> some View {
        let polyline = MKPolyline(coordinates: self.summary.track, count: self.summary.track.count)
        return MapOverlay(polyline: polyline)
    }
}

private struct MapOverlay: UIViewRepresentable {
    let polyline: MKPolyline

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.isUserInteractionEnabled = false
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlay(self.polyline)
        uiView.setVisibleMapRect(
            self.polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
            animated: false
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let line = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: line)
                renderer.strokeColor = UIColor(DesignSystem.ColorRole.primary)
                renderer.lineWidth = 4
                renderer.lineJoin = .round
                renderer.lineCap = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

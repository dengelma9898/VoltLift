import MapKit
import SwiftUI

struct OutdoorActivityView: View {
    @StateObject private var locationService = LocationService()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedActivity: ActivityType = .running

    var body: some View {
        VStack(spacing: 0) {
            Map(coordinateRegion: self.$region, showsUserLocation: true)
                .ignoresSafeArea(edges: [.horizontal])

            Color.clear.frame(height: 0)
        }
        .navigationTitle(String(localized: "title.outdoor_activity"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { self.centerOnUser() }) {
                    Image(systemName: "location.fill")
                }
                .buttonStyle(VLIconButtonStyle(size: 36))
                .accessibilityLabel(Text(String(localized: "action.locate_me")))
                .disabled(!self.isLocateEnabled)
            }
        }
        .onAppear {
            self.locationService.requestWhenInUsePermission()
        }
        .onChange(of: self.locationService.authorizationStatus) { _, newStatus in
            if [.authorizedAlways, .authorizedWhenInUse].contains(newStatus) {
                self.locationService.startUpdatingLocation()
            }
        }
        .onChange(of: self.locationService.currentLocation) { _, newLocation in
            guard let newLocation else { return }
            withAnimation(.easeInOut) {
                self.region.center = newLocation.coordinate
                self.region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ActivityPickerView(activities: ActivityType.defaultSet, selected: self.$selectedActivity) { _ in
                // future: adjust metrics/filters per activity
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.bottom, DesignSystem.Spacing.xl)
            .background(.clear)
        }
    }

    private var isLocateEnabled: Bool {
        [.authorizedAlways, .authorizedWhenInUse].contains(self.locationService.authorizationStatus) && self
            .locationService.currentLocation != nil
    }

    private func centerOnUser() {
        if ![CLAuthorizationStatus.authorizedAlways, .authorizedWhenInUse]
            .contains(self.locationService.authorizationStatus)
        {
            self.locationService.requestWhenInUsePermission()
        } else if let location = self.locationService.currentLocation {
            withAnimation(.easeInOut) {
                self.region.center = location.coordinate
                self.region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            }
        } else {
            self.locationService.startUpdatingLocation()
        }
    }
}

#Preview {
    NavigationStack {
        OutdoorActivityView()
    }
}

import MapKit
import SwiftUI

struct OutdoorActivityView: View {
    @StateObject private var locationService = LocationService()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.5200, longitude: 13.4050),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedActivity: ActivityType = .running
    @State private var isCountdownPresented = false
    @State private var isActivityRunning = false
    @State private var countdownActivity: ActivityType?

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: self.$region, showsUserLocation: true)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.m) {
                if self.isActivityRunning {
                    VLGlassCard {
                        HStack(spacing: DesignSystem.Spacing.m) {
                            Image(systemName: "play.circle.fill").foregroundColor(.white)
                            Text(String(localized: "hint.activity_running"))
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.white)
                            Spacer()
                            Button(String(localized: "action.stop")) {
                                self.isActivityRunning = false
                            }
                            .buttonStyle(VLSecondaryButtonStyle())
                        }
                    }
                } else {
                    ActivityPickerView(
                        activities: ActivityType.defaultSet,
                        selected: self.$selectedActivity
                    ) { activity in
                        self.selectedActivity = activity
                        self.countdownActivity = activity
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .padding(.bottom, DesignSystem.Spacing.s + 40)
                }
            }
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
        .sheet(item: self.$countdownActivity) { activity in
            OutdoorCountdownView(activity: activity) {
                self.locationService.requestPreciseLocationIfNeeded()
                self.isActivityRunning = true
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(DesignSystem.Radius.l)
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

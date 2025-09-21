import CoreLocation
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
    @State private var activeActivity: ActivityType?

    // Metrics tracking
    @State private var activityStartDate: Date?
    @State private var elapsedSeconds: Int = 0
    @State private var totalDistanceMeters: Double = 0
    @State private var lastTrackLocation: CLLocation?
    @State private var activityTimerTask: Task<Void, Never>?
    @State private var splitsSeconds: [Int] = []
    @State private var lastSplitStartSeconds: Int = 0
    @State private var showStopConfirm = false
    @State private var summary: OutdoorActivitySummary?
    @State private var trackCoordinates: [CLLocationCoordinate2D] = []

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(coordinateRegion: self.$region, showsUserLocation: true)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.m) {
                if self.isActivityRunning {
                    VLGlassCard {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.m) {
                            HStack(spacing: DesignSystem.Spacing.m) {
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                                Text(self.activeActivity?.title ?? String(localized: "hint.activity_running"))
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.ColorRole.textPrimary)
                                Spacer()
                                Button(String(localized: "action.stop")) {
                                    self.showStopConfirm = true
                                }
                                .buttonStyle(VLSecondaryButtonStyle())
                            }

                            HStack(spacing: DesignSystem.Spacing.xl) {
                                self.metricItem(
                                    titleKey: "label.elapsed_time",
                                    value: self.formattedDuration(self.elapsedSeconds)
                                )
                                self.metricItem(
                                    titleKey: "label.distance",
                                    value: self.formattedDistance(self.totalDistanceMeters)
                                )
                                self.metricItem(
                                    titleKey: "label.pace",
                                    value: self.formattedPace(
                                        seconds: self.elapsedSeconds,
                                        meters: self.totalDistanceMeters
                                    )
                                )
                            }
                        }
                    }
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.l, style: .continuous))
                    #if os(visionOS)
                        .glassBackgroundEffect()
                    #endif
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.bottom, DesignSystem.Spacing.s + 40)
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
                self.startActivity()
            }
            .presentationDetents([.medium])
            .presentationCornerRadius(DesignSystem.Radius.l)
        }
        .confirmationDialog(
            String(localized: "title.confirm_stop"),
            isPresented: self.$showStopConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "action.stop"), role: .destructive) {
                let built = self.buildSummary()
                self.stopActivity()
                Task {
                    // Persistiere in Outdoor-Historie
                    let activity = self.activeActivity ?? self.selectedActivity
                    let record = OutdoorActivityRecord(
                        id: UUID(),
                        activityType: self.storageKey(for: activity),
                        startedAt: built.startDate,
                        finishedAt: Date(),
                        totalSeconds: built.totalSeconds,
                        totalMeters: built.totalMeters,
                        perKmSeconds: built.perKmSeconds,
                        lastPartialSeconds: built.lastPartialSeconds,
                        track: built.track
                    )
                    try? await OutdoorActivityHistoryService().save(record: record)
                }
                self.summary = built
            }
            Button(String(localized: "action.cancel"), role: .cancel) {}
        }
        .sheet(item: self.$summary) { summary in
            OutdoorSummaryView(summary: summary) {
                self.summary = nil
            }
            .presentationDetents([.medium, .large])
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
            if self.isActivityRunning {
                if let last = self.lastTrackLocation {
                    self.totalDistanceMeters += newLocation.distance(from: last)
                }
                self.lastTrackLocation = newLocation
                // track route
                self.trackCoordinates.append(newLocation.coordinate)
                let completedKm = Int(self.totalDistanceMeters / 1_000.0)
                while self.splitsSeconds.count < completedKm {
                    let split = self.elapsedSeconds - self.lastSplitStartSeconds
                    self.splitsSeconds.append(max(split, 0))
                    self.lastSplitStartSeconds = self.elapsedSeconds
                }
                withAnimation(.easeInOut) {
                    self.region.center = newLocation.coordinate
                    self.region.span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                }
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

    private func startActivity() {
        self.locationService.requestPreciseLocationIfNeeded()
        self.isActivityRunning = true
        self.activityStartDate = Date()
        self.elapsedSeconds = 0
        self.totalDistanceMeters = 0
        self.lastTrackLocation = self.locationService.currentLocation
        self.activeActivity = self.selectedActivity
        self.splitsSeconds = []
        self.lastSplitStartSeconds = 0
        self.trackCoordinates = self.locationService.currentLocation.map { [$0.coordinate] } ?? []
        self.activityTimerTask?.cancel()
        self.activityTimerTask = Task { @MainActor in
            while self.isActivityRunning {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !self.isActivityRunning { break }
                self.elapsedSeconds += 1
            }
        }
    }

    private func stopActivity() {
        self.isActivityRunning = false
        self.activityTimerTask?.cancel()
        self.activityTimerTask = nil
        self.activeActivity = nil
    }

    private func buildSummary() -> OutdoorActivitySummary {
        let kmCompleted = Int(self.totalDistanceMeters / 1_000.0)
        let perKm = Array(self.splitsSeconds.prefix(kmCompleted))
        let remainderMeters = self.totalDistanceMeters - Double(kmCompleted) * 1_000.0
        let partial = remainderMeters > 1 ? (self.elapsedSeconds - self.lastSplitStartSeconds) : nil
        return OutdoorActivitySummary(
            activity: self.activeActivity ?? self.selectedActivity,
            totalSeconds: self.elapsedSeconds,
            totalMeters: self.totalDistanceMeters,
            perKmSeconds: perKm,
            lastPartialSeconds: partial,
            startDate: self.activityStartDate ?? Date(),
            track: self.trackCoordinates
        )
    }

    @ViewBuilder
    private func metricItem(titleKey: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(titleKey))
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

    private func storageKey(for activity: ActivityType) -> String {
        switch activity {
        case .running: "running"
        case .biking: "biking"
        case .hiking: "hiking"
        }
    }
}

#Preview {
    NavigationStack {
        OutdoorActivityView()
    }
}

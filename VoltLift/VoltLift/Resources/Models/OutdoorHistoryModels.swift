import CoreLocation
import Foundation

/// Persistierbares Modell für Outdoor-Aktivitäten
struct OutdoorActivityRecord: Identifiable, Equatable, Codable {
    let id: UUID
    let activityType: String // mappt `ActivityType` über String ("running"/"biking"/"hiking")
    let startedAt: Date
    let finishedAt: Date
    let totalSeconds: Int
    let totalMeters: Double
    let perKmSeconds: [Int]
    let lastPartialSeconds: Int?
    let track: [CLLocationCoordinate2D]

    init(
        id: UUID = UUID(),
        activityType: String,
        startedAt: Date,
        finishedAt: Date,
        totalSeconds: Int,
        totalMeters: Double,
        perKmSeconds: [Int],
        lastPartialSeconds: Int?,
        track: [CLLocationCoordinate2D]
    ) {
        self.id = id
        self.activityType = activityType
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.totalSeconds = totalSeconds
        self.totalMeters = totalMeters
        self.perKmSeconds = perKmSeconds
        self.lastPartialSeconds = lastPartialSeconds
        self.track = track
    }

    static func == (lhs: OutdoorActivityRecord, rhs: OutdoorActivityRecord) -> Bool {
        guard lhs.id == rhs.id,
              lhs.activityType == rhs.activityType,
              lhs.startedAt == rhs.startedAt,
              lhs.finishedAt == rhs.finishedAt,
              lhs.totalSeconds == rhs.totalSeconds,
              lhs.totalMeters == rhs.totalMeters,
              lhs.perKmSeconds == rhs.perKmSeconds,
              lhs.lastPartialSeconds == rhs.lastPartialSeconds,
              lhs.track.count == rhs.track.count
        else { return false }

        for (leftCoordinate, rightCoordinate) in zip(lhs.track, rhs.track) {
            if leftCoordinate.latitude != rightCoordinate.latitude || leftCoordinate.longitude != rightCoordinate
                .longitude
            {
                return false
            }
        }
        return true
    }
}

extension CLLocationCoordinate2D: Codable {
    private enum CodingKeys: String, CodingKey { case latitude, longitude }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lat = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: lat, longitude: lon)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.latitude, forKey: .latitude)
        try container.encode(self.longitude, forKey: .longitude)
    }
}

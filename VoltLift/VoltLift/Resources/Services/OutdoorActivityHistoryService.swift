import CoreData
import CoreLocation
import Foundation

protocol OutdoorActivityHistoryReading {
    func list(limit: Int?) async throws -> [OutdoorActivityRecord]
    func load(id: UUID) async throws -> OutdoorActivityRecord?
}

protocol OutdoorActivityHistoryWriting {
    func save(record: OutdoorActivityRecord) async throws
    func delete(id: UUID) async throws
}

struct OutdoorActivityHistoryService: OutdoorActivityHistoryReading, OutdoorActivityHistoryWriting {
    private let persistence: PersistenceController

    init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
    }

    // MARK: - Public API

    func list(limit: Int? = nil) async throws -> [OutdoorActivityRecord] {
        try await self.persistence.performBackgroundTask { context in
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "OutdoorActivityCD")
            request.sortDescriptors = [NSSortDescriptor(key: "finishedAt", ascending: false)]
            if let limit { request.fetchLimit = limit }

            let rows = try context.fetch(request)
            return try rows.map { try self.decodeRow($0) }
        }
    }

    func load(id: UUID) async throws -> OutdoorActivityRecord? {
        try await self.persistence.performBackgroundTask { context in
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "OutdoorActivityCD")
            request.predicate = NSPredicate(format: "activityId == %@", id as CVarArg)
            request.fetchLimit = 1
            return try context.fetch(request).first.flatMap { try? self.decodeRow($0) }
        }
    }

    func save(record: OutdoorActivityRecord) async throws {
        _ = try await self.persistence.performBackgroundTask { context in
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "OutdoorActivityCD")
            request.predicate = NSPredicate(format: "activityId == %@", record.id as CVarArg)
            request.fetchLimit = 1

            let row: NSManagedObject
            if let existing = try context.fetch(request).first {
                row = existing
            } else {
                guard let entity = NSEntityDescription.entity(forEntityName: "OutdoorActivityCD", in: context) else {
                    throw NSError(
                        domain: "OutdoorActivityHistoryService",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Missing entity OutdoorActivityCD"]
                    )
                }
                row = NSManagedObject(entity: entity, insertInto: context)
            }

            try self.encodeRow(row, from: record)
            return record.id
        }
    }

    func delete(id: UUID) async throws {
        try await self.persistence.performBackgroundTask { context in
            let request: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "OutdoorActivityCD")
            request.predicate = NSPredicate(format: "activityId == %@", id as CVarArg)
            request.fetchLimit = 1
            if let row = try context.fetch(request).first {
                context.delete(row)
            }
        }
    }

    // MARK: - Mapping

    private func encodeRow(_ row: NSManagedObject, from record: OutdoorActivityRecord) throws {
        row.setValue(record.id, forKey: "activityId")
        row.setValue(record.activityType, forKey: "activityType")
        row.setValue(record.startedAt, forKey: "startedAt")
        row.setValue(record.finishedAt, forKey: "finishedAt")
        row.setValue(record.totalSeconds, forKey: "totalSeconds")
        row.setValue(record.totalMeters, forKey: "totalMeters")

        let perKmData = try JSONEncoder().encode(record.perKmSeconds)
        row.setValue(perKmData, forKey: "perKmSecondsData")

        if let lastPartial = record.lastPartialSeconds {
            row.setValue(lastPartial, forKey: "lastPartialSeconds")
        } else {
            row.setValue(nil, forKey: "lastPartialSeconds")
        }

        let trackData = try JSONEncoder().encode(record.track)
        row.setValue(trackData, forKey: "trackData")
    }

    private func decodeRow(_ row: NSManagedObject) throws -> OutdoorActivityRecord {
        let id = (row.value(forKey: "activityId") as? UUID) ?? UUID()
        let activityType = (row.value(forKey: "activityType") as? String) ?? "running"
        let startedAt = (row.value(forKey: "startedAt") as? Date) ?? Date()
        let finishedAt = (row.value(forKey: "finishedAt") as? Date) ?? Date()
        let totalSeconds = (row.value(forKey: "totalSeconds") as? Int) ?? 0
        let totalMeters = (row.value(forKey: "totalMeters") as? Double) ?? 0

        let perKm: [Int] = {
            if let data = row.value(forKey: "perKmSecondsData") as? Data {
                return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
            }
            return []
        }()
        let lastPartialSeconds = row.value(forKey: "lastPartialSeconds") as? Int
        let track: [CLLocationCoordinate2D] = {
            if let data = row.value(forKey: "trackData") as? Data {
                return (try? JSONDecoder().decode([CLLocationCoordinate2D].self, from: data)) ?? []
            }
            return []
        }()

        return OutdoorActivityRecord(
            id: id,
            activityType: activityType,
            startedAt: startedAt,
            finishedAt: finishedAt,
            totalSeconds: totalSeconds,
            totalMeters: totalMeters,
            perKmSeconds: perKm,
            lastPartialSeconds: lastPartialSeconds,
            track: track
        )
    }
}

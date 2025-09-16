//
//  ExerciseMetadata+Extensions.swift
//  VoltLift
//
//  Created by Kiro on 14.9.2025.
//

import Foundation
import CoreData

extension ExerciseMetadata {
    
    /// Convenience initializer for creating ExerciseMetadata with required fields
    convenience init(exerciseId: UUID, name: String, context: NSManagedObjectContext) {
        self.init(context: context)
        self.exerciseId = exerciseId
        self.name = name
        self.lastUsed = Date()
        self.usageCount = 0
    }
    
    /// Returns true if the exercise has been used recently (within last 7 days)
    var isRecentlyUsed: Bool {
        guard let lastUsed = lastUsed else { return false }
        return Date().timeIntervalSince(lastUsed) < 7 * 24 * 60 * 60 // 7 days
    }
    
    /// Returns true if the exercise is frequently used (more than 5 times)
    var isFrequentlyUsed: Bool {
        return usageCount > 5
    }
    
    /// Returns formatted last used date string
    var formattedLastUsed: String {
        guard let lastUsed = lastUsed else { return "Never" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUsed, relativeTo: Date())
    }
    
    /// Returns usage frequency description
    var usageFrequencyDescription: String {
        switch usageCount {
        case 0:
            return "Never used"
        case 1:
            return "Used once"
        case 2...5:
            return "Used \(usageCount) times"
        case 6...20:
            return "Frequently used (\(usageCount) times)"
        default:
            return "Very frequently used (\(usageCount) times)"
        }
    }
}

// MARK: - Fetch Request

extension ExerciseMetadata {
    
    /// Fetch request for recently used exercises
    static func recentlyUsedFetchRequest(limit: Int = 10) -> NSFetchRequest<ExerciseMetadata> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExerciseMetadata.lastUsed, ascending: false)]
        request.fetchLimit = limit
        return request
    }
    
    /// Fetch request for most used exercises
    static func mostUsedFetchRequest(limit: Int = 10) -> NSFetchRequest<ExerciseMetadata> {
        let request = fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ExerciseMetadata.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \ExerciseMetadata.lastUsed, ascending: false)
        ]
        request.fetchLimit = limit
        return request
    }
    
    /// Fetch request for specific exercise by ID
    static func fetchRequest(for exerciseId: UUID) -> NSFetchRequest<ExerciseMetadata> {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "exerciseId == %@", exerciseId as CVarArg)
        request.fetchLimit = 1
        return request
    }
}
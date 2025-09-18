import Foundation

public enum PlanChangeOperation: String, Equatable, CaseIterable {
    case addSet
    case removeSet
    case moveSet
    case editSetAttributes
}

public struct PlanChangeDuringSession: Equatable, Identifiable {
    public let id: UUID
    public var sessionId: UUID
    public var operation: PlanChangeOperation
    public var payload: Data // opaque payload (JSON-encoded indices/values)

    public init(id: UUID = UUID(), sessionId: UUID, operation: PlanChangeOperation, payload: Data) {
        self.id = id
        self.sessionId = sessionId
        self.operation = operation
        self.payload = payload
    }
}

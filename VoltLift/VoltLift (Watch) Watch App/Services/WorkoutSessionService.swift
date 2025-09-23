import Combine
import Foundation
import HealthKit

protocol WatchWorkoutSessionServiceProtocol: AnyObject {}

final class WatchWorkoutSessionService: NSObject, ObservableObject, WatchWorkoutSessionServiceProtocol {}

# Design Document

## Overview

The workout plan customization feature extends VoltLift's existing workout system to enable detailed exercise parameter customization within saved workout plans. Users can modify individual exercises with specific set configurations, including repetition types (warm-up, normal, cool-down), weight values, and repetition counts. This design builds upon the existing Core Data architecture and SwiftUI components while introducing new data models and UI components for granular exercise control.

## Architecture

### High-Level Architecture

The feature follows VoltLift's existing layered architecture:

```
UI Layer (SwiftUI Views)
    ↓
Service Layer (UserPreferencesService + ExerciseCustomizationService)
    ↓
Data Layer (Core Data + HealthKit Integration)
```

### Key Components

1. **Enhanced Data Models**: Extended `ExerciseData` and new `ExerciseSet` model
2. **Exercise Customization Service**: New service for managing exercise modifications
3. **Plan Customization UI**: New views for editing workout plans and exercises
4. **Set Management System**: Components for adding/removing/editing individual sets
5. **Validation Engine**: Input validation for weights, reps, and set configurations

## Components and Interfaces

### Data Models

#### Enhanced ExerciseData Model
```swift
struct ExerciseData: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let sets: [ExerciseSet]  // Changed from Int to [ExerciseSet]
    let restTime: Int
    let orderIndex: Int
    
    // Computed properties for backward compatibility
    var totalSets: Int { sets.count }
    var averageReps: Int { sets.isEmpty ? 0 : sets.map(\.reps).reduce(0, +) / sets.count }
    var averageWeight: Double { sets.isEmpty ? 0 : sets.map(\.weight).reduce(0, +) / Double(sets.count) }
}
```

#### New ExerciseSet Model
```swift
struct ExerciseSet: Identifiable, Codable, Equatable {
    let id: UUID
    let setNumber: Int
    let reps: Int
    let weight: Double
    let setType: SetType
    let isCompleted: Bool
    let completedAt: Date?
    
    init(setNumber: Int, reps: Int = 10, weight: Double = 0.0, setType: SetType = .normal) {
        self.id = UUID()
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.setType = setType
        self.isCompleted = false
        self.completedAt = nil
    }
}

enum SetType: String, CaseIterable, Codable {
    case warmUp = "warm_up"
    case normal = "normal"
    case coolDown = "cool_down"
    
    var displayName: String {
        switch self {
        case .warmUp: return "Warm-up"
        case .normal: return "Working Set"
        case .coolDown: return "Cool-down"
        }
    }
    
    var icon: String {
        switch self {
        case .warmUp: return "thermometer.low"
        case .normal: return "dumbbell.fill"
        case .coolDown: return "leaf.fill"
        }
    }
}
```

### Services

#### ExerciseCustomizationService
```swift
@MainActor
class ExerciseCustomizationService: ObservableObject {
    @Published var isCustomizing: Bool = false
    @Published var validationErrors: [ValidationError] = []
    
    // Exercise modification methods
    func updateExerciseSet(_ exerciseId: UUID, setId: UUID, reps: Int, weight: Double, setType: SetType) async throws
    func addSetToExercise(_ exerciseId: UUID, afterSet: Int?) async throws -> ExerciseSet
    func removeSetFromExercise(_ exerciseId: UUID, setId: UUID) async throws
    func reorderSets(_ exerciseId: UUID, from: IndexSet, to: Int) async throws
    
    // Validation methods
    func validateSetParameters(reps: Int, weight: Double) -> [ValidationError]
    func validateExerciseStructure(_ exercise: ExerciseData) -> [ValidationError]
}
```

### UI Components

#### PlanCustomizationView
Main view for customizing workout plans with exercise list and editing capabilities.

#### ExerciseCustomizationView
Detailed view for editing individual exercises with set management.

#### SetEditorView
Component for editing individual set parameters (reps, weight, type).

#### SetTypePickerView
Specialized picker for selecting set types with visual indicators.

## Data Models

### Core Data Schema Updates

#### Updated PlanExercise Entity
```xml
<entity name="PlanExercise">
    <attribute name="exerciseId" attributeType="UUID"/>
    <attribute name="name" attributeType="String"/>
    <attribute name="setsData" attributeType="Binary"/>  <!-- JSON serialized ExerciseSet array -->
    <attribute name="restTime" attributeType="Integer 32"/>
    <attribute name="orderIndex" attributeType="Integer 32"/>
    <attribute name="workoutPlanId" attributeType="UUID"/>
    
    <!-- Computed attributes for queries -->
    <attribute name="totalSets" attributeType="Integer 32" derived="YES"/>
    <attribute name="averageWeight" attributeType="Double" derived="YES"/>
</entity>
```

### Validation Rules

#### Set Parameter Validation
- **Repetitions**: 1-50 range, integer values only
- **Weight**: 0-1000 lbs/kg range, decimal precision to 0.5 increments
- **Set Types**: Must be valid enum values
- **Set Structure**: Minimum 1 set per exercise, maximum 10 sets per exercise

#### Exercise Structure Validation
- **Set Ordering**: Warm-up sets before normal sets, cool-down sets after normal sets
- **Set Numbering**: Sequential numbering starting from 1
- **Duplicate Prevention**: No duplicate set numbers within an exercise

## Error Handling

### Validation Errors
```swift
enum ValidationError: LocalizedError {
    case invalidRepCount(value: Int, range: ClosedRange<Int>)
    case invalidWeight(value: Double, range: ClosedRange<Double>)
    case invalidSetStructure(reason: String)
    case minimumSetsRequired(minimum: Int)
    case maximumSetsExceeded(maximum: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidRepCount(let value, let range):
            return "Repetitions must be between \(range.lowerBound) and \(range.upperBound). Got: \(value)"
        case .invalidWeight(let value, let range):
            return "Weight must be between \(range.lowerBound) and \(range.upperBound). Got: \(value)"
        case .invalidSetStructure(let reason):
            return "Invalid set structure: \(reason)"
        case .minimumSetsRequired(let minimum):
            return "At least \(minimum) set is required"
        case .maximumSetsExceeded(let maximum):
            return "Maximum \(maximum) sets allowed per exercise"
        }
    }
}
```

### Error Recovery Strategies
- **Auto-correction**: Automatically adjust out-of-range values to nearest valid value
- **Graceful degradation**: Fall back to default values for corrupted set data
- **User feedback**: Clear error messages with suggested corrections
- **Undo functionality**: Allow users to revert changes if validation fails

## Testing Strategy

### Unit Tests
- **Data Model Tests**: Validation of ExerciseSet and ExerciseData models
- **Service Tests**: ExerciseCustomizationService functionality
- **Validation Tests**: Comprehensive testing of validation rules
- **Serialization Tests**: JSON encoding/decoding of enhanced models

### Integration Tests
- **Core Data Integration**: Saving/loading customized plans
- **HealthKit Integration**: Syncing detailed set data to HealthKit
- **Service Integration**: UserPreferencesService with customization features
- **Migration Tests**: Upgrading existing plans to new data structure

### UI Tests
- **Plan Customization Flow**: End-to-end customization workflow
- **Set Management**: Adding, removing, and editing sets
- **Validation Feedback**: Error handling and user feedback
- **Accessibility**: VoiceOver and accessibility compliance

### Performance Tests
- **Large Plan Loading**: Performance with plans containing many exercises and sets
- **Real-time Validation**: Responsiveness during parameter editing
- **Memory Usage**: Efficient handling of detailed exercise data
- **Background Processing**: Non-blocking customization operations

## Implementation Considerations

### Backward Compatibility
- **Data Migration**: Automatic conversion of existing simple exercise data to set-based structure
- **API Compatibility**: Maintain existing ExerciseData interface through computed properties
- **UI Fallbacks**: Graceful handling of legacy data in new UI components

### Performance Optimizations
- **Lazy Loading**: Load detailed set data only when needed for customization
- **Batch Operations**: Efficient bulk updates for multiple set modifications
- **Caching Strategy**: Cache frequently accessed customization data
- **Background Processing**: Perform validation and saving operations off main thread

### User Experience
- **Progressive Disclosure**: Show basic exercise info by default, detailed sets on demand
- **Smart Defaults**: Intelligent default values based on exercise type and user history
- **Quick Actions**: Common operations (duplicate set, adjust all weights) easily accessible
- **Visual Feedback**: Clear indication of set types and completion status

### HealthKit Integration
- **Detailed Metadata**: Include set type and individual set data in HealthKit workouts
- **Structured Data**: Organize workout data with proper set grouping
- **Privacy Compliance**: Respect user privacy preferences for detailed tracking data
- **Sync Reliability**: Robust error handling for HealthKit synchronization failures
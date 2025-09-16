# Design Document

## Overview

The Enhanced Exercise Library feature expands VoltLift's current exercise catalog system to provide comprehensive exercise information, better equipment-based filtering, and detailed exercise guidance. The design maintains VoltLift's core principle of simplicity while significantly improving the user experience for exercise selection and execution.

The current system has a basic `ExerciseCatalog` with ~22 exercises that filters based on available equipment. This enhancement will expand the catalog, add rich exercise metadata, and provide visual guidance while preserving the existing SwiftUI architecture and HealthKit integration.

## Architecture

### Current System Analysis
- **ExerciseCatalog**: Static enum with hardcoded exercise array
- **Exercise Model**: Simple struct with name, muscle group, and required equipment
- **Equipment System**: Set-based filtering with 10 available equipment types
- **UI Flow**: Equipment selection → Plan creation → Exercise selection by muscle group

### Enhanced Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
├─────────────────────────────────────────────────────────────┤
│ ExerciseLibraryView │ ExerciseDetailView │ AddExerciseView   │
│ (Enhanced)          │ (New)             │ (Enhanced)        │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                             │
├─────────────────────────────────────────────────────────────┤
│ ExerciseService     │ ExerciseRepository │ ExerciseModel    │
│ (New)              │ (New)              │ (Enhanced)       │
└─────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
├─────────────────────────────────────────────────────────────┤
│ ExerciseCatalog     │ ExerciseAssets     │ Core Data        │
│ (Enhanced)          │ (New)             │ (Existing)       │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### Enhanced Exercise Model

```swift
struct Exercise: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let muscleGroup: MuscleGroup
    let requiredEquipment: Set<String>
    
    // New properties
    let description: String
    let instructions: [String]
    let safetyTips: [String]
    let targetMuscles: [String]
    let secondaryMuscles: [String]
    let difficulty: DifficultyLevel
    let variations: [ExerciseVariation]
    let imageName: String?
    let animationName: String?
}

enum DifficultyLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate" 
    case advanced = "Advanced"
}

struct ExerciseVariation: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let difficultyModifier: Int // -1 easier, 0 same, +1 harder
}
```

### Exercise Service Layer

```swift
protocol ExerciseServiceProtocol {
    func getAllExercises() -> [Exercise]
    func getExercises(for muscleGroup: MuscleGroup, 
                     availableEquipment: Set<String>) -> [Exercise]
    func getExercisesWithEquipmentHints(for muscleGroup: MuscleGroup,
                                       availableEquipment: Set<String>) -> [ExerciseDisplayItem]
    func getExercise(by id: UUID) -> Exercise?
}

struct ExerciseDisplayItem {
    let exercise: Exercise
    let isAvailable: Bool
    let missingEquipment: Set<String>
}
```

### Enhanced Exercise Catalog

The current static catalog will be expanded to include:
- **Expanded Exercise Database**: 60+ exercises across all muscle groups
- **Rich Metadata**: Descriptions, instructions, safety tips, muscle targeting
- **Equipment Variations**: Multiple exercises per equipment type
- **Difficulty Progression**: Beginner to advanced variations

### Asset Management System

```swift
struct ExerciseAssets {
    static func getImage(for exerciseName: String) -> UIImage?
    static func getAnimation(for exerciseName: String) -> URL?
    static func getInstructionImages(for exerciseName: String) -> [UIImage]
}
```

#### Image Sourcing Strategy

**Phase 1 - SF Symbols & Simple Graphics**
- Use SF Symbols for exercise icons (e.g., `figure.strengthtraining.traditional`, `dumbbell`)
- Create simple vector illustrations using SF Symbols combinations
- Leverage system icons for equipment representation

**Phase 2 - Custom Illustrations** 
- Commission simple line-art style illustrations matching VoltLift's design system
- Focus on key form points rather than photorealistic images
- Use consistent color palette (VLPrimary, VLSecondary) for highlighting

**Phase 3 - Animation Enhancement**
- Simple SwiftUI animations showing exercise motion
- Lottie animations for complex movements (optional future enhancement)
- Animated SF Symbol transitions for basic movements

**Fallback Strategy**
- Always provide SF Symbol fallbacks for missing custom images
- Text-based descriptions as primary information source
- Progressive enhancement approach - app works fully without images

## Data Models

### Core Data Extensions

While maintaining HealthKit as the source of truth, we'll extend the existing Core Data model for exercise metadata caching:

```xml
<entity name="ExerciseMetadata">
    <attribute name="exerciseId" attributeType="UUID"/>
    <attribute name="name" attributeType="String"/>
    <attribute name="lastUsed" attributeType="Date"/>
    <attribute name="personalNotes" attributeType="String" optional="YES"/>
    <attribute name="customWeight" attributeType="Double" optional="YES"/>
</entity>
```

### Exercise Database Structure

The enhanced catalog will be organized as:

```swift
struct ExerciseDatabase {
    static let exercises: [Exercise] = [
        // Bodyweight exercises (no equipment)
        Exercise(
            name: "Push-up",
            muscleGroup: .chest,
            requiredEquipment: [],
            description: "A fundamental upper body exercise targeting chest, shoulders, and triceps.",
            instructions: [
                "Start in plank position with hands shoulder-width apart",
                "Lower body until chest nearly touches ground",
                "Push back up to starting position"
            ],
            safetyTips: [
                "Keep core engaged throughout movement",
                "Maintain straight line from head to heels"
            ],
            targetMuscles: ["Pectoralis Major", "Anterior Deltoid", "Triceps"],
            secondaryMuscles: ["Core", "Serratus Anterior"],
            difficulty: .beginner,
            variations: [
                ExerciseVariation(name: "Knee Push-up", description: "Easier variation on knees", difficultyModifier: -1),
                ExerciseVariation(name: "Diamond Push-up", description: "Hands in diamond shape", difficultyModifier: 1)
            ],
            imageName: "pushup_demo",
            animationName: "pushup_animation"
        ),
        // ... expanded catalog with 60+ exercises
    ]
}
```

## Error Handling

### Equipment Availability
- **Missing Equipment**: Clear visual indicators when exercises require unavailable equipment
- **Partial Equipment**: Show exercises that can be modified with available equipment
- **No Equipment**: Always show bodyweight alternatives

### Asset Loading
- **Missing Images**: Fallback to system SF Symbols
- **Animation Failures**: Graceful degradation to static images
- **Network Issues**: All assets bundled locally for offline access

### Data Consistency
- **Exercise Updates**: Maintain backward compatibility with existing workout plans
- **HealthKit Integration**: Preserve existing workout data structure
- **Migration**: Seamless upgrade from current exercise system

## Testing Strategy

### Unit Tests
- **Exercise Filtering**: Test equipment-based filtering logic
- **Data Models**: Validate exercise model properties and relationships
- **Service Layer**: Test exercise retrieval and filtering methods

### Integration Tests
- **HealthKit Integration**: Ensure new exercises map correctly to HealthKit categories
- **Core Data**: Test exercise metadata persistence
- **Asset Loading**: Verify image and animation loading

### UI Tests
- **Exercise Selection Flow**: Test complete exercise selection and addition
- **Equipment Filtering**: Verify equipment indicators and filtering behavior
- **Exercise Detail View**: Test exercise information display and navigation

### Performance Tests
- **Catalog Loading**: Ensure fast exercise catalog initialization
- **Image Loading**: Test asset loading performance
- **Memory Usage**: Monitor memory consumption with expanded exercise data

## Implementation Phases

### Phase 1: Enhanced Data Model & SF Symbols
- Expand Exercise struct with new properties
- Create enhanced ExerciseCatalog with 60+ exercises using SF Symbol icons
- Implement ExerciseService layer
- Add SF Symbol-based exercise representations

### Phase 2: Equipment Enhancement
- Add equipment availability indicators using SF Symbols
- Implement "show all exercises" functionality
- Create equipment requirement hints with icon representations

### Phase 3: Exercise Details & Custom Assets
- Build ExerciseDetailView with descriptions and instructions
- Add custom illustration support (with SF Symbol fallbacks)
- Implement exercise variations display
- Create simple custom icons for key exercises

### Phase 4: Integration & Polish
- Integrate with existing workout flow
- Add Core Data caching for user preferences
- Performance optimization and testing
- Optional: Add simple SwiftUI animations for exercise demonstrations

## Visual Design Integration

Following VoltLift's design system:
- **VLGlassCard**: Exercise cards with equipment indicators
- **Color System**: Equipment availability using VLSuccess/VLWarning colors
- **Typography**: DesignSystem.Typography for consistent text hierarchy
- **Navigation**: Maintain existing NavigationStack patterns
- **Accessibility**: Full VoiceOver support for all exercise information
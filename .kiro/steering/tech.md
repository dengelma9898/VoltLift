# VoltLift Technical Stack

## Platform & Framework
- **Platform**: iOS (Swift 6.0)
- **UI Framework**: SwiftUI with Combine/Swift Concurrency
- **Architecture**: Modular layers (UI, Domain, HealthKit-Adapter, Sensors)
- **Data**: Core Data + HealthKit as source of truth
- **Minimum iOS Version**: iOS 17+ (inferred from SwiftUI usage)

## Key Dependencies & Frameworks
- **HealthKit**: Primary data store for all workout and health data
- **Core Location**: GPS tracking for outdoor workouts
- **Core Data**: Local caching and app-specific data
- **SwiftUI**: Declarative UI framework
- **Swift Concurrency**: Async/await for data operations

## Build System & Tools
- **Build System**: Xcode project with standard iOS build pipeline
- **Code Formatting**: SwiftFormat (4-space indentation, 120 char line limit)
- **Linting**: SwiftLint with strict rules and opt-in best practices
- **Pre-commit Hooks**: Automated SwiftFormat and SwiftLint checks

## Common Commands
```bash
# Format code
swiftformat --config .swiftformat .

# Lint code
swiftlint --config .swiftlint.yml

# Build project (from VoltLift directory)
xcodebuild -project VoltLift.xcodeproj -scheme VoltLift build

# Run tests
xcodebuild test -project VoltLift.xcodeproj -scheme VoltLift -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Code Quality Standards
- **Line Length**: 120 characters max
- **Indentation**: 4 spaces (no tabs)
- **Swift Version**: 6.0
- **Force Unwrapping**: Error level (avoid at all costs)
- **Function Length**: 80 lines warning, 200 lines error
- **Type Length**: 300 lines warning, 400 lines error

## Future Tech Considerations
- **watchOS Companion**: HKWorkoutSession, WatchConnectivity
- **AI/ML**: Core ML for on-device training suggestions
- **Background Processing**: Efficient outdoor workout tracking
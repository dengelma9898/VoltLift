# Implementation Plan

- [x] 1. Create enhanced data models for exercise customization
  - Implement ExerciseSet model with id, setNumber, reps, weight, setType, completion tracking
  - Implement SetType enum with warmUp, normal, coolDown cases and display properties
  - Update ExerciseData model to use array of ExerciseSet instead of simple set count
  - Add computed properties for backward compatibility (totalSets, averageReps, averageWeight)
  - Write comprehensive unit tests for new data models
  - _Requirements: 1.1, 2.1, 3.1, 4.1_

- [x] 2. Implement Core Data schema updates and migration
  - Update PlanExercise entity to store setsData as Binary attribute (JSON serialized)
  - Add computed attributes for totalSets and averageWeight for query optimization
  - Implement data migration logic to convert existing simple exercise data to set-based structure
  - Create migration tests to ensure existing workout plans are preserved
  - _Requirements: 5.1, 5.3_

- [ ] 3. Create ExerciseCustomizationService for exercise modification operations
  - Implement updateExerciseSet method with validation for reps, weight, and setType parameters
  - Implement addSetToExercise method with intelligent default value initialization
  - Implement removeSetFromExercise method with set numbering updates and minimum set validation
  - Implement reorderSets method for drag-and-drop set reordering
  - Add comprehensive error handling and validation for all operations
  - Write unit tests for all service methods
  - _Requirements: 1.2, 1.3, 1.4, 4.2, 4.3, 4.4, 4.5_

- [ ] 4. Implement validation engine for exercise parameters
  - Create ValidationError enum with specific error cases for reps, weight, and set structure
  - Implement validateSetParameters method with range checking (reps: 1-50, weight: 0-1000)
  - Implement validateExerciseStructure method for set ordering and numbering validation
  - Add auto-correction functionality for out-of-range values
  - Write comprehensive validation tests covering edge cases and error scenarios
  - _Requirements: 1.3, 3.3, 3.4, 3.5, 4.5_

- [ ] 5. Create SetEditorView component for individual set parameter editing
  - Implement UI for editing reps, weight, and set type with proper input validation
  - Add SetTypePickerView with visual indicators and icons for each set type
  - Implement real-time validation feedback with clear error messages
  - Add accessibility support with proper labels and VoiceOver compatibility
  - Write UI tests for set editing workflows and validation feedback
  - _Requirements: 2.1, 2.2, 3.1, 3.2, 3.5_

- [ ] 6. Create ExerciseCustomizationView for detailed exercise editing
  - Implement exercise header with name and basic information display
  - Add set list with drag-and-drop reordering capability
  - Implement add/remove set functionality with confirmation dialogs
  - Add save/cancel actions with unsaved changes handling
  - Integrate SetEditorView components for individual set editing
  - Write UI tests for complete exercise customization workflow
  - _Requirements: 1.2, 1.5, 2.2, 4.1, 4.2, 4.3, 4.4_

- [ ] 7. Create PlanCustomizationView for workout plan overview and editing
  - Implement workout plan header with plan name and summary statistics
  - Add exercise list showing customized parameters (sets, reps, weights, types)
  - Implement navigation to ExerciseCustomizationView for detailed editing
  - Add plan-level actions (save, reset, duplicate)
  - Integrate with existing workout plan navigation structure
  - Write UI tests for plan customization navigation and overview display
  - _Requirements: 6.1, 6.2, 1.1, 1.2_

- [ ] 8. Integrate customization features with existing workout execution system
  - Update WorkoutExecutionView to display set types with appropriate visual indicators
  - Implement set completion tracking with setType-aware progress display
  - Add quick parameter adjustment capability during workout execution
  - Update set progression logic to handle different set types appropriately
  - Ensure workout timer and rest periods work correctly with customized sets
  - Write integration tests for workout execution with customized plans
  - _Requirements: 6.3, 6.4, 6.5, 2.3, 2.4_

- [ ] 9. Implement HealthKit integration for detailed workout data synchronization
  - Update HealthKit workout creation to include individual set data and repetition types
  - Implement structured workout data with proper set grouping and metadata
  - Add retry logic and error handling for HealthKit synchronization failures
  - Ensure privacy compliance and respect user preferences for detailed tracking
  - Write integration tests for HealthKit sync with customized workout data
  - _Requirements: 5.2, 5.4, 5.5_

- [ ] 10. Add comprehensive error handling and user feedback systems
  - Implement graceful degradation for corrupted set data with fallback to defaults
  - Add undo functionality for exercise modifications with change tracking
  - Implement loading states and progress indicators for customization operations
  - Add success/error toast notifications for save operations
  - Create comprehensive error recovery workflows for validation failures
  - Write error handling tests covering network failures and data corruption scenarios
  - _Requirements: 1.5, 3.5, 5.5_

- [ ] 11. Implement performance optimizations for large workout plans
  - Add lazy loading for detailed set data to improve initial plan loading performance
  - Implement batch operations for multiple set modifications
  - Add caching strategy for frequently accessed customization data
  - Optimize Core Data queries with proper indexing and fetch request optimization
  - Write performance tests for plans with many exercises and sets
  - _Requirements: 5.1, 5.3_

- [ ] 12. Create comprehensive test suite for workout plan customization feature
  - Write unit tests for all data models, services, and validation logic
  - Create integration tests for Core Data persistence and HealthKit synchronization
  - Implement UI tests for complete user workflows from plan selection to workout execution
  - Add accessibility tests ensuring VoiceOver compatibility for all customization features
  - Create performance tests for large dataset handling and real-time validation
  - Write migration tests ensuring backward compatibility with existing data
  - _Requirements: All requirements - comprehensive testing coverage_
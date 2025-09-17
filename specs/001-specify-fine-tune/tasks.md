# Tasks: Feintuning des generierten Trainingsplans

**Input**: Design documents from `/Users/dengelma/develop/private/VoltLift/specs/001-specify-fine-tune/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
2. Load optional design documents (data-model.md, contracts/, research.md, quickstart.md)
3. Generate tasks by category (Setup → Tests → Models → Services → UI → Integration → Polish)
4. Mark [P] for truly independent files
5. Number tasks sequentially (T001, T002...)
6. Provide dependency notes and parallel examples
7. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Phase 3.1: Setup
- [x] T001 Configure SwiftLint & SwiftFormat and verify locally (run in repo root)
  - Command: `swiftformat . && swiftlint`
- [x] T002 Update docs cross-links (add UX principles to quickstart)
  - File: `/Users/dengelma/develop/private/VoltLift/specs/001-specify-fine-tune/quickstart.md`

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
- [ ] T010 [P] Contract tests: Plan Editor use-cases (UC1–UC3)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/PlanEditorUseCaseTests.swift`
  - Cover: Add/Remove/Reorder, Edit Set Attributes, Save Plan, validation errors
- [ ] T011 [P] Contract tests: Workout Logging use-cases (UC4–UC5)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutLoggingUseCaseTests.swift`
  - Cover: Record Set Weight (equipment-only), Per-Rep Difficulty (1–10), length mismatch
- [ ] T012 [P] Integration UI tests: Plan-Editor Flows (Acceptance 1,2,6)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLiftUITests/PlanEditorUITests.swift`
  - Steps: Manuell erstellten, equipment-basierten Plan öffnen → Editieren → Speichern/Abbruchdialog
- [ ] T013 [P] Integration UI tests: Workout-Logging (Acceptance 7)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLiftUITests/WorkoutLoggingUITests.swift`
  - Steps: Aktives Workout → Gewicht (0,5 kg Schritte) und Schwierigkeit 1–10 erfassen → Beenden → Persistenz prüfen
- [ ] T014 [P] Data-Model validation tests
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/DataModelValidationTests.swift`
  - Cover: reps ≥ 0, setType Enum, unilateral nur wenn erlaubt, weight steps 0.5, difficulty 1..10

## Phase 3.3: Core Implementation (ONLY after tests are failing)
- [ ] T020 [P] Create plan models (WorkoutPlan, PlanExercise, ExerciseSet)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/Models/WorkoutPlanModels.swift`
  - Include: fields, equatable, validation helpers
- [ ] T021 [P] Create execution models (WorkoutSetEntry)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/Models/WorkoutExecutionModels.swift`
  - Include: difficulty array (1–10), weightKg optional, validation
- [ ] T022 PlanEditorService (UC1–UC3)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/Services/PlanEditorService.swift`
  - Methods: addSet/removeSet/moveSet, editSetAttributes, savePlan
- [ ] T023 WorkoutLoggingService (UC4–UC5)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/Services/WorkoutLoggingService.swift`
  - Methods: recordSetWeight(equipment-only), recordPerRepDifficulty
- [ ] T024 [P] ViewModels for Editor & Logging
  - Files:
    - `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/UI/Workout/PlanEditorViewModel.swift`
    - `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/UI/Workout/WorkoutLoggingViewModel.swift`
  - Responsibilities: state, validation, bind to services
- [ ] T025 SwiftUI Views for Editor & Logging
  - Files:
    - `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/UI/Workout/PlanEditorView.swift`
    - `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/UI/Workout/WorkoutLoggingView.swift`
  - Controls: Picker/Stepper, SegmentedControl, Side toggle, Comment field, Weight stepper, Difficulty capture
- [ ] T026 Taxonomy: unilateral criteria in metadata
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/Extensions/ExerciseMetadata+Extensions.swift`
  - Add: `allowsUnilateral` mapping/logic per exercise type
- [ ] T027 Persistence integration (Core Data)
  - Files:
    - `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/Core Data/PersistenceController.swift`
    - Core Data model updates as needed (`VoltLift.xcdatamodeld`)
  - Persist: plan edits on explicit save; workout entries on finish

## Phase 3.4: Integration
- [ ] T030 Wire services into existing flows
  - Files:
    - `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/Services/ExerciseCustomizationService.swift`
    - `/Users/dengelma/develop/private/VoltLift/VoltLift/Resources/UI/Workout/ExerciseService.swift`
  - Ensure: plan models used in UI, logging routes to services
- [ ] T031 HealthKit write path review
  - Confirm: difficulty is local-only (not in HK); weight written where supported; no duplicates
  - Files: HealthKit adapter files (identify and update if needed)
- [ ] T032 Update quickstart with UX link
  - File: `/Users/dengelma/develop/private/VoltLift/specs/001-specify-fine-tune/quickstart.md`
  - Add: Link zu `/Users/dengelma/develop/private/VoltLift/Docs/UX_PRINCIPLES.md`

## Phase 3.5: Polish
- [ ] T040 [P] Unit tests for edge validations (negative, overflow, mismatch)
  - File: `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/ValidationEdgeCaseTests.swift`
- [ ] T041 [P] Accessibility pass (Dynamic Type, labels, contrast)
  - Review: new views under `Resources/UI/Workout/`
- [ ] T042 [P] Docs: ensure UX principles reflected in components
  - File: `/Users/dengelma/develop/private/VoltLift/Docs/UX_PRINCIPLES.md`

## Dependencies
- Tests (T010–T014) before implementation (T020+)
- Models (T020–T021) before services (T022–T023)
- Services before ViewModels/Views (T024–T025)
- Taxonomy (T026) before enabling unilateral UI options
- Persistence (T027) before finishing flows and UI assertions

## Parallel Example
```
# Launch independent test tasks together:
Task: "T010 Contract tests Plan Editor"
Task: "T011 Contract tests Workout Logging"
Task: "T012 UI tests Plan Editor"
Task: "T013 UI tests Workout Logging"
Task: "T014 Data-Model validation tests"

# After tests failing, parallelize model creation:
Task: "T020 Create plan models"
Task: "T021 Create execution models"
```

## Validation Checklist
- [ ] All contracts have corresponding tests (T010–T013)
- [ ] All entities have model tasks (T020–T021)
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task

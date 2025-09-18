# Tasks: Start Workout Flow

**Input**: Spec from `/Users/dengelma/develop/private/VoltLift/specs/002-description-start-workout/`
**Prerequisites**: plan.md (this), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
2. Load design docs (data-model.md, contracts/, research.md, quickstart.md)
3. Generate tasks by category (Models → Services → UI → Integration → Tests → Polish)
4. Number tasks sequentially (T001, T002...)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)

## Models
- [P] T001 Add WorkoutSession model (if not present) and session state storage
  - File: `VoltLift/VoltLift/Resources/Models/WorkoutExecutionModels.swift`
- [P] T002 Extend WorkoutSetEntry with repIndex and sessionId if needed
  - File: `VoltLift/VoltLift/Resources/Models/WorkoutExecutionModels.swift`

## Services
- T010 WorkoutLoggingService: startWorkout(planId), finishWorkout(sessionId), cancelWorkout(sessionId)
  - File: `VoltLift/VoltLift/Resources/Services/WorkoutLoggingService.swift`
- T011 WorkoutLoggingService: confirmRep(sessionId, planExerciseId, setIndex, repIndex, weightKg?, difficulty)
  - File: `VoltLift/VoltLift/Resources/Services/WorkoutLoggingService.swift`
- T012 Timer handling: 120s rest with callbacks; haptic/jingle emission at end
  - File: `VoltLift/VoltLift/Resources/Services/WorkoutLoggingService.swift`
- T013 Apply PlanChangeDuringSession on finish; discard on cancel
  - Files: `WorkoutLoggingService.swift`, `PlanEditorService.swift`

## ViewModels
- T020 WorkoutLoggingViewModel: session state (exercise/set/rep indices), bind to service, timer state
  - File: `VoltLift/VoltLift/Resources/UI/Workout/WorkoutLoggingViewModel.swift`

## UI
- T030 WorkoutLoggingView: per‑exercise paging (ScrollView + TabView/Page), VLGlassCard sections
  - File: `VoltLift/VoltLift/Resources/UI/Workout/WorkoutLoggingView.swift`
- T031 Rep confirmation UI: weight (step 0.5 for equipment), difficulty (1–10), confirm CTA
  - File: `WorkoutLoggingView.swift`
- T032 Timer UI: show remaining 2:00, auto‑start/stop, no manual controls; haptic/jingle on end
  - File: `WorkoutLoggingView.swift`
- T033 Summary view after finish/cancel (cards: duration, reps/sets, stats, plan changes)
  - File: `VoltLift/VoltLift/Resources/UI/Workout/WorkoutSummaryView.swift`
- T034 Navigation: Start Workout from PlanDetailView; auto‑advance to next exercise; manual swipe
  - Files: `PlanDetailView.swift`, `WorkoutLoggingView.swift`
- T035 Prevent editing other plans while session active (disable routes/toolbar actions)
  - Files: `WorkoutSetupView.swift`, `PlanEditorView.swift`

## Integration & Persistence
- T040 Persist WorkoutSetEntry incrementally; persist session lifecycle; summary aggregation
  - Files: `PersistenceController.swift`

## Tests
- [P] T050 Contract tests for Workout Session (UC1–UC8)
  - File: `VoltLift/VoltLiftTests/WorkoutSessionUseCaseTests.swift`
- [P] T051 UI tests: Start → reps with timer → auto‑advance → finish summary
  - File: `VoltLift/VoltLiftUITests/WorkoutSessionUITests.swift`
- [P] T052 UI tests: Cancel‑Pfad (persist execution data, discard plan changes)
  - File: `VoltLift/VoltLiftUITests/WorkoutSessionUITests.swift`

## Polish
- T060 SwiftFormat/SwiftLint clean‑up
- T061 Accessibility pass (Dynamic Type, labels, contrast)

## Dependencies
- Models before Services; Services before ViewModels/Views
- Start navigation requires basic ViewModel/Service hooks



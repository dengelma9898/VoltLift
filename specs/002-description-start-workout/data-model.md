# Data Model: Start Workout Session

## Entities
- WorkoutSession
  - id: UUID
  - planId: UUID
  - startedAt: Date
  - finishedAt: Date?
  - status: {active, finished, canceled}
  - currentExerciseIndex: Int (≥ 0)
  - setIndex: Int (≥ 0)
  - repIndex: Int (≥ 0)
  - restDurationSeconds: Int (fixed 120)
  - restTimerRemainingSeconds: Int (≥ 0)
  - hapticOnTimerEnd: Bool (default true)

- WorkoutSetEntry
  - id: UUID
  - sessionId: UUID
  - planExerciseId: UUID
  - setIndex: Int (≥ 0)
  - repIndex: Int (≥ 0)
  - weightKg: Decimal? (≥ 0, step 0.5; nil für Körpergewicht)
  - difficulty: Int (1..10)
  - timestamp: Date

- PlanChangeDuringSession
  - id: UUID
  - sessionId: UUID
  - operation: {addSet, removeSet, moveSet, editSetAttributes}
  - payload: opaque (indices/values je nach Operation)

## Relationships
- WorkoutSession 1–* WorkoutSetEntry (erfasste Wiederholungen)
- WorkoutSession 1–* PlanChangeDuringSession (eingestreute Planänderungen)
- WorkoutPlan 1–* PlanExercise 1–* ExerciseSet (aus 001‑Spezifikation)

## Validation Rules
- repIndex, setIndex, currentExerciseIndex, weightKg, difficulty gemäß Grenzen oben.
- Gewicht nur bei Equipment‑Übungen; ansonsten `weightKg == nil`.
- Schwierigkeit Länge == ausgeführte Wiederholungen pro Satz.

## State Transitions
- Session: active → finished | canceled
- On finished: apply PlanChangeDuringSession to underlying Plan.
- On canceled: discard PlanChangeDuringSession; persist WorkoutSetEntry.



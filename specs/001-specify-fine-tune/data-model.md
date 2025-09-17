# Data Model: Feintuning des generierten Trainingsplans

## Entities
- WorkoutPlan
  - id
  - name
  - exercises: [PlanExercise]

- PlanExercise
  - id
  - referenceExerciseId (aus Katalog)
  - displayName
  - allowsUnilateral (aus Taxonomie)
  - sets: [ExerciseSet]

- ExerciseSet (Plan)
  - id
  - reps: Int (≥ 0)
  - setType: {warmUp, normal, coolDown}
  - side: {both, unilateral}
  - comment: String? (optional)

- WorkoutSetEntry (Ausführung)
  - id
  - planExerciseId (Bezug)
  - setIndex (0-based)
  - weightKg: Decimal (≥ 0, Schrittweite 0,5) | null bei Körpergewicht
  - difficulties: [Int 1..10] (eine pro Wiederholung)
  - timestamp

## Relationships
- WorkoutPlan 1–* PlanExercise
- PlanExercise 1–* ExerciseSet
- Workout (laufend) 1–* WorkoutSetEntry (pro ausgeführtem Satz)

## Validation Rules
- reps ≥ 0; setType ∈ {warmUp, normal, coolDown}
- side ∈ {both, unilateral}; unilateral nur wenn allowsUnilateral == true
- weightKg nur bei Equipment-Übungen; Schrittweite 0,5; ≥ 0
- difficulties Länge == ausgeführte Wiederholungen; Werte ∈ 1..10

## State Transitions
- Plan: Draft → Saved (explizites Speichern)
- Workout: Active → Finished (Persistenz der WorkoutSetEntries beim Beenden)

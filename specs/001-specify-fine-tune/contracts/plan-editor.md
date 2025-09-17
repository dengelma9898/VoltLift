# Contract: Plan Editor Use-Cases

## UC1: Add/Remove/Reorder Sets
- Input: planId, exerciseId, action(add|remove|move), payload(indexes)
- Output: Updated PlanExercise
- Errors: IndexOutOfRange, EditLocked (wenn nicht laufender Plan während aktivem Workout)

## UC2: Edit Set Attributes
- Input: planId, exerciseId, setIndex, reps(Int ≥0), setType(Enum), side(Enum), comment(String?)
- Output: Updated ExerciseSet
- Errors: InvalidValue, NotAllowed(UnilateralNotSupported)

## UC3: Save Plan
- Input: planId
- Output: Success
- Errors: ValidationFailed

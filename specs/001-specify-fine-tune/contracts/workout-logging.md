# Contract: Workout Logging Use-Cases

## UC4: Record Set Weight
- Preconditions: Active workout; exercise uses equipment
- Input: workoutId, planExerciseId, setIndex, weightKg(Decimal step 0.5, ≥0)
- Output: Updated WorkoutSetEntry.weightKg
- Errors: NotActiveWorkout, NoEquipment, InvalidValue

## UC5: Record Per-Rep Difficulty
- Preconditions: Active workout
- Input: workoutId, planExerciseId, setIndex, difficulties([Int 1..10], length==reps)
- Output: Updated WorkoutSetEntry.difficulties
- Errors: NotActiveWorkout, InvalidValue, LengthMismatch

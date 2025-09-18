# Contract: Workout Session Use-Cases

## UC1: Start Workout
- Input: planId
- Output: WorkoutSession(active), first exercise page loaded
- Errors: PlanNotFound, SessionAlreadyActive

## UC2: Confirm Rep
- Preconditions: Active session; exercise/set/rep in range
- Input: sessionId, planExerciseId, setIndex, repIndex, weightKg(Decimal step 0.5, ≥0)? , difficulty(Int 1..10)
- Output: WorkoutSetEntry created; RestTimer(start: now, duration: 120s)
- Errors: NotActive, InvalidValue, NoEquipment(weight specified but exercise has none)

## UC3: Rest Timer Elapsed
- Preconditions: Timer running
- Input: sessionId
- Output: Haptic/Jingle triggered; UI prompt for next rep (or next exercise if last rep)
- Errors: NotActive, TimerNotRunning

## UC4: Auto‑Advance After Exercise Complete
- Input: sessionId, planExerciseId
- Output: Navigate to next exercise page (if any)
- Errors: NotActive

## UC5: Cancel Workout
- Input: sessionId
- Output: Session(canceled); Persist all WorkoutSetEntry; Discard PlanChangeDuringSession; Show summary
- Errors: NotActive

## UC6: Finish Workout
- Preconditions: Last rep of last exercise confirmed
- Input: sessionId
- Output: Session(finished); Persist all WorkoutSetEntry; Apply PlanChangeDuringSession to Plan; Show summary
- Errors: NotActive

## UC7: Edit Plan During Session
- Preconditions: Active session
- Input: sessionId, operation(addSet|removeSet|moveSet|editSetAttributes), payload
- Output: PlanChangeDuringSession recorded (applied on finish)
- Errors: NotActive, InvalidOperation

## UC8: Restrict Parallel Editing
- Preconditions: Active session
- Rule: Block editing of any other plan until session is finished or canceled



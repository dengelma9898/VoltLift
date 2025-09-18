## Tasks: Start Workout Flow (Feature 002 - description-start-workout)

**Input**: Design documents from `/Users/dengelma/develop/private/VoltLift/specs/002-description-start-workout/`
**Prerequisites**: `plan.md` (required), `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

Repository root: `/Users/dengelma/develop/private/VoltLift`
Feature dir: `/Users/dengelma/develop/private/VoltLift/specs/002-description-start-workout`

### Format
`[ID] [P?] Description`
- **[P]**: Kann parallel laufen (verschiedene Dateien, keine gegenseitigen Abhängigkeiten)
- Alle Pfade absolut
- TDD: Tests zuerst; Modelle → Services → UI → Integration → Polish

### Phase 3.1: Setup
1. T001 Prüfe Tooling: Swift 6, Xcode 26, iOS 18.6 Simulator; richte lokale Lint/Format-Checks ein (SwiftFormat/SwiftLint) und pre-commit Hook. [DONE]
   - Pfade: `/Users/dengelma/develop/private/VoltLift/.swiftlint.yml`, `/Users/dengelma/develop/private/VoltLift/.swiftformat`, Git Hook unter `.git/hooks/pre-commit`
   - Ergebnis: `swiftformat .` und `swiftlint` laufen clean.
2. T002 [P] Verifiziere Build-Ziel und Scheme für iOS (Simulator iPhone 16/17) und greife per Agent darauf zu. [DONE]
   - Pfade: `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift.xcodeproj`, Scheme `VoltLift`
3. T003 [P] Simulator-Build-Check: Baue und starte App auf iOS-Simulator per Agent. [DONE]
   - Aktion: Build+Run auf `iPhone 16` (oder `iPhone 17`) ausführen; sicherstellen, dass Startbildschirm erscheint.

### Phase 3.2: Tests First (TDD) – Muss vor 3.3 fertig sein
Contract: `/Users/dengelma/develop/private/VoltLift/specs/002-description-start-workout/contracts/workout-session.md`

4. T004 [P] Contract-Test UC1 Start Workout in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutSessionUC1_StartWorkoutTests.swift` (Service-API, Fehlerfälle).
5. T005 [P] Contract-Test UC2 Confirm Rep in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutSessionUC2_ConfirmRepTests.swift` (Gewicht 0,5‑Schritt, ≥0; Schwierigkeit 1–10; NoEquipment).
6. T006 [P] Contract-Test UC3 Rest Timer Elapsed in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutSessionUC3_RestTimerElapsedTests.swift` (Timer 120s, Signal).
7. T007 [P] Contract-Test UC4 Auto‑Advance After Exercise Complete in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutSessionUC4_AutoAdvanceTests.swift`.
8. T008 [P] Contract-Test UC5 Cancel Workout in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutSessionUC5_CancelWorkoutTests.swift` (Persistiert SetEntries; verwirft Planänderungen).
9. T009 [P] Contract-Test UC6 Finish Workout in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutSessionUC6_FinishWorkoutTests.swift` (Persistiert und wendet Planänderungen an).
10. T010 [P] Contract-Test UC7 Edit Plan During Session in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutSessionUC7_EditPlanDuringSessionTests.swift`.
11. T011 [P] Contract-Test UC8 Restrict Parallel Editing in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/WorkoutSessionUC8_RestrictParallelEditingTests.swift`.
12. T012 [P] Integration-UI-Test „Quickstart Smoke-Test“ in `/Users/dengelma/develop/private/VoltLift/VoltLiftUITests/WorkoutSessionFlowUITests.swift` gemäß `quickstart.md` (Start → Rep bestätigen → Timer → Auto‑Advance → Finish/Cancel Pfade).

### Phase 3.3: Core Implementation (nachdem Tests fehlschlagen)
Data Model: `/Users/dengelma/develop/private/VoltLift/specs/002-description-start-workout/data-model.md`

13. T013 [P] Modell anlegen: `WorkoutSession` (Domain) in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/Models/WorkoutSessionModels.swift` (Felder: id, planId, startedAt, finishedAt?, status, currentExerciseIndex, setIndex, repIndex, restDurationSeconds=120, restTimerRemainingSeconds, hapticOnTimerEnd=true).
14. T014 [P] Modell anlegen: `PlanChangeDuringSession` (Domain) in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/Models/PlanChangeDuringSessionModels.swift` (operation+payload opaque).
15. T015 Aktualisiere `WorkoutSetEntry` falls nötig, um Validierung/Constraints aus Datenmodell sicherzustellen (≥0, 0,5‑Schritte; Schwierigkeit 1–10, Länge == Reps) in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/Models/WorkoutExecutionModels.swift` (keine API‑Brüche, Tests grün machen).

Services & Timer & Haptik
16. T016 Service implementieren: `WorkoutSessionService` (UC1–UC8) in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/Services/WorkoutSessionService.swift` (Swift Concurrency, protokollbasierte DI; keine UI‑Abhängigkeiten).
17. T017 [P] Timer‑Service implementieren: `RestTimerService` in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/Services/RestTimerService.swift` (fix 120s, Start bei Rep‑Bestätigung, keine manuelle Steuerung; liefert Ticks/Completion).
18. T018 [P] Haptik/Jingle‑Adapter implementieren: `HapticsService` in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/Services/HapticsService.swift` (CoreHaptics/AudioServices; einfache API `signalTimerEnd()`).

Persistence (Core Data)
19. T019 Core‑Data‑Model erweitern: Neue Modellversion `VoltLift 4.xcdatamodel` in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/VoltLift.xcdatamodeld/` mit Entities `WorkoutSession`, `WorkoutSetEntry`, `PlanChangeDuringSession` gemäß Datenmodell; Migrationspfad erstellen.
20. T020 Repository/Adapter implementieren: `WorkoutSessionRepository` in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/Services/WorkoutSessionRepository.swift` (CRUD für Session, SetEntries, PlanChangeDuringSession; Integration `PersistenceController.swift`).

UI & Navigation
21. T021 ViewModel implementieren: `WorkoutSessionViewModel` in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/UI/Workout/WorkoutSessionViewModel.swift` (bindet `WorkoutSessionService`, `RestTimerService`, `HapticsService`).
22. T022 View implementieren: `WorkoutSessionView` in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/UI/Workout/WorkoutSessionView.swift` (VLGlassCard, Brand‑Background, Bottom‑CTAs; Gewicht/Difficulty Erfassung; Timer‑Anzeige; Auto‑Advance UI‑Flow).
23. T023 `PlanDetailView` verdrahten: onStart navigiert zu `WorkoutSessionView` in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/UI/Workout/PlanDetailView.swift` (Navigation, Übergabe planId/erste Übung).
24. T024 Zusammenfassung implementieren: `WorkoutSummaryView` in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/UI/Workout/WorkoutSummaryView.swift` (Finish/Cancel Pfade, Anzeige der Session‑Daten).
25. T025 Plan‑Edit während Session (UI) implementieren: Sheet/Overlay zur Satz‑/Rep‑Modifikation; Änderungen als `PlanChangeDuringSession` erfassen; in `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/UI/Workout/WorkoutSessionView.swift`.

### Phase 3.4: Integration
26. T026 Services mit Persistence verbinden: `WorkoutSessionService` nutzt `WorkoutSessionRepository` für Persistenz (Start, Confirm, Cancel, Finish) – Dateien siehe T016/T020.
27. T027 [P] Haptik an Timer koppeln: `RestTimerService` Completion → `HapticsService.signalTimerEnd()` (Dateien T017/T018).
28. T028 Fehlerbehandlung & Logging konsolidieren: Domain‑Errors → lokalisierte User‑Meldungen; Mapping im ViewModel (`lastError`) und UI‑Alerts; Pfade: `/Users/dengelma/develop/private/VoltLift/VoltLift/VoltLift/Resources/UI/Workout/*` und Services.

### Phase 3.5: Polish
29. T029 [P] Zusätzliche Unit‑Tests: Validierung (`ExecutionValidation`), `WorkoutSessionService`, `RestTimerService`, `HapticsService` in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/`.
30. T030 [P] Performance‑Tests: Timer/Jitter und UI‑Responsiveness in `/Users/dengelma/develop/private/VoltLift/VoltLiftTests/`.
31. T031 [P] Docs aktualisieren: Ergänze `quickstart.md` um Screenshots/Steps; verweise auf HIG/Design‑System; Pfad: `/Users/dengelma/develop/private/VoltLift/specs/002-description-start-workout/quickstart.md`.
32. T032 [P] Simulator‑Validierung: Baue & starte App; führe Smoke‑Test manuell gemäß Quickstart aus; dokumentiere Ergebnisse in `quickstart.md`.

---

## Abhängigkeiten & Reihenfolge
- Setup (T001–T003) zuerst.
- Tests (T004–T012) vor Implementierung (T013+).
- Modelle (T013–T015) vor Services (T016–T018) vor UI (T021–T025).
- Persistence (T019–T020) vor Service‑Integration (T026).
- Integration (T026–T028) vor Polish (T029–T032).
- [P] nur, wenn unterschiedliche Dateien; Tasks, die dieselben Dateien berühren (z. B. T022 & T025) sind sequenziell.

## Parallel-Ausführung (Beispiele)
```
# Contract-Tests parallel starten (unabhängige Testdateien):
Task: "T004 Contract-Test UC1 Start Workout in VoltLiftTests/WorkoutSessionUC1_StartWorkoutTests.swift"
Task: "T005 Contract-Test UC2 Confirm Rep in VoltLiftTests/WorkoutSessionUC2_ConfirmRepTests.swift"
Task: "T006 Contract-Test UC3 Rest Timer Elapsed in VoltLiftTests/WorkoutSessionUC3_RestTimerElapsedTests.swift"
Task: "T007 Contract-Test UC4 Auto‑Advance in VoltLiftTests/WorkoutSessionUC4_AutoAdvanceTests.swift"
Task: "T008 Contract-Test UC5 Cancel Workout in VoltLiftTests/WorkoutSessionUC5_CancelWorkoutTests.swift"
Task: "T009 Contract-Test UC6 Finish Workout in VoltLiftTests/WorkoutSessionUC6_FinishWorkoutTests.swift"
Task: "T010 Contract-Test UC7 Edit Plan During Session in VoltLiftTests/WorkoutSessionUC7_EditPlanDuringSessionTests.swift"
Task: "T011 Contract-Test UC8 Restrict Parallel Editing in VoltLiftTests/WorkoutSessionUC8_RestrictParallelEditingTests.swift"

# Setup/Build auf Simulator (Beispiel mit Agent-Befehlen):
Task: "T003 Simulator-Build-Check" → Build & Run Scheme `VoltLift` auf `iPhone 16`.
```

## Validierungs-Checkliste
- Alle UCs (UC1–UC8) haben Contract‑Tests (T004–T011).
- Alle Entities aus `data-model.md` haben Modell‑Tasks (T013–T015).
- Tests kommen vor Implementierung (T004–T012 < T013+).
- [P] Tasks ändern keine selben Dateien.
- Alle Tasks nennen absolute Pfade.



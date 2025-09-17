
# Implementation Plan: Feintuning des generierten Trainingsplans

**Branch**: `001-specify-fine-tune` | **Date**: 2025-09-17 | **Spec**: /Users/dengelma/develop/private/VoltLift/specs/001-specify-fine-tune/spec.md
**Input**: Feature specification from `/Users/dengelma/develop/private/VoltLift/specs/001-specify-fine-tune/spec.md`

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, or `GEMINI.md` for Gemini CLI).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
Ziel: Nutzer können automatisch generierte Pläne (aus Equipment-Logik) nachträglich auf Satz-Ebene feinjustieren (Satzanzahl, Wiederholungen, Satztyp, Seite, Kommentar). Gewicht und Schwierigkeit werden nur während eines aktiven Workouts erfasst (Gewicht nur bei Equipment-Übungen, 0,5 kg Schritte, min 0). UX HIG-konform, einfache Optionen statt Freitext, klare Fehlermeldungen, explizites Speichern.

## Technical Context
**Language/Version**: Swift 6 (Xcode 26)
**Primary Dependencies**: SwiftUI, HealthKit, Core Data
**Storage**: Core Data (Pläne/Editorzustand), HealthKit (Workouts/Sätze), lokal nur nötige Metadaten
**Testing**: XCTest (Unit/Integration/UI), SwiftLint/SwiftFormat
**Target Platform**: iOS 18.6+
**Project Type**: mobile (iOS App)
**Performance Goals**: 60 fps UI; selbsterklärende UX; stabile HealthKit-Schreibungen
**Constraints**: HIG-konform, einfache UX (keine Freitexte), offline-freundlich für Planbearbeitung
**Scale/Scope**: Einzel-App, begrenzte Nutzerbasis; Fokus auf Qualität/Robustheit

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Apple-First/HIG: UI folgt HIG und Design System (`Docs/DESIGN_SYSTEM.md`).
- Architektur: Clean Architecture + MVVM, protokollbasierte DI, Swift Concurrency.
- Qualität: SwiftLint/SwiftFormat verpflichtend; Tests an kritischen Stellen.
- DoD: Simulator-Build prüfen; keine WIP-Views; Vision/Design-Konformität.

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
# Option 1: Single project (DEFAULT)
src/
├── models/
├── services/
├── cli/
└── lib/

tests/
├── contract/
├── integration/
└── unit/

# Option 2: Web application (when "frontend" + "backend" detected)
backend/
├── src/
│   ├── models/
│   ├── services/
│   └── api/
└── tests/

frontend/
├── src/
│   ├── components/
│   ├── pages/
│   └── services/
└── tests/

# Option 3: Mobile + API (when "iOS/Android" detected)
api/
└── [same as backend above]

ios/ or android/
└── [platform-specific structure]
```

**Structure Decision**: Mobile (iOS App) – bestehende Xcode-Struktur beibehalten

## Phase 0: Outline & Research
1. Unknowns extrahieren: Kriterien für „einseitig“, Validierungsgrenzen, UI-Interaktion für Schwierigkeit.
2. Best Practices sichten: SwiftUI Editoren (Picker, Stepper), HealthKit-Satzerfassung, Core Data Modellierung.
3. Findings konsolidieren in `research.md` (Entscheidung, Begründung, Alternativen).

**Output**: research.md (erstellt)

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. Entitäten aus der Spezifikation in `data-model.md` modellieren (Felder, Beziehungen, Validierung, Zustände).
2. Use-Case-Verträge in `/contracts/` definieren (Plan-Editor, Workout-Erfassung) als Markdown/Swift-Schnittstellen.
3. Quickstart (`quickstart.md`) mit Build/Run/Smoke-Test für Editor und Workout-Erfassung.
4. Agent-Kontext aktualisieren via Skript.

**Output**: data-model.md, /contracts/*, quickstart.md, aktualisierter Agent-Kontext

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
- [x] Phase 1: Design complete (/plan command)
- [ ] Phase 2: Task planning complete (/plan command - describe approach only)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS
- [x] All NEEDS CLARIFICATION resolved
- [ ] Complexity deviations documented

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*

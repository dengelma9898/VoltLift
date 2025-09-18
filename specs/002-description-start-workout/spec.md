# Feature Specification: Start Workout Flow

**Feature Branch**: `002-description-start-workout`  
**Created**: 2025-09-18  
**Status**: Draft  
**Input**: User description: "Start a workout from a pre-planned plan; allow dynamic plan edits during the workout; confirm each rep with weight and difficulty; auto-start a 2-minute rest timer on confirmation; per-exercise paging with swipe; show exercise descriptions; auto-advance after finishing all reps; show a summary at the end; on cancel show a summary and do not save plan changes; follow Docs/DESIGN_SYSTEM.md."

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., timer between reps vs sets), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## User Scenarios & Testing (mandatory)

### Primary User Story
Als Nutzer möchte ich aus einem vorgeplanten Trainingsplan ein Workout starten, pro Übung auf einer eigenen Seite die Wiederholungen nacheinander bestätigen (mit Gewicht und Schwierigkeit), nach jeder Bestätigung automatisch eine Ruhezeit (2 Minuten) erhalten, und nach Abschluss aller Wiederholungen automatisch zur nächsten Übung wechseln, damit ich mein Training strukturiert und effizient absolvieren kann. Am Ende sehe ich eine Zusammenfassung und meine während des Workouts vorgenommenen Plananpassungen werden übernommen. Breche ich das Workout vorzeitig ab, erhalte ich ebenfalls eine Zusammenfassung, ohne Planänderungen zu speichern.

### Acceptance Scenarios
1. **Given** ein gespeicherter Plan, **When** ich "Start Workout" wähle, **Then** wird das Workout mit den vorgeplanten Übungen/Sätzen geladen und die erste Übung im Seitenlayout angezeigt.
2. **Given** eine Übung mit geplanten Wiederholungen, **When** ich eine Wiederholung ausgeführt habe, **Then** wähle ich Gewicht (in 0,5 kg Schritten, ≥ 0, nur bei Equipment-Übungen) und Schwierigkeit (1–10) und **Then** bestätige ich diese Wiederholung.
3. **Given** ich bestätige eine Wiederholung, **When** die Eingabe gespeichert ist, **Then** startet automatisch ein Ruhe‑Timer mit 2 Minuten (nicht editierbar) zwischen jeder Wiederholung sowie zwischen der letzten Wiederholung einer Übung und der ersten der nächsten Übung; nach der letzten Übung gibt es keinen weiteren Timer.
4. **Given** der Ruhe‑Timer läuft ab, **When** die Zeit endet, **Then** gibt das Gerät haptisches Feedback oder spielt einen kurzen Jingle und fordert mich zur nächsten Wiederholung auf.
5. **Given** alle Wiederholungen einer Übung sind bestätigt, **When** ich die letzte Wiederholung bestätige, **Then** wechselt die Ansicht automatisch zur nächsten Übung (Swipe nach rechts) und manuelles Swipen bleibt jederzeit möglich.
6. **Given** ich nehme während des Workouts Plananpassungen vor (Sätze hinzufügen/entfernen/reihenfolgen/Attribute wie Reps/Typ/Seite), **When** ich das Workout normal abschließe (nach letzter Rep), **Then** werden diese Änderungen zurück in den zugrundeliegenden Plan gespeichert (ausgenommen reine Ausführungsdaten wie Gewicht/Schwierigkeit).  
7. **Given** ich breche ein laufendes Workout ab, **When** ich "Cancel" wähle, **Then** sehe ich eine Zusammenfassung der bis dahin erfassten Ausführungsdaten, **and** diese Ausführungsdaten werden gespeichert, jedoch werden keine Planänderungen gespeichert.
8. **Given** die Übungsansicht, **When** ich mich durch die Übungen bewege, **Then** sehe ich für jede Übung die Beschreibung/Instruktion klar dargestellt.
9. **Given** das Design System, **When** ich das Workout durchlaufe, **Then** entspricht die UI den Patterns aus `Docs/DESIGN_SYSTEM.md` (Brand-Background, VLGlassCard-Abschnitte, HIG-konforme Bottom-CTAs).

### Edge Cases
- Vorzeitiger Abbruch: Zusammenfassung anzeigen; Ausführungsdaten werden gespeichert; Planänderungen werden nicht übernommen.
- Übungen ohne Equipment: Gewichtseingabe entfällt; Schwierigkeit bleibt erfassbar.
- Manuelles Swipen jederzeit möglich; Auto-Advance nur beim Abschluss einer Übung.
- Timer-Bedienung: Zeit kann nicht manuell gesteuert werden; sie startet bei Bestätigung einer Wiederholung und endet automatisch.
- Planänderungen während aktivem Workout: Kein paralleles Editieren anderer Pläne erlaubt; andere Pläne können erst nach Cancel/Finish bearbeitet werden.

## Requirements (mandatory)

### Functional Requirements
- **FR-001**: Nutzer KÖNNEN ein Workout aus einem gespeicherten Plan starten (Plan wird vorab geladen).
- **FR-002**: Die Workout-UI zeigt pro Übung eine eigene Seite mit Titel und Beschreibung; manuelles Swipen zwischen Übungen ist möglich; nach Abschluss aller Wiederholungen einer Übung erfolgt Auto-Advance zur nächsten Übung.
- **FR-003**: Pro bestätigter Wiederholung werden Gewicht (nur bei Equipment-Übungen; Schrittweite 0,5 kg; Minimum 0) und Schwierigkeit (Integer 1–10) erfasst; bei Körpergewichtsübungen ist Gewicht null/nicht erforderlich.
- **FR-004**: Nach Bestätigung startet ein Ruhe‑Timer (2 Minuten, nicht editierbar) zwischen jeder Wiederholung und zwischen letzter Wiederholung einer Übung und der ersten der nächsten Übung; nach der letzten Übung gibt es keinen Timer. Der Timer startet automatisch mit der Bestätigung und endet automatisch; keine manuelle Steuerung.
- **FR-005**: Nutzer KÖNNEN während des Workouts Planstrukturen dynamisch anpassen (Sätze hinzufügen/entfernen/verschieben; Reps, Set-Typ, Seite). Diese Planänderungen werden beim regulären Abschluss des Workouts in den Plan übernommen; bei Abbruch bleiben sie verworfen.
- **FR-006**: Reine Ausführungsdaten (Gewicht, Schwierigkeit pro Wiederholung) werden lokal gespeichert und NICHT in HealthKit geschrieben (siehe `specs/001-specify-fine-tune/healthkit-review.md`).
- **FR-007**: Beim regulären Abschluss (letzte Rep bestätigt) erscheint eine kompakte Zusammenfassung (Dauer, Anzahl Sätze/Repeats, Gewichts- und Schwierigkeitsstatistiken, Planänderungen), danach Navigation zurück zum Home-Screen.
- **FR-008**: Beim Abbruch erscheint eine Zusammenfassung; Ausführungsdaten bis dahin werden gespeichert; Planänderungen werden nicht übernommen.
- **FR-011**: Während eines aktiven Workouts ist die Bearbeitung anderer Pläne gesperrt; Bearbeitung wird erst nach Cancel/Finish wieder erlaubt.
- **FR-012**: Beim Ablauf des Timers erfolgt haptisches Feedback oder ein kurzer Jingle als Hinweis zum Fortfahren.
- **FR-009**: UI folgt `Docs/DESIGN_SYSTEM.md`:  
  - Brand-Background via `.vlBrandBackground()`
  - Inhalte in `VLGlassCard`-Abschnitten (Titel, Meta, Eingaben)
  - HIG-konforme Bottom-CTAs (`ToolbarItem(.bottomBar)` oder `safeAreaInset(edge:.bottom)` ohne grauen Zusatzcontainer)
  - Typografie/Farben via `DesignSystem.Typography`/`DesignSystem.ColorRole`
- **FR-010**: Accessibility: Dynamic Type, ausreichender Kontrast, klare Labels.

- **Workout (Active Session)**: id, planId, startTime, endTime?, status(active|finished|canceled), currentExerciseIndex, setIndex, repIndex, restTimerRemaining.
- **WorkoutSetEntry**: id, planExerciseId, setIndex, repIndex, weightKg(decimal, step 0.5, ≥ 0)?, difficulty(Int 1..10), timestamp.
- **PlanChangeDuringSession**: add/remove/move set operations; attribute edits (reps, setType, side); only persisted to Plan on workout completion.
- **Summary**: duration, completed reps/sets, per-exercise aggregates (avg difficulty, used weights), list der Planänderungen.

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [ ] No implementation details (languages, frameworks, APIs)
- [ ] Focused on user value and business needs
- [ ] Written for non-technical stakeholders
- [ ] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous  
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [x] User description parsed
- [x] Key concepts extracted
- [x] Ambiguities marked
- [x] User scenarios defined
- [x] Requirements generated
- [x] Entities identified
- [ ] Review checklist passed

---



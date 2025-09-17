# Feature Specification: Feintuning des generierten Trainingsplans

**Feature Branch**: `001-specify-fine-tune`  
**Created**: 2025-09-17  
**Status**: Draft  
**Input**: User description: "fine tune the generated workout plan. So I want to edit the sets, the repetitions the type of repetition (e.g. warm up, normal, cool down), weight that is used (+ whole body, one arm / leg). Use the already existing logic where we create plans based on equipment and let us afterwards edit the created plans."

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

Hinweis für VoltLift: Entscheidungen orientieren sich an `PRODUCT_VISION.md`, Apple HIG und dem internen Design System (`Docs/DESIGN_SYSTEM.md`). Bei Konflikten: Einfachheit > HIG > Vision.

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
Als Nutzer, der bereits anhand meines verfügbaren Equipments einen Trainingsplan generiert hat, möchte ich für jede Übung die Sätze feinjustieren (Anzahl der Sätze, Wiederholungen je Satz, Satztyp: Aufwärmen/Normal/Abwärmen, verwendetes Gewicht, Ausführungsseite: beidseitig/einseitig), damit der Plan meinen aktuellen Bedürfnissen entspricht.

### Acceptance Scenarios
1. **Given** ein automatisch erzeugter Plan basierend auf gewähltem Equipment, **When** ich in den Bearbeitungsmodus wechsle, **Then** kann ich für jede Übung Sätze hinzufügen/entfernen, die Reihenfolge anpassen und pro Satz Wiederholungen, Satztyp (Aufwärmen/Normal/Abwärmen), Ausführungsseite (beidseitig/einseitig) sowie einen Kommentar festlegen. Es werden ausschließlich gültige Optionen angeboten (keine Freitexteingaben).
2. **Given** ich nehme Änderungen vor, **When** ich speichere, **Then** werden die Änderungen am Plan dauerhaft übernommen und sind bei der späteren Durchführung des Workouts sichtbar/nutzbar.
3. **Given** nur gültige Optionen werden angeboten, **When** ein fehlerhafter Zustand entsteht (z. B. widersprüchliche Konfiguration), **Then** erhalte ich eine klare, verständliche Fehlermeldung mit Hinweisen zur Korrektur.
4. **Given** bestimmte Optionen sind nur bei kompatiblen Übungen sinnvoll (z. B. einseitig), **When** ich solche Optionen bearbeiten möchte, **Then** werden sie nur dort angeboten, wo sie fachlich passen.
5. **Given** ein aktives Workout läuft, **When** ich einen anderen Plan öffnen möchte, **Then** ist dessen Bearbeitung gesperrt; nur der aktuell laufende Workout-Plan ist editierbar.
6. **Given** ich verlasse den Bearbeitungsmodus ohne zu speichern, **When** ein Bestätigungsdialog erscheint, **Then** kann ich meine Entscheidung (verwerfen oder zurück zur Bearbeitung) treffen.
7. **Given** ein aktives Workout mit einer Übung, die Equipment nutzt, **When** ich Satzdaten erfasse, **Then** kann ich für den Satz das Gewicht (kg in 0,5er-Schritten, Minimum 0, kein Maximum) eingeben und pro Wiederholung eine Schwierigkeit (1–10) erfassen; bei Körpergewichtsübungen wird keine Gewichtseingabe angeboten.

### Edge Cases
- Aktives Workout: Andere Pläne sind während eines aktiven Workouts nicht editierbar; nur der laufende Workout-Plan kann bearbeitet werden.
- Gewicht: Für Übungen MIT Equipment ist Gewicht nur im aktiven Workout editierbar (kg in 0,5er-Schritten, Minimum 0, kein Maximum). Für Übungen OHNE Equipment (Körpergewicht/Band) wird keine Gewichtseingabe angeboten; Standard ist Körpergewicht.
- Einseitig: Option nur bei Übungen anbieten, bei denen eine einseitige Ausführung fachlich sinnvoll ist (z. B. einarmig/einbeinig). Kriterien leiten sich aus der Übungstaxonomie ab.
- Speichern: Außerhalb eines aktiven Workouts wird nur bei explizitem Speichern persistiert; während eines aktiven Workouts werden Änderungen beim Beenden des Workouts übernommen.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: Nutzer KÖNNEN einen automatisch generierten Trainingsplan in einen Bearbeitungsmodus versetzen.
- **FR-002**: Nutzer KÖNNEN pro Übung Sätze hinzufügen, löschen und die Reihenfolge von Sätzen anpassen.
- **FR-003**: Nutzer KÖNNEN pro Satz die Wiederholungen (Ganzzahl), den Satztyp (Aufwärmen, Normal, Abwärmen) und die Ausführungsseite (beidseitig oder einseitig) festlegen. Gewichtskonfiguration ist nicht Teil dieses Editors.
- **FR-004**: Ungültige Eingaben sind nicht möglich (nur gültige Optionen werden angeboten); bei fehlerhaften Zuständen zeigt das System verständliche Fehlermeldungen.
- **FR-005**: Änderungen MUSS das System dauerhaft speichern und beim Starten/Protokollieren des Workouts verwenden.
- **FR-006**: Abbruch-/Zurück-Navigation MUSS ungespeicherte Änderungen absichern (Bestätigungsdialog).
- **FR-007**: Bei der Erstellung neuer Pläne werden sinnvolle Standardwerte für die Anzahl der Sätze pro Übung gesetzt.
- **FR-008**: Die Option „einseitig“ wird nur bei Übungen angeboten, bei denen sie fachlich sinnvoll ist (basierend auf der Übungstaxonomie).
- **FR-009**: Inhalte, Bezeichnungen und Interaktionen MÜSSEN HIG-konform und gemäß VoltLift Design System gestaltet sein (Dynamic Type, klare Labels, AA-Kontrast). Referenzen: `PRODUCT_VISION.md`, `Docs/DESIGN_SYSTEM.md`.
- **FR-010**: Während eines aktiven Workouts ist nur der laufende Workout-Plan editierbar; andere Pläne sind gesperrt.
- **FR-011**: Gewicht ist nur für Übungen mit Equipment editierbar und nur während eines aktiven Workouts (kg in 0,5er-Schritten, Minimum 0, kein Maximum). Für Übungen ohne Equipment gibt es keine Gewichtseingabe (Körpergewicht).
- **FR-012**: Nutzer KÖNNEN optional zu jedem Satz einen Kommentar hinzufügen.
- **FR-013**: Nutzer KÖNNEN während eines aktiven Workouts für jede Wiederholung eine Schwierigkeit auf einer Skala von 1 (sehr leicht) bis 10 (keine weitere Wiederholung möglich) erfassen.
- **FR-014**: Speichersemanik: Außerhalb eines aktiven Workouts nur bei explizitem Speichern persistieren; während eines aktiven Workouts beim Beenden des Workouts übernehmen.

### Key Entities *(include if feature involves data)*
- **WorkoutPlan**: Nutzerdefinierter Trainingsplan, abgeleitet aus Equipment-Auswahl; enthält geordnete Liste von Plan-Übungen.
- **PlanExercise**: Bezug auf eine Übung aus dem Katalog (Name, Kategorie); enthält geordnete Liste von Sätzen, ggf. Hinweise zu Equipment-Eignung.
- **ExerciseSet (Plan)**: Attribute auf Satz-Ebene im Plan: Wiederholungen, Satztyp (Aufwärmen/Normal/Abwärmen), Ausführungsseite (beidseitig/einseitig), optionaler Kommentar. Keine Gewichtseingabe, keine Schwierigkeit im Plan.
- **WorkoutSetEntry (Ausführung)**: Erfasste Satzdaten während des aktiven Workouts: Gewicht (nur bei Equipment-Übungen; kg in 0,5er-Schritten, Minimum 0, kein Maximum) und pro Wiederholung eine Schwierigkeitsskala 1–10.
- **Taxonomie/Regeln**: Geschäftslogik, die bestimmt, wann „einseitig“ erlaubt ist und welche Standardwerte pro Übung/Equipmentsituation gelten.

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


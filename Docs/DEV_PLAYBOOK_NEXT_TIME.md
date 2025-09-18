### Besser beim nächsten Mal – Mini-Playbook

- **Definition of Done (je Task)**
  - Trace zur Spec (UC/FR-IDs), Build grün, Unit- und UI-Tests grün, Lint ok
  - Screenshot/GIF der UX im PR
  - Quickstart aktualisiert

- **Konsequentes TDD für UI**
  - Vor der UI-Implementierung XCUITests für UC2 (Reps ändern, Set-Typ, Seite, Kommentar, Add/Remove/Move)
  - Navigationstest: Saved Plan → PlanEditorView (sichtbare Edit-Controls)

- **Nachvollziehbarkeit Spec → Code**
  - Tasks und PRs mit Spec-IDs taggen (z. B. FR012, FR013)
  - Links auf relevante Abschnitte in `specs/001-specify-fine-tune/spec.md`

- **Strengere CI-Gates**
  - Stufen: swiftformat, swiftlint, Build (Simulator), Unit-Tests, UI-Tests (Headless)
  - Smoke-Flow: App starten → Saved Plan → Editor öffnen → Reps ändern → Speichern

- **Vertragstests für Navigation & Mapping**
  - Unit-Tests für Mapping `WorkoutPlanData → PlanDraft`
  - UI-Tests gegen „leerer/Schwarz“-Screens (assert Sichtbarkeit/Editierbarkeit)

- **SwiftUI Previews gezielt nutzen**
  - Previews mit realistischem `PlanDraft` (inkl. `allowsUnilateral`)
  - Kurze Preview-Checkliste im PR (Labels, Kontraste, Accessibility-Hinweise)

- **Vertikale Slices**
  - End-to-end in kleinen Schritten: Reps → Set-Typ → Seite → Kommentar → Reorder
  - Nach jedem Slice: Tests+Smoke, dann nächsten Slice

- **PR-Template**
  - Checkliste (DoD, Spec-IDs, Tests, Screens/GIF, Migrations-/UX-Notizen)

- **Quickstart-Smoke pflegen**
  - Konkrete Schritte zum Kernflow; Pflicht vor Merge auszuführen und zu aktualisieren

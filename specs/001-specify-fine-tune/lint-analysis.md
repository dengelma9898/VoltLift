# SwiftLint Analyse – Aktueller Stand

Stand: 77 Warnungen, 0 "serious". Build: erfolgreich. Die Verstöße sind überwiegend stilistisch/komplexitätsbezogen.

## Übersicht nach Regelgruppen

- Öffnende Klammer Abstand (`opening_brace`)
  - Ursache: Vor `{` fehlt Leerzeichen bzw. Formatregel verletzt.
  - Beispiele: `VLErrorView.swift:188`, `WorkoutSetupView.swift:105`, diverse Services.
  - Status: überwiegend bestehend (Altlasten).

- Zyklomatische Komplexität (`cyclomatic_complexity`)
  - Ursache: Funktionen mit Komplexität > 10.
  - Beispiele: `SettingsView.swift:226`, `WorkoutSetupView.swift:451`.
  - Status: bestehend.

- Zeilenlänge (`line_length`)
  - Ursache: > 120 Zeichen/Zeile.
  - Beispiele: `SettingsView.swift:43`, `EnhancedExerciseCatalog.swift:17, 1177`, `ExerciseDetailView.swift:474`.
  - Status: bestehend.

- Dateilänge / Typkörperlänge (`file_length`, `type_body_length`)
  - Ursache: Datei bzw. Typ zu lang.
  - Beispiele: `WorkoutSetupView.swift:814`, `ExerciseDetailView.swift:508`, `UserPreferencesService.swift:795`, `ExerciseCustomizationService.swift:509`, `PersistenceController.swift:765`.
  - Status: bestehend.

- Switch-Case-Zeilenumbruch (`switch_case_on_newline`)
  - Ursache: `case`-Zweige nicht auf eigener Zeile.
  - Beispiele: viele in `WorkoutSetupView.swift`; neu auch in `PlanEditorService.swift` und `WorkoutLoggingService.swift`; sowie `WorkoutPlanModels.swift:77–78` (Switch in `PlanValidation`).
  - Status: teils bestehend, teils neu.

- Bezeichner-Länge (`identifier_name`)
  - Ursache: zu kurze Variablennamen (1–2 Zeichen).
  - Beispiele: `ExerciseDetailView.swift` (`eq`), `ExerciseCustomizationService.swift` (`to`).
  - Anmerkung: Neuer Verstoß `v` in `WorkoutLoggingView.swift` bereits zu `value` behoben.
  - Status: bestehend (+ 1 neu behoben).

- Force Casts (`force_cast`)
  - Ursache: `as!`-Casts.
  - Beispiele: `PersistenceController.swift:659, 714, 740, 742`.
  - Status: bestehend.

- Großes Tupel (`large_tuple`)
  - Ursache: Tupel mit > 2 Elementen.
  - Beispiel: `ExerciseCustomizationService.swift:481`.
  - Status: bestehend.

- TODO/FIXME (`avoid_todo_fixme`, `todo`)
  - Ursache: TODO-Kommentare im Code.
  - Beispiele: `PersistenceController.swift:755, 762` (neu angelegte Persistenz-Platzhalter), weitere ältere TODOs.
  - Status: teils neu (Platzhalter), teils bestehend.

- Parameteranzahl (`function_parameter_count`)
  - Ursache: Funktionen mit > 5 Parametern.
  - Beispiele: `PlanEditorService.swift:~76` (UC2), `PlanEditorViewModel.swift:~47` (VM-Bridge).
  - Status: neu.

- Dateiname-Regel (`file_name`)
  - Ursache: Dateiname passt nicht zum/zu den Typen.
  - Beispiele: `WorkoutPlanModels.swift` enthält `PlanDraft`, `PlanExerciseDraft`, `PlanSetDraft`; `WorkoutExecutionModels.swift` enthält Ausführungsmodelle.
  - Status: neu (durch Umbenennung der Domain-Modelle zur Kollisionsvermeidung).

## Priorisierung der Korrekturen

1) Schnell und risikoarm (neu, lokal):
   - `switch_case_on_newline` in neuen Dateien beheben (PlanEditorService, WorkoutLoggingService, PlanValidation-Switch).
   - TODO-Kommentare in Persistenz-Platzhaltern entschärfen (oder mit schlanker Disable-Direktive versehen).
   - `file_name`: kurzfristig lokale Deaktivierung per Kommentar am Dateianfang; Umbenennung kann später geplant werden.

2) Mittelfristig (neu, mit kleinem Refactor):
   - `function_parameter_count`: Parameter-Objekt/Struct für UC2 (Service) + passenden VM-Aufruf einführen.

3) Langfristig (Altlasten, größerer Aufwand):
   - `cyclomatic_complexity`, `file_length`, `line_length` in großen Views/Services sukzessive reduzieren (Aufteilung, Extraktion von Unter-Views/Methoden).
   - `force_cast` im `PersistenceController` gezielt entfernen (sichere Casts, Guard-Pfade).
   - `identifier_name` in Altcode (z. B. `eq`, `to`) bereinigen, sofern ohne API-Bruch möglich.
   - `large_tuple` auf struct/tuple-slim refactoren.

## Hinweise

- Alle Verstöße sind Warnungen; keine blockierenden Fehler. Der Projekt-Build ist grün.
- `swiftformat` und `swiftlint` wurden ausgeführt; die meisten Verstöße stammen aus umfangreichen Bestandsdateien.
- Die neuen Flows (Plan/Logging) bringen wenige, klar adressierbare Stilthemen mit (Case-Zeilenumbrüche, Param-Anzahl, Dateiname-Regel, TODO-Platzhalter).

## Vorschlag für Fix-Tasks (für später)

- Kurzfristige Tasks
  - Case-Formatierung in `PlanEditorService.swift`, `WorkoutLoggingService.swift`, `WorkoutPlanModels.swift` korrigieren.
  - TODO-Kommentare in `PersistenceController.swift` anpassen (oder `// swiftlint:disable:next todo` mit Ticket-Referenz).
  - `file_name`-Regel temporär pro Datei deaktivieren, bis Umbenennung geplant ist.

- Mittelfristige Tasks
  - Parameter-Objekt für `editSetAttributes` (Service + VM) einführen.

- Langfristige Tasks
  - Komplexitäts- und Längenverstöße in großen Dateien iterativ abbauen.
  - Force-Casts im `PersistenceController` ersetzen.
  - Kurznamen (`eq`, `to`) entschärfen.
  - Großes Tupel aufbrechen.

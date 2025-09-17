# Quickstart: Feintuning des generierten Trainingsplans

## Voraussetzungen
- Xcode 26, iOS 18.6 Simulator
- Swift 6 Toolchain
- SwiftLint & SwiftFormat installiert

## Build & Run
1. Projekt öffnen: `VoltLift/VoltLift.xcodeproj`
2. Ziel: `VoltLift` (iOS)
3. Simulator starten (iPhone 16/17)
4. Build & Run (⌘R)

## Smoke-Test (Plan-Editor)
1. Bestehenden, manuell erstellten und equipment-basierten Plan öffnen (wie im aktuellen App-Stand)
   - Falls keiner existiert: neuen Plan manuell anlegen und Equipment auswählen
2. In Bearbeitungsmodus wechseln
3. Satz hinzufügen, Wiederholungen und Satztyp ändern, Seite auf einseitig stellen (falls Übung erlaubt), Kommentar hinzufügen
4. Speichern und prüfen, dass Änderungen persistieren

## Smoke-Test (Workout-Erfassung)
1. Workout starten mit einer Equipment-Übung
2. Für einen Satz Gewicht in 0,5 kg Schritten erfassen (min 0)
3. Für jede Wiederholung Schwierigkeit 1–10 erfassen
4. Workout beenden; prüfen, dass Werte persistieren

## Format & Lint
- `swiftformat .` und `swiftlint` im Repo ausführen

## Hinweise
- Nur der laufende Workout-Plan ist während eines aktiven Workouts editierbar
- Gewicht nur bei Equipment-Übungen, sonst Körpergewicht (keine Eingabe)

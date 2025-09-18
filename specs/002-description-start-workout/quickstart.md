# Quickstart: Start Workout Flow

## Voraussetzungen
- Xcode 26, iOS 18.6 Simulator
- Swift 6 Toolchain
- SwiftLint & SwiftFormat installiert

## Build & Run
1. Projekt öffnen: `VoltLift/VoltLift.xcodeproj`
2. Ziel: `VoltLift` (iOS)
3. Simulator: iPhone 16/17
4. Build & Run (⌘R)

## Smoke-Test
1. Plan auswählen → "Start Workout" tippen.
2. Erste Übung: Eine Wiederholung ausführen → Gewicht (0,5‑kg‑Schritte, ≥0 bei Equipment) und Schwierigkeit (1–10) wählen → "Bestätigen".
3. 2:00‑Timer startet automatisch → nach Ablauf Haptik/Jingle → nächste Wiederholung.
4. Letzte Wiederholung der Übung bestätigen → Auto‑Advance zur nächsten Übung (Swipen jederzeit möglich).
5. Währenddessen einen Satz hinzufügen und Reps ändern → am Ende (Finish) prüfen, dass Planänderungen übernommen wurden.
6. Abbruch‑Pfad: Workout starten, einige Reps loggen → "Cancel" → Zusammenfassung erscheint → prüfen, dass Ausführungsdaten gespeichert und Planänderungen verworfen wurden.

## Format & Lint
- `swiftformat .` und `swiftlint` im Repo ausführen

## Hinweise
- UI folgt `Docs/DESIGN_SYSTEM.md` (VLGlassCard, Brand‑Background, Bottom‑CTA ohne grauen Container).
- Keine manuelle Timer‑Steuerung; Start bei Rep‑Bestätigung; Ende automatisch.



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
1. Plan öffnen (`Saved Plans` → Plan wählen) → "Start Workout" tippen (navigiert zu `WorkoutSessionView`).
2. Falls Equipment: Gewicht per Stepper wählen (0,5‑kg‑Schritte, ≥0). Reps festlegen und pro Wiederholung Schwierigkeit (1–10) wählen.
3. "Bestätigen" tippen → 2:00‑Timer startet automatisch. Nach Ablauf Haptik/Jingle.
4. Wiederholt bestätigen; optional "Plan ändern" öffnen (Overlay) und Änderungen simulieren.
5. "Finish" → Zusammenfassung erscheint (alle Einträge sichtbar); App neu starten → Daten bestehen.
6. "Cancel" → Zusammenfassung erscheint; Planänderungen werden verworfen (nur Ausführungsdaten gespeichert).

## Format & Lint
- `swiftformat .` und `swiftlint` im Repo ausführen

## Hinweise
- UI folgt `Docs/DESIGN_SYSTEM.md` (VLGlassCard, Brand‑Background, Bottom‑CTA ohne grauen Container).
- Keine manuelle Timer‑Steuerung; Start bei Rep‑Bestätigung; Ende automatisch.
- Screenshots: Session-Hauptscreen, Timer‑Anzeige, Plan‑Edit‑Overlay, Zusammenfassung.



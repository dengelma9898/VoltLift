# VoltLift UX-Prinzipien

Bezug: `PRODUCT_VISION.md`, `Docs/DESIGN_SYSTEM.md`, Apple HIG. Priorität: Einfachheit > HIG > Vision.

## Leitlinien
- Klarheit vor Umfang: Nur notwendige Optionen zeigen; progressive Offenlegung.
- Selbsterklärend: Beschriftungen sind eindeutig, Hilfetexte sparsam und kontextnah.
- Konsistenz: Farben/Typografie/Komponenten strikt gemäß Design System.
- Tast- und VoiceOver-tauglich: Dynamic Type, ausreichender Kontrast (AA), aussagekräftige Accessibility-Labels.
- Fehlerprävention statt Fehlerbehandlung: Vordefinierte Optionen statt Freitext.

## Plan-Editor (Feintuning generierter Pläne)
- Eingaben
  - Wiederholungen: Stepper/Pickers mit gültigen Werten (≥ 0).
  - Satztyp: Segmented Control (Aufwärmen | Normal | Abwärmen).
  - Seite: Nur anzeigen, wenn Übung „einseitig“ erlaubt (beidseitig | einseitig).
  - Kommentar: Optional, kurz & einzeilig (max. ~140 Zeichen, Dynamic Type beachten).
- Interaktion
  - Sätze hinzufügen/entfernen/neu anordnen mit gut sichtbaren Controls.
  - Speichern explizit (Primary CTA). Beim Verlassen mit ungespeicherten Änderungen: Bestätigung.
- Feedback
  - Ungültige Zustände frühzeitig verhindern (disabled Optionen); andernfalls knappe, klare Fehlhinweise.

## Workout-Logging (aktive Ausführung)
- Sichtbarkeit
  - Nur laufender Workout-Plan ist editierbar (deutliche Kennzeichnung „Aktiv“).
- Gewicht
  - Nur für Equipment-Übungen anbieten: kg in 0,5er-Schritten, Minimum 0, kein Maximum.
  - Keine Gewichtseingabe für Körpergewichtsübungen (Label „Körpergewicht“).
- Schwierigkeit (pro Wiederholung)
  - Skala 1–10, kompakte Erfassung (z. B. komprimierte Rating-UI oder schnell erfassbare Picker).
  - Schnelleingabe für alle Wiederholungen plus Möglichkeit zur Feinjustierung.
- Speichern
  - Werte beim Beenden des Workouts persistieren; Zwischenspeichern robust gegen App-Wechsel.

## Fehler- und Leere-Zustände
- Leere Zustände: Kurz erklären, was zu tun ist; CTA anbieten (z. B. „Satz hinzufügen“).
- Fehlertexte: Freundlich, präzise, handlungsleitend. Keine internen Codes zeigen.

## Accessibility & Interaktion
- Touch-Ziele ≥ 44×44 pt, ausreichende Abstände (`DesignSystem.Spacing`).
- Lesereihenfolge logisch; VoiceOver-Gruppierung für komplexe Controls.
- Haptik/Feedback sparsam und bedeutungsvoll einsetzen (Bestätigung, Fehler, kritische Aktionen).

## Mikro-Kopien (Beispiele)
- Plan-Editor Speichern: „Änderungen speichern“
- Ungespeichert verlassen: „Änderungen verwerfen?“ – „Verwerfen“ | „Zurück“
- Gewicht (Equipment): „Gewicht (kg)“ – Step 0,5
- Schwierigkeit: „Schwierigkeit je Wiederholung (1–10)“

## Checkliste vor Merge
- Inhalte HIG- und Design-System-konform?
- Nur gültige Optionen angeboten (keine Freitexte, wo verboten)?
- Laufender Plan exklusiv editierbar, andere gesperrt?
- Dynamic Type passt, Labels verständlich, Kontrast AA?
- Ungespeicherte Änderungen werden abgefangen?

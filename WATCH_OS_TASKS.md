## WATCH OS – Aufgaben und Implementierungsplan

### Kontext
- Branch: `feature/watch-functional-impl`
- Ziele: Koppelte watchOS-App, Start/Pause/Fortsetzen/Beenden von Workouts auf der Watch, zuverlässiger State-Sync mit iOS, HIG- und Corporate-Design-konforme UI, vollständige Lokalisierung und CI-Konformität.

### 1) WatchConnectivity-Protokoll definieren
- [ ] Ereignisse und Schlüssel vereinbaren
  - **Events**: `workout.start`, `workout.pause`, `workout.resume`, `workout.stop`, `workout.progress`
  - **Payload (Beispiele)**:
    - `workout.start`: `{ "activity": "functional_strength_training", "startedAt": ISO8601 }`
    - `workout.progress`: `{ "hr": Int?, "kcal": Double?, "elapsed": Int, "timestamp": ISO8601 }`
- [ ] Transportstrategie festlegen
  - **Sofort**: `sendMessage(_:replyHandler:errorHandler:)`
  - **Offline**: `transferUserInfo(_:)` als Fallback und Nachlieferung
  - **Retry/Backoff**: einfache Wiederholungslogik bei Fehlern
- [ ] Versionierung der Nachrichten (z. B. `version: 1`) und Kompatibilitätsregeln dokumentieren

### 2) HealthKit-Workout-Session auf watchOS orchestrieren
- [ ] Autorisierung UX-Flow (lokalisiert, freundliche Texte). Sicherstellen, dass nur die Watch aufzeichnet
- [ ] Konfiguration: `HKWorkoutConfiguration` pro Aktivität (Start mit `functionalStrengthTraining`), später erweiterbar
- [ ] Live-Daten: Herzfrequenz, aktive Energie; optional Distanz je Aktivität
- [ ] Lifecycle: Start, Pause, Resume, End, Finish-Builder, Persistenz/Finalisierung
- [ ] Edge Cases: bereits laufende Session, abgelehnte Berechtigung, Builder-Fehler, App-Lifecycle/Extended Runtime

### 3) Zustands-Synchronisation Watch ↔ iOS
- [ ] Deterministischer State (enum + Timestamps) und klar definierte State-Transitions
- [ ] Initialer Sync bei App-Start/Re-Aktivierung (beide Seiten robust gegen doppelte Events)
- [ ] Konfliktlösung: Watch als „Source of Truth“ während aktiver Workouts
- [ ] Offline-Pufferung und Nachlieferung (UserInfo-Queue)

### 4) Watch-UI (Produktiv, HIG + DesignSystem)
- [ ] Minimaler Flow hart machen: Start, Pause/Fortsetzen, Stop mit gut sichtbaren, großen Buttons
- [ ] DesignSystem anwenden (Farben/Typo/Spacing/Buttons), Haptik-Signale hinzufügen
- [ ] Lokalisierung: alle Texte in `Localizable.strings` (de/en), Accessibility-Labels/Values/Hints
- [ ] Zustandsanzeige (laufend/pausiert), Fehler- und Berechtigungszustände freundlich darstellen

### 5) iOS-Begleiter-Ansichten
- [ ] Live-Spiegelung des Watch-Workouts (Status, HR, kcal, Dauer)
- [ ] Optionaler Start über iOS (nur wenn Watch erreichbar/aktiv), sonst Hinweis auf Start an der Watch
- [ ] Konfliktregeln: iOS blockiert parallele Bearbeitung, wenn Watch-Session aktiv ist

### 6) Fehlerbehandlung & Diagnostik
- [ ] Logging-Punkte definieren (Start/Ende, Autorisierung, Connectivity-Änderungen, Fehler)
- [ ] Nutzerfreundliche Fehlermeldungen (lokalisiert), klare Handlungsoptionen
- [ ] Einfache Retry-Strategien (Connectivity), Telemetrie-Hooks für spätere Auswertung

### 7) Tests
- [ ] Unit-Tests (Domain/Use-Cases): State-Maschine, Event-Verarbeitung, Mapping von Messages ↔ State
- [ ] Adapter-Tests: `WCSession`-Stubs/Mocks (Watch/iOS), HealthKit-Builder-Stub (so weit möglich)
- [ ] UI-Tests/Snapshots (watchOS): Zustandsdarstellung, Buttons, Lokalisierung
- [ ] Integrationspfade im Simulator (gekoppelte iPhone/Watch-Sims)

### 8) CI/CD
- [ ] Build iOS + watchOS Schemes in CI aktivieren
- [ ] SwiftFormat/SwiftLint vollständig grün halten (Pre-Commit + CI)
- [ ] Optional: einfache UI-Testläufe für watchOS im CI, falls verfügbar

### 9) Privacy & Sicherheit
- [ ] HealthKit- und ggf. Standort-Berechtigungen final prüfen (lokalisierte Beschreibungen vorhanden)
- [ ] Datenminimierung/Transparenz: Nur notwendige Daten synchronisieren, keine sensiblen Daten im Klartext loggen
- [ ] Persistenz-Strategie abstimmen (was wird lokal gespeichert, was nur synchron angezeigt)

### 10) Lokalisierung
- [ ] Alle neuen Keys in `de.lproj`/`en.lproj` anlegen und Review der Übersetzungen
- [ ] A11y-Texte (Labels/Values/Hints) abdecken

### 11) Akzeptanzkriterien (DoD)
- [ ] Start/Pause/Resume/Stop funktionieren stabil auf Watch, UI reagiert unmittelbar
- [ ] iOS zeigt den korrekten Live-Zustand binnen < 1–2 s bei Reachability
- [ ] Nachrichten werden bei Verbindungsabbruch gepuffert und später zugestellt
- [ ] Lokalisierung de/en vollständig, keine Hardcoded-Strings
- [ ] SwiftFormat/SwiftLint grün, Simulator-Builds iOS+watchOS laufen

### 12) Meilensteine
- [ ] M1 – Protokoll/State-Maschine final + Dummy-Flow (Connectivity-Stubs)
- [ ] M2 – HealthKit-Session stabil, UI-Bedienung (Start/Pause/Resume/Stop)
- [ ] M3 – State-Sync Ende-zu-Ende, iOS-Begleiteransicht
- [ ] M4 – Tests, A11y/L10n-Review, CI-Abschluss

### Hinweise
- Entscheidungen gem. `PRODUCT_VISION.md`, `Docs/UX_PRINCIPLES.md`, `Docs/DESIGN_SYSTEM.md` und AGENTS-Regeln.
- Einfachheit bevorzugen, konsistente Architektur (Clean + MVVM), Swift Concurrency.



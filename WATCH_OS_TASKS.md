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

### 1.1) Kommunikationsereignisse (aktueller iOS‑Funktionsumfang)

Alle Nachrichten verwenden einen gemeinsamen Envelope:

```json
{
  "v": 1,
  "flow": "strength|outdoor",
  "type": "<event>",
  "id": "<uuid>",
  "corr": "<uuid>",
  "ts": "<ISO8601>",
  "device": "watch|phone",
  "payload": { }
}
```

| Flow | Event | Richtung | Payload (Schema) | Beispiel |
|---|---|---|---|---|
| any | mode.select | Watch → Phone (optional Phone → Watch Bestätigung) | { "flow": "strength"|"outdoor" } | {"v":1,"flow":"strength","type":"mode.select","id":"…","corr":null,"ts":"2025-09-21T20:00:00Z","device":"watch","payload":{"flow":"strength"}} |
| strength | strength.start | Watch → Phone | { "planId": "<id>" } | {"v":1,"flow":"strength","type":"strength.start","id":"…","ts":"…","device":"watch","payload":{"planId":"plan_123"}} |
| strength | strength.rep.confirm | Watch → Phone | { "setId":"<id>", "exerciseId":"<id>", "weight": <Double>, "reps": <Int>, "difficulty": { "type":"rpe"|"rir"|"native", "value": <Double?> }, "confirmedAt":"<ISO8601>" } | {"v":1,"flow":"strength","type":"strength.rep.confirm","id":"…","ts":"…","device":"watch","payload":{"setId":"s_1","exerciseId":"e_1","weight":60.0,"reps":8,"difficulty":{"type":"rpe","value":8.5},"confirmedAt":"2025-09-21T20:05:00Z"}} |
| strength | strength.rest.started | Phone → Watch | { "seconds": <Int> } | {"v":1,"flow":"strength","type":"strength.rest.started","id":"…","ts":"…","device":"phone","payload":{"seconds":90}} |
| strength | strength.rest.completed | Phone → Watch | { } | {"v":1,"flow":"strength","type":"strength.rest.completed","id":"…","ts":"…","device":"phone","payload":{}} |
| strength | strength.finish | Watch → Phone | { "finishedAt":"<ISO8601>" } | {"v":1,"flow":"strength","type":"strength.finish","id":"…","ts":"…","device":"watch","payload":{"finishedAt":"2025-09-21T21:00:00Z"}} |
| outdoor | outdoor.activity.select | Watch → Phone | { "activity": "running"|"cycling"|"walking"|… } | {"v":1,"flow":"outdoor","type":"outdoor.activity.select","id":"…","ts":"…","device":"watch","payload":{"activity":"running"}} |
| outdoor | outdoor.countdown.start | Watch → Phone | { "seconds": <Int> } | {"v":1,"flow":"outdoor","type":"outdoor.countdown.start","id":"…","ts":"…","device":"watch","payload":{"seconds":10}} |
| outdoor | outdoor.countdown.extend | Watch → Phone | { "seconds": <Int> } | {"v":1,"flow":"outdoor","type":"outdoor.countdown.extend","id":"…","ts":"…","device":"watch","payload":{"seconds":10}} |
| outdoor | outdoor.countdown.skip | Watch → Phone | { } | {"v":1,"flow":"outdoor","type":"outdoor.countdown.skip","id":"…","ts":"…","device":"watch","payload":{}} |
| outdoor | outdoor.start | Watch → Phone | { "startedAt":"<ISO8601>" } | {"v":1,"flow":"outdoor","type":"outdoor.start","id":"…","ts":"…","device":"watch","payload":{"startedAt":"2025-09-21T20:10:00Z"}} |
| outdoor | outdoor.progress | Watch → Phone (throttled) | { "elapsed": <Int>, "hr": <Int?>, "kcal": <Double?>, "distance": <Double?>, "pace": "<min/km?>", "loc": { "lat": <Double>, "lon": <Double> }? } | {"v":1,"flow":"outdoor","type":"outdoor.progress","id":"…","ts":"…","device":"watch","payload":{"elapsed":120,"hr":132,"kcal":17.3,"distance":0.4,"pace":"5:15","loc":{"lat":48.1374,"lon":11.5755}}} |
| outdoor | outdoor.stop.request | Watch → Phone | { } | {"v":1,"flow":"outdoor","type":"outdoor.stop.request","id":"…","ts":"…","device":"watch","payload":{}} |
| outdoor | outdoor.stop.confirm | Watch → Phone | { "confirmedAt":"<ISO8601>" } | {"v":1,"flow":"outdoor","type":"outdoor.stop.confirm","id":"…","ts":"…","device":"watch","payload":{"confirmedAt":"2025-09-21T21:10:00Z"}} |
| system | session.snapshot | beide Richtungen | { "state": { … vollständiger Zustand … } } | {"v":1,"flow":"strength","type":"session.snapshot","id":"…","ts":"…","device":"phone","payload":{"state":{"flow":"strength","planId":"plan_123","currentSet":"s_1","restRemaining":45}}} |
| system | session.ack | Empfänger → Sender | { "id":"<refId>", "ok": true } | {"v":1,"flow":"outdoor","type":"session.ack","id":"…","ts":"…","device":"phone","payload":{"id":"<ref-of-msg>","ok":true}} |
| system | session.nack | Empfänger → Sender | { "id":"<refId>", "ok": false, "error": { "code":"…","msg":"…" } } | {"v":1,"flow":"strength","type":"session.nack","id":"…","ts":"…","device":"phone","payload":{"id":"<ref-of-msg>","ok":false,"error":{"code":"invalid_state","msg":"Set not active"}}} |
| system | permission.status | Watch → Phone | { "health":"granted|denied", "location":"granted|denied|precise" } | {"v":1,"flow":"outdoor","type":"permission.status","id":"…","ts":"…","device":"watch","payload":{"health":"granted","location":"precise"}} |
| system | reachability.changed | beide Richtungen | { "reachable": true|false } | {"v":1,"flow":"any","type":"reachability.changed","id":"…","ts":"…","device":"phone","payload":{"reachable":false}} |

Hinweise:
- Strength‑Rest‑Timer ist automatisch (Phone initiiert; Watch erhält nur `rest.started`/`rest.completed` zur Anzeige/Haptik).
- Keine Pause/Resume‑Events im aktuellen Scope (entspricht iOS‑Funktionalität).

### 1.2) Reserved for future (nicht Teil des aktuellen iOS‑Umfangs)
- strength.pause / strength.resume
- outdoor.pause / outdoor.resume
- strength.rest.extend / strength.rest.cancel / strength.rest.skip

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



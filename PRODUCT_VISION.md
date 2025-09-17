## Produktvision: VoltLift

### Kurzbeschreibung
VoltLift ist eine iOS-App zum Starten und Tracken von Workouts – sowohl Krafttraining als auch Outdoor-Aktivitäten – vollständig integriert mit Apple HealthKit. Nutzer erhalten einfache, verlässliche Aufzeichnungen, aussagekräftige Auswertungen und nahtlose Synchronisierung ihrer Gesundheitsdaten.

### Problem & Kontext
- Menschen möchten Training unkompliziert starten, sauber erfassen und in Apple Health zentral bündeln.
- Viele Apps sind überladen oder fragmentieren Daten (separate Apps für Kraft vs. Outdoor).
- HealthKit bietet einen sicheren, systemweiten Datenspeicher – wird aber oft nicht konsequent genutzt.

### Zielgruppe
- Fitness-Einsteiger bis Fortgeschrittene, die Klarheit und Einfachheit bevorzugen.
- iOS-Nutzer, die ihre Trainingsdaten in Apple Health konsolidieren möchten.

### Nutzenversprechen
- Hauptbildschirm mit zwei Buttons: „Krafttraining“ und „Outdoor“ – sofort loslegen.
- Stabile, verlässliche HealthKit-Synchronisierung (lesen, schreiben, zusammenführen).
- Fokussierte Auswertungen statt Feature-Overload.
- Optionaler AI-Assistent (opt-in) schlägt personalisierte Optimierungen für Trainingspläne vor.

### Produktziele (12 Monate)
- Hohe Datenqualität: Vollständige, korrekte Sätze in HealthKit (>99% Erfolgsrate beim Schreiben).
- Selbsterklärende UX: Kernflows ohne Anleitung verständlich (Task-Success ≥ 95%; SUS ≥ 80).
- Tägliche aktive Nutzer mit Wiederkehrrate Woche 4 ≥ 30%.
- App Store Rating ≥ 4,6.

### Umfang
#### MVP (Phase 1)
- Workouts starten: Krafttraining, Outdoor (z. B. Laufen, Gehen, Radfahren) – Hauptbildschirm mit zwei Buttons.
- HealthKit-Integration: Berechtigungen, Schreiben von Trainings (HKWorkout), Dauer, Energie, Herzfrequenz (falls verfügbar), Strecke (Outdoor), Sätze/Wiederholungen (Kraft, strukturiert über Metadaten oder eigene Entitäten + Aggregation).
- Live-Tracking bei Outdoor-Workouts: Distanz, Dauer, Tempo (Core Location), Herzfrequenz (falls Sensor vorhanden und HealthKit verfügbar).
- Einfaches Protokoll: Verlaufsliste mit Kerndaten je Workout.
- Basis-Auswertung: Wochenübersicht (Trainingszeit, Anzahl Workouts, geschätzte Energie).
- Optionaler AI-Assistent (opt-in): einfache Vorschläge zur Trainingsplan-Optimierung basierend auf Verlauf und Belastung.

#### Nächste Iterationen (Phase 2+)
- Apple Watch Companion-App: Start/Stopp am Handgelenk, Live-Herzfrequenz/Distanz, Haptik; Synchronisierung über HealthKit + WatchConnectivity; Komplikation/Widget zum Schnellstart.
- Satz-Timer, Pausen-Automatik, RPE/Intensitätserfassung.
- Übungskatalog, Vorlagen, Supersätze.
- Indoor-/Outdoor-Autodetektion, GPS-Route.
- Ziele & Meilensteine, Trainingspläne leichtgewichtig.

### Kernfunktionen
- Hauptbildschirm mit zwei Start-Buttons: „Krafttraining“ und „Outdoor“ – minimale Interaktion bis Start.
- Krafttraining: Sätze/Wiederholungen/Gewicht erfassen; Pausentimer optional; HealthKit-Schreiben je Satz/Workout.
- Outdoor: Distanz, Dauer, Pace, HR; automatische Pausen optional.
- HealthKit: Robuste Permission-Flows, idempotentes Schreiben, Duplikatvermeidung, Zusammenführung bei App-Neuinstallationen.
- Verlauf & Insights: Filter, Kalender, Wochenkarten mit Trends.
- AI-Assistent (opt-in): Vorschläge für Progression, Deloads, Übungsauswahl und Volumensteuerung.
- Apple Watch Companion: Start/Stopp und Live-Metriken (HR, Distanz) direkt auf der Watch, Haptik-Feedback, Komplikation zum Schnellstart.

### User Flows (hochlevel)
1) App öffnen → Hauptbildschirm mit zwei Buttons (Kraft | Outdoor) → Start → Tracken → Stopp → Speichern → HealthKit.
2) Verlauf öffnen → Workout-Detail anzeigen → Health-Daten verlinkt einsehbar.
3) Erststart → HealthKit-Berechtigungen anfragen → Selektive Erlaubnisse akzeptieren → Nutzung.
4) AI-Assistent (optional) → Vorschläge ansehen → Änderungen übernehmen oder verwerfen.
5) Apple Watch: Workout auf der Watch starten → Live-Metriken sehen → Stopp → Synchronisierung mit iPhone/HealthKit.

### Metriken & Erfolgskriterien
- Technisch: Schreibfehlerquote HealthKit, Crash-free Sessions, GPS-Drift.
- Nutzung: DAU/WAU, Workouts pro Nutzer/Woche, Abschlussrate begonnener Workouts, Retention D7/D28.
- Qualität: Support-Tickets pro 1.000 Sessions, App Store Rating, opt-in Quote HealthKit.
- UX: Task-Success in Kernflows ≥ 95%; System Usability Scale (SUS) ≥ 80; Editor-Abbruchrate < 10%.
- AI: Opt-in-Rate, angenommene Vorschläge/Session, Einfluss auf Retention und Trainingsfrequenz.
- Watch: Anteil der Workouts, die auf der Watch gestartet werden; WCSession-Verbindungsstabilität; Energieverbrauch.

### Datenschutz & Sicherheit
- Minimalprinzip: Nur notwendige HealthKit-Typen anfragen (Workouts, Active Energy, Heart Rate, Distance, ggf. Body Mass für Kalorienmodelle – opt-in).
- Lokale Persistenz: Nur nicht-sensitive Metadaten; sensitive Daten primär in HealthKit.
- Transparenz: Klare Erklärtexte vor Berechtigungen; Export/Löschung respektieren.
- AI-Assistent: Optional; bevorzugt On-Device-Verarbeitung. Keine Übermittlung von HealthKit-Daten an Server ohne explizite Zustimmung; granulare Opt-ins.
- Watch <→> iPhone: Minimierter Datenaustausch über WatchConnectivity; keine Übertragung an Dritte ohne ausdrückliche Zustimmung.

### Technische Grundlagen
- Plattform: iOS, SwiftUI, Combine/Swift Concurrency.
- Daten: HealthKit als Quelle der Wahrheit für Gesundheitsdaten; optionale lokale Cache-Ebene für Verlauf/Insights.
- Services: Core Location für Outdoor, Motion/Altimeter optional, Background Modes für kontinuierliches Tracking (energiesparend).
- Architektur: Modulare Schichten (UI, Domain, HealthKit-Adapter, Sensors), testbare Use-Cases.
- AI-Assistent: On-Device (z. B. Core ML) für Vorschläge; optional erweiterbar um serverseitige Modelle mit Privacy-Guardrails.
- watchOS Companion: HealthKit auf watchOS (HKWorkoutSession/HKLiveWorkoutBuilder); WatchConnectivity (WCSession) für Sync; WidgetKit/Komplikationen für Schnellstart; energieeffiziente Hintergrundsitzungen.

### Risiken & Annahmen
- HealthKit-Berechtigungen werden gewährt (Annahme) → sonst eingeschränkter Funktionsumfang.
- GPS-Genauigkeit und Herzfrequenzsensor-Verfügbarkeit variieren.
- Energieverbrauch bei Outdoor-Tracking muss optimiert werden.

### Nicht-Ziele (vorerst)
- Soziale Feeds, Challenges, breite Community-Funktionen.
- Umfangreiche Ernährungs- oder Schlaf-Module.

### Referenzen
- Apple HealthKit Doku: [HealthKit | Apple Developer](https://developer.apple.com/documentation/healthkit)
- HKWorkout: [Workout-Datenmodell](https://developer.apple.com/documentation/healthkit/hkworkout)
- watchOS Workouts: [HKWorkoutSession & LiveWorkoutBuilder](https://developer.apple.com/documentation/healthkit/hkworkoutsession)
- WatchConnectivity: [WCSession](https://developer.apple.com/documentation/watchconnectivity/wcsession)
- Komplikationen/WidgetKit: [WidgetKit für watchOS](https://developer.apple.com/documentation/widgetkit)

---
Stand: Initiale Vision. Dient als Leitplanke für Scope, Entscheidungen und Priorisierung.



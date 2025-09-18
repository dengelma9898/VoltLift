# HealthKit Write Path Review (T031)

Zielsetzung:
- Difficulty (1–10) bleibt lokal – wird NICHT nach HealthKit geschrieben.
- Gewicht je Satz: Nur lokal persistiert; in HealthKit aktuell NICHT als standardisiertes Feld verfügbar. Optional später als Metadaten (Custom Keys) am `HKWorkout` denkbar, aber geringe Interoperabilität.
- Duplikatvermeidung: Idempotentes Schreiben von Workouts; keine mehrfachen Workouts für denselben Zeitraum.

Bestehende Codebasis:
- Kein dedizierter HealthKit-Adapter im Repo vorhanden (nur Verweise in Vision/Plan).
- `PersistenceController.saveWorkoutEntries(_:)` enthält Platzhalter (TODO) für Mapping in Core Data/HealthKit.

Empfohlene Leitlinien:
1) Workout-Speicherung in HealthKit
   - Schreibe `HKWorkout` mit `HKWorkoutActivityType.traditionalStrengthTraining`.
   - Standard-Metriken: Dauer, Energie (falls vorhanden), Herzfrequenz (falls vorhanden).
   - KEINE Speicherung von per-Satz-Daten in HealthKit (Gewicht/Schwierigkeit) – lokal halten.
   - Idempotenz: Vor dem Schreiben prüfen, ob bereits ein Workout im selben Zeitfenster mit `metadata["VoltLiftSessionId"]` existiert; wenn ja, aktualisieren statt neu anlegen.

2) Gewicht/Schwierigkeit
   - Gewicht: nur lokal pro Satz in `WorkoutSetEntry.weightKg` (Schritt 0,5 kg, min 0).
   - Schwierigkeit (1–10): nur lokal pro Wiederholung in `WorkoutSetEntry.difficulties`.
   - HealthKit: keine standardisierte Struktur für per-Satz-Details – Verzicht auf Custom-Metadaten für Interop/Simplicity.

3) Duplikatvermeidung
   - `metadata["VoltLiftSessionId"] = UUID().uuidString` beim Start; bei Wiederaufnahme denselben Wert verwenden.
   - Vor Persistenz nach Workouts mit gleicher SessionId suchen; update-or-insert.

Follow-ups (separate Tasks):
- HK-Adapter erstellen (`HealthKitWorkoutWriter`) mit idempotentem Schreibe-Fluss.
- Permissions-Flow prüfen (HKHealthStore authorization für Workout/HR/Energie).
- Mapping von lokalem Verlauf (Detaildaten) zu aggregierten HealthKit-Workouts definieren (z. B. Summe Wiederholungen als optionale App-interne Statistik, nicht HealthKit).

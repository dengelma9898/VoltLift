# Research: Feintuning des generierten Trainingsplans

## Decisions
- Einseitig-Kriterien: Ableitung aus Übungstaxonomie (z. B. Flags in Exercise-Metadaten); nur für Übungen, die anatomisch einarmig/-beinig sinnvoll sind.
- Validierung: Keine Freitextfelder; Picker/Stepper mit gültigen Optionen. Wiederholungen ≥ 0; Satztyp ∈ {Aufwärmen, Normal, Abwärmen}.
- Gewicht: Nur bei Equipment-Übungen während aktivem Workout; Schritte 0,5 kg; Minimum 0; kein Maximum (praktisch über UI begrenzt).
- Schwierigkeit: Skala 1–10 pro Wiederholung nur während aktivem Workout; UI als kompaktes Rating-Element.
- Speichern: Explizites Speichern im Plan-Editor; während Workout beim Beenden persistieren.

## Rationale
- HIG & Einfachheit: Reduzierung von Fehlern durch vordefinierte Optionen; klare mentale Modelle.
- Data Integrity: Trennung von Plan (Soll) und Workout (Ist) vermeidet Vermischung; erleichtert HealthKit-Abbildung.
- UX Flow: Minimale Interaktion vor dem Start, nachträgliche Detailerfassung im Workout-Kontext.

## Alternatives Considered
- Freitext für Gewicht/Kommentare: Abgelehnt (Fehleranfällig, nicht HIG-konform, erschwert Validierung).
- Gewicht im Plan erfassen: Abgelehnt (Plan ist Vorlage; Ist-Daten gehören in die Ausführung).
- Schwierigkeit auf Satz-Ebene statt Wiederholung: Abgelehnt (Granularität gefordert; ggf. Aggregation später möglich).

## Open Points (resolved)
- Gewichtseinheit: Nur kg, Schritte 0,5.
- Minimalwerte: Wiederholungen ≥ 0; Gewicht ≥ 0.
- Bearbeitungssperren: Nur laufender Workout-Plan editierbar.

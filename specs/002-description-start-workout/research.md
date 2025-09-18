# Research: Start Workout Flow

## Decisions
- Timer‑Semantik: 2:00 Minuten zwischen jeder Wiederholung und zwischen letzter Wiederholung einer Übung und der ersten der nächsten Übung; kein Timer nach letzter Übung; nicht editierbar; startet automatisch bei Rep‑Bestätigung; endet automatisch.
- Signal bei Timer‑Ende: Haptik (CoreHaptics) oder kurzer Jingle (System‑Sound) als Hinweis zum Fortfahren.
- Ausführungsdaten bei Abbruch: Werden gespeichert; Planänderungen werden verworfen.
- Paralleles Editieren: Während aktiver Session gesperrt; andere Pläne erst nach Cancel/Finish editierbar.
- Planänderungen während Session: Dürfen vorgenommen werden; werden nur bei regulärem Abschluss in den Plan zurückgeschrieben.
- Gewicht/Schwierigkeit: Gewicht nur bei Equipment‑Übungen (Schritt 0,5 kg, ≥ 0), Schwierigkeit 1–10 pro Wiederholung.
- HealthKit: Keine Speicherung von per‑Rep‑Daten in HealthKit (Bestätigung gemäß `specs/001-specify-fine-tune/healthkit-review.md`).

## Rationale
- HIG & Einfachheit: Feste Timer‑Dauer reduziert UI‑Komplexität; klare Nutzererwartung durch Haptik/Jingle.
- Datenintegrität: Trennung zwischen Plan (Soll) und Ausführung (Ist); bewusste Persistenzregeln bei Finish vs Cancel.
- UX‑Flow: Per‑Übung‑Paging, Auto‑Advance, konsistente Glass‑Card‑Oberflächen gemäß Design System.

## Alternatives Considered
- Editierbarer Timer: Verworfen (mehr Komplexität, uneinheitlicher Flow, wenig Mehrwert aktuell).
- HealthKit‑Persistenz pro Rep: Verworfen (fehlende Standardfelder; geringe Interoperabilität; siehe Review).
- Zusammenfassung erst nach Home‑Navigation: Verworfen (fehlendes Feedback; schlechter Abschluss des Flows).

## Open Points (resolved)
- Geklärt: Reihenfolge der Eingabe (erst Gewicht/Schwierigkeit wählen, dann bestätigen).
- Geklärt: Timer‑Zeitpunkte (zwischen Reps & Übungen), Signalisierung (Haptik/Jingle), Persistenz bei Abbruch (nur Ausführungsdaten).



## AGENTS – Implementierungsregeln für VoltLift

Geltungsbereich: iOS- und watchOS-Code dieses Repos. Entscheidungen richten sich nach `PRODUCT_VISION.md` und Apples HIG. Bei Konflikten: Einfachheit, HIG, Vision in dieser Reihenfolge.

- Latest swift version: Verwende stets die aktuelle stabile Swift-Version (Projekt/CI regelmäßig aktualisieren).
- Latest swiftui version: Nutze die aktuelle stabile SwiftUI-Version (entsprechend der Xcode-Toolchain).
- Latest xcode version: Entwickle mit der aktuellen stabilen Xcode-Version.
- Follow apple design guidelines: Befolge die Apple Human Interface Guidelines (HIG) für iOS/watchOS.
- Use the corporate design: Nutze das Corporate Design (Farben, Typografie, Komponenten). Falls unklar, Rückfrage einholen.
- Ask whenever something is unclear: Unklarheiten sofort klären (Requirements, UX, Datenflüsse, Privacy).
- Do not overcomplicate things: Bevorzuge einfache, gut lesbare Lösungen (YAGNI, klare Verantwortung, wenige Abhängigkeiten).
- Use a well established architecture throughout the whole project.: Konsistente Architektur: Clean Architecture (Use-Cases/Domain) + MVVM, Swift Concurrency, Protokoll-basierte DI, modulare Schichten (UI, Domain, Adapter wie HealthKit/Location).
- Add tests where it makes sense.: Schreibe Tests dort, wo Nutzen am höchsten ist (Domain/Use-Cases, HealthKit-/Location-Adapter, kritische UI-Flows). Priorisiere Stabilität über 100% Coverage.
\- SwiftLint & SwiftFormat: Erzwinge konsistenten Stil. SwiftFormat für automatische Formatierung, SwiftLint für statische Analysen. Beide lokal (pre-commit) und in CI ausführen; PRs dürfen ohne grüne Checks nicht gemergt werden.

- Simulator-Build verifizieren: Bevor eine Aufgabe abgeschlossen wird, stets den Xcode MCP nutzen, um auf dem Simulator zu bauen/zu starten und sicherzustellen, dass die App wie erwartet funktioniert.



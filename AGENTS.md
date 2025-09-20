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


### Lokalisierung (L10n)

- Pflicht: Alle user-sichtbaren Texte (inkl. Accessibility-Labels/Values/Hints) werden über `Localizable.strings` lokalisiert. Keine Hardcoded-Strings in Views.
- Aktuelle Sprachen: Deutsch (`de.lproj/Localizable.strings`) und Englisch (`en.lproj/Localizable.strings`).
- Verwendung: `String(localized: "<key>")` oder `Text(String(localized: "<key>"))` in SwiftUI. Für Format-Strings Platzhalter nach Apple-Guidelines verwenden.
- Schlüssel-Konvention: dot-notiert und semantisch, z. B. `title.outdoor_activity`, `action.locate_me`, `activity.running`.
- Review-Kriterium: PRs müssen neue/angepasste Keys in beiden Sprachen enthalten.

### Tooling & Qualitätssicherung

- SwiftFormat: Vor Commit/Push ausführen (automatische Formatierung). In CI verpflichtend.
- SwiftLint: Vor Commit/Push ausführen (statische Analyse). In CI verpflichtend.
- Simulator-Build: Jede Aufgabe wird vor Abschluss mit einem Simulator-Build getestet. Verwende das VoltLift-Scheme im Workspace und einen iOS-Simulator (z. B. iPhone 16).
- Tests: Dort schreiben, wo sinnvoll (Domain/Use-Cases, Adapter, kritische UI-Flows). PRs ohne grüne Checks werden nicht gemergt.

### UI/Design-System Richtlinien

- Apple HIG und Corporate Design strikt befolgen (Farben, Typografie, Komponenten).
- Bevorzugte Komponenten: z. B. `VLGlassCard`, `VLPrimaryButtonStyle`, `VLSecondaryButtonStyle`, `VLIconButtonStyle` für Icon-Aktionen.
- Konsistente Abstände/Ecken/Schatten über `DesignSystem` nutzen (Spacing/Radius/Shadow/Gradient/ColorRole/Typography).

### Privacy & Berechtigungen

- Benötigte Berechtigungen früh klären. Info.plist-Keys hinzufügen (bevorzugt via Build-Settings `INFOPLIST_KEY_*`).
- Beispiel Standort: `NSLocationWhenInUseUsageDescription` mit nutzerfreundlichem, lokalisiertem Grund.

### Abschluss-Checkliste je Task

1. Anforderungen geklärt, HIG/Corporate Design eingehalten.
2. UI-Komponenten aus dem Design System verwendet.
3. Alle neuen Texte lokalisiert (`Localizable.strings` de/en), keine Hardcoded-Strings.
4. SwiftFormat ausgeführt, SwiftLint sauber.
5. Simulator-Build gestartet und manuell geprüft (Navigationsfluss, States, Permissions, A11y-Labels).
6. Relevante Tests ergänzt/aktualisiert.

### Hinweise zur Erweiterbarkeit (Beispiel Outdoor-Aktivitäten)

- Aktivitätsauswahl modular halten (Enum + View-Komponente), damit neue Aktivitäten mit minimalen Änderungen (Enum-Fall + Lokalisierung + Symbol) hinzugefügt werden können.


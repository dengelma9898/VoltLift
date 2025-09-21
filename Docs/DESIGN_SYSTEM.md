## VoltLift Design System (Light & Dark)

Quelle & Referenzen
- Apple HIG (Typography, Dynamic Type, Dark Mode)
- Trendfarben 2025 (Teal, Apricot/Orange-Akzente) – siehe Web-Suche in Ticket

Ziele
- Einfache, konsistente Tokens für Farben und Typografie
- Dark/Light-tauglich, AA-Kontrast als Mindestziel
- HIG-konform (SF Pro, Dynamic Type)

Typografie
- Font: System (SF Pro Text/Display via SwiftUI `Font.system`)
- Textgrößen (Mapping auf SwiftUI TextStyles)
  - Title XL → `.largeTitle .bold()`
  - Title L → `.title .bold()`
  - Title M → `.title2 .semibold()`
  - Title S → `.title3 .semibold()`
  - Body → `.body` (Standard-Lesetext)
  - Callout → `.callout`
  - Caption → `.caption`

Farben (Assets)
- VLPrimary (Brand)
  - Light: #0EA5A4 (bestehend)
  - Dark: #2DD4BF (bestehend)
- Zusatz-Gradients für Dark-UI (orientiert am Screenshot)
  - primary: purple → indigo (~#8B5CF6 → #3B63FA)
  - bluePurple: indigo → purple
  - tealBlue: teal → indigo (~#14B8A6 → #3B63FA)
- VLBackground
  - Light: #FFFFFF
  - Dark: #0B1229 (tiefes Navy)
- VLSurface (Karten/Controls)
  - Light: #F5F7FA
  - Dark: Material/Glas-Effekt auf Navy, Border Weiß 10–12% Opazität
- VLTextPrimary
  - Light: #0B0F1A
  - Dark: #F5F7FA
- VLTextSecondary
  - Light: #6B7280
  - Dark: #CBD5E1
- VLSuccess
  - Light: #22C55E
  - Dark: #86EFAC
- VLWarning
  - Light: #F59E0B
  - Dark: #FBBF24
- VLDanger
  - Light: #EF4444
  - Dark: #FCA5A5

Verwendung (SwiftUI)
- `Color("VLPrimary")` etc. (über `DesignSystem.ColorRole`-Wrapper nutzbar)
- `.tint(DesignSystem.ColorRole.primary)` für Buttons/Links
- Typografie via `DesignSystem.Typography` (z. B. `.font(DesignSystem.Typography.titleL)`)
- Spacing/Radius: `DesignSystem.Spacing`, `DesignSystem.Radius`
- Gradient: `DesignSystem.Gradient.primary`
- Zusätzliche Gradients: `DesignSystem.Gradient.bluePurple`, `DesignSystem.Gradient.tealBlue`
- ButtonStyles: `VLPrimaryButtonStyle`, `VLSecondaryButtonStyle`; Komponente `VLButton("Titel", style: .primary/.secondary/.destructive)`

Komponenten
- `VLButton`: einheitlicher CTA-Button mit drei Varianten
- `VLGlassCard`: Glas-/Transluzenz-Karte (Home-Optik, weißer Border 10%)
- `VLListRow`: Listenzeile mit führendem/abschließendem Content, Titel/Untertitel
- `VLWordmark`: zweifarbige Wortmarke (Text + Verlauf)
- `HomeView`/`MainTabView`: Startseite ähnlich Referenz mit Tabbar

Accessibility
- AA-Kontrast prüfen (Text vs. Hintergrund)
- Dynamic Type respektieren (TextStyles; keine fixen Punktgrößen)
- Nicht nur Farbe als Status-Indikator (Icons/Labels zusätzlich)

Brand-Guidelines
- Primärfarbe für zentrale Aktionen (Start Workout, CTA)
- Sekundärfarbe für sekundäre CTAs/Hervorhebungen
- Sparsame Verwendung von kräftigen Akzenten, Fokus auf ruhige Flächen

Base Design (Glas only)
- Hintergrund: `view.vlBrandBackground()`
- Textfarben: `DesignSystem.ColorRole.textPrimary` (weiß), `textSecondary` (weiß 0.85)
- Karten: ausschließlich `VLGlassCard { ... }` für Abschnitte, Status, CTAs
- Navigation/TabBar: `VLAppearance.applyBrandAppearance()` im App-Root, `.preferredColorScheme(.dark)`

Beispiel
```swift
VStack {
    VLGlassCard {
        Text("Title").font(DesignSystem.Typography.titleS)
        Text("Subtitle").font(DesignSystem.Typography.callout)
            .foregroundColor(DesignSystem.ColorRole.textSecondary)
    }
}
.padding(DesignSystem.Spacing.xl)
.vlBrandBackground()
```

## Seiten-Patterns (Cards statt List)

- Detailseiten (z. B. PlanDetailView)
  - Grundlayout: `ScrollView` + `VStack` mit `VLGlassCard`-Abschnitten; keine `List` mit grauem System-Hintergrund.
  - Header-Card: Titel, Meta (Exercise-Count, Created, Last used) in einer `VLGlassCard`.
  - Inhalt: Jede Übung als eigene `VLGlassCard` mit Titel und kompaktem Untertitel (z. B. Warm‑up/Working/Cool‑down‑Sets, Reps-Range inkl. Durchschnitt, Restzeit-Hinweis).
  - Abstände: `DesignSystem.Spacing.l`–`xl` zwischen Cards, Außenabstand `padding(DesignSystem.Spacing.xl)`.

- Listenübersichten (z. B. Saved Plans im Workout-Setup)
  - Ein übergeordneter Card-Container pro Abschnitt (Titel, Add-Action), darin Zeilen als `VLListRow`.
  - Für eigenständige Plan-Detaildarstellung: pro Plan eine `VLGlassCard` anstelle einer System-`List`.

## Bottom-CTAs (HIG-konform, ohne grauen Container)

- Primär: `ToolbarItem(placement: .bottomBar)` für Aktionen wie „Start Workout“/„Edit Plan“.
- Alternativ (falls nötig): `safeAreaInset(edge: .bottom) { ... }` mit ausreichendem `padding` – ohne zusätzlichen Material/Grau-Container, damit keine Kollision mit TabBar entsteht.
- Buttons: `VLButton`/`VLButtonLabel` nutzen, `.tint(DesignSystem.ColorRole.primary)` bzw. Sekundär/Destruktiv gemäß Design System.

## Do / Don’t

- Do: `ScrollView` + `VLGlassCard` für Abschnitte/Details verwenden.
- Do: Brand-Background via `.vlBrandBackground()` global aktiv halten.
- Do: Textfarben ausschließlich über `DesignSystem.ColorRole.text*` nutzen.
- Don’t: System-`List`-Hintergründe/Grauflächen für Detailseiten.
- Don’t: Zusätzliche graue Container unter Bottom-CTAs.

## Beispiel: Plan-Detail (Skeleton)

```swift
struct PlanDetailView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Spacing.l) {
                VLGlassCard { /* Header: Name, Created, Last used */ }
                ForEach(exercises) { exercise in
                    VLGlassCard {
                        Text(exercise.name)
                        Text(exercise.subtitle)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.ColorRole.textSecondary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .vlBrandBackground()
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                HStack(spacing: DesignSystem.Spacing.m) {
                    VLButton("Edit Plan", style: .secondary) { /* ... */ }
                    VLButton("Start Workout", style: .primary) { /* ... */ }
                }
            }
        }
    }
}
```


## Palette-Konsolidierung (Vorschlag)

Ziel: Wenige Grundfarben definieren, alle Ableitungen (Gradients, States, Opazitäten) konsequent daraus ableiten; eine Quelle der Wahrheit (Assets).

- Grundfarben (Assets als Quelle)
  - Primary: VLPrimary (Teal-Familie)
  - Background: VLBackground (Light #FFFFFF, Dark vereinheitlichen auf Navy 0x0F1729)
  - Surface: VLSurface (Light #F5F7FA, Dark = Background + Glas/Border 10–12%)
  - Text: VLTextPrimary/VLTextSecondary (Light: #0A0F19/#6B737F; Dark: #FFFFFF/85%)

- Statusfarben
  - Success: VLSuccess (#21C35E / #87F2AB)
  - Warning: VLWarning (#F59E0A / #FBBF24)
  - Danger: VLDanger (#F04444 / #FFA6A6)

- Gradients (aus Grundpalette abgeleitet)
  - primary: purple → indigo (~#8B5CF6 → #3B63FA)
  - bluePurple: indigo → purple
  - tealBlue: teal → indigo (~#14B8A6 → #3B63FA)

- Richtlinien
  - Keine Hardcoded-RGBs in Code (auch `DesignSystem.ColorRole.background`) – stattdessen Asset-Rollen verwenden
  - `textSecondary` konsistent über feste Töne oder Opacity, nicht beides gemischt
  - `VLSecondary` als Akzent prüfen: entweder gezielt für sekundäre CTAs oder durch Gradients ersetzen

- To‑Dos (Implementierung)
  1) VLBackground/VLSurface (Dark) harmonisieren und `DesignSystem.ColorRole.background` auf Asset mappen
  2) Textfarben-Strategie vereinheitlichen (Assets vs. Opacity) und Views migrieren
  3) Farbverwendung in Komponenten prüfen (Buttons, Karten, Tabbar) und auf Rollen mappen
  4) Dokumentation/Zeigestücke (Screens) updaten



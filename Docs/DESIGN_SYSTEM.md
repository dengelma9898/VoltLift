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



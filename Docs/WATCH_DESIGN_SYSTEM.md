## VoltLift Watch – Design System (Liquid‑Glass)

Bezug: `Docs/DESIGN_SYSTEM.md` (Farben, Typografie, Glass‑Tokens). Diese Kurzfassung beschreibt watchOS‑spezifische Leitlinien.

- Native‑first & HIG
- Quelle: Apple HIG – Designing for watchOS: https://developer.apple.com/design/human-interface-guidelines/designing-for-watchos
- Grundsatz: Immer zuerst native watchOS‑Elemente verwenden (List, NavigationLink, Button, Toolbar/Back, Grouped Insets). Nur dort eigen gestalten, wo es die HIG nicht abdeckt.
- Branding: Markenfarben sparsam einsetzen (z. B. Akzentfarbe, Buttons). Keine eigenen Hintergründe/Overlays, wenn sie System‑Navigation, Kontrast oder A11y beeinflussen.
- Layout: System‑Abstände und ‑Zeilenhöhen respektieren; keine überlagernden Overlays am Rand. Persistente Bottom‑Aktionen via `safeAreaInset(edge:.bottom)`.
- Typografie: Systemfonts belassen; nur Gewicht variieren. Truncation/Mehrzeiligkeit gemäß Bildschirmgröße.

- Hintergrund: Navy‑Ton, per `view.vlBrandBackground()`.
- Komponenten:
  - `VLGlassCard`: Material‑Layer + getönter Gradient + Border + Overlay‑Highlight.
  - `VLPrimaryButtonStyle`: Verlauf Purple→Teal, hohe Lesbarkeit, Dynamic Type.
- Typografie: `.title`/`.title3` für Header/Aktionen, sonst `.body`.
- Abstände: `Spacing.s/m/l/xl` (watch‑optimiert).
- Lokalisierung: Alle sichtbaren Texte via `Localizable.strings` (de/en).
- Startansicht: Wortmarke „VoltLift“, darunter Aktions‑Card mit zwei Buttons: „Strength“ und „Outdoor“.



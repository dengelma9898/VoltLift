# VoltLift Project Structure

## Root Directory Organization
```
VoltLift/
├── VoltLift/                    # Main app target
│   ├── VoltLift/               # Source code
│   │   ├── Assets.xcassets/    # App icons, colors, images
│   │   ├── Resources/          # Core app resources
│   │   ├── VoltLift.xcdatamodeld/ # Core Data model
│   │   └── VoltLiftApp.swift   # App entry point
│   └── VoltLift.xcodeproj/     # Xcode project files
├── VoltLiftTests/              # Unit tests
├── VoltLiftUITests/            # UI tests
└── Docs/                       # Documentation
```

## Source Code Architecture (`VoltLift/VoltLift/`)

### Resources Directory Structure
- **`Resources/`**: Core app components and design system
  - **`DesignSystem.swift`**: Centralized design tokens (colors, typography, spacing)
  - **`UI/`**: Reusable UI components and views
    - **Component files**: `VLButton.swift`, `VLGlassCard.swift`, etc.
    - **Screen directories**: `Home/`, `Workout/` for feature-specific views
    - **`MainTabView.swift`**: Root navigation structure

### Design System Conventions
- **Color Assets**: Named with `VL` prefix (VLPrimary, VLSecondary, etc.)
- **Component Naming**: `VL` prefix for all custom components (`VLButton`, `VLGlassCard`)
- **Style Protocols**: Dedicated ButtonStyle implementations (`VLPrimaryButtonStyle`)

## Key Architectural Patterns

### Design System Usage
- Centralized design tokens in `DesignSystem` enum
- Semantic color roles (primary, secondary, background, etc.)
- Consistent spacing, typography, and radius scales
- Gradient definitions for brand consistency

### UI Component Structure
- Reusable components with `VL` prefix
- Style variants through enums (`.primary`, `.secondary`, `.destructive`)
- Accessibility labels on all interactive elements
- Animation consistency with spring curves

### File Organization Rules
- Group related functionality in subdirectories
- Keep view files focused and under 400 lines
- Separate business logic from UI components
- Use descriptive, intention-revealing names

## Asset Management
- **Colors**: Defined in Assets.xcassets with semantic names
- **Dark Mode**: App uses `.preferredColorScheme(.dark)` globally
- **Brand Colors**: Custom color sets for consistent theming
- **Icons**: System SF Symbols preferred for consistency

## Navigation Structure
- **Root**: `MainTabView` with 4 tabs (Home, Activities, Progress, Settings)
- **Navigation**: `NavigationStack` for each tab's content
- **Tinting**: Global tint color set to `DesignSystem.ColorRole.primary`

## Testing Structure
- **Unit Tests**: `VoltLiftTests/` for business logic
- **UI Tests**: `VoltLiftUITests/` for user interaction flows
- **Test Naming**: Descriptive test method names following Given-When-Then pattern
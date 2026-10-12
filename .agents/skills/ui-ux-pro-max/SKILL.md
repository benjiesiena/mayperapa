---
name: ui-ux-pro-max
description: >-
  UI/UX design intelligence for web, mobile, and desktop applications. Use when designing, building,
  reviewing, or fixing interfaces, establishing design systems, component architecture, responsive behavior,
  accessibility standards (WCAG AA), typography, color palettes, and layout hierarchies.
---

# UI/UX Pro Max: Design Intelligence System

Repository: `https://github.com/nextlevelbuilder/ui-ux-pro-max-skill`

## 1. Rule Categories by Priority

| Priority | Category | Impact | Domain | Key Checks (Must Have) | Anti-Patterns (Avoid) |
|---|---|---|---|---|---|
| 1 | **Accessibility (WCAG AA)** | CRITICAL | `ux` | Contrast >= 4.5:1 (normal text) & >= 3:1 (large text/graphics), Alt text, Keyboard navigation, Aria-labels | Removing focus rings, Icon-only buttons without labels, Low contrast |
| 2 | **Touch & Interaction** | CRITICAL | `ux` | Min touch target 44×44px, 8px+ spacing, Immediate tactile feedback (`:active` scale) | Reliance on hover only, Instant state changes (0ms), Hidden interactive states |
| 3 | **Performance & Stability** | HIGH | `ux` | Reserve space to prevent layout shifts (CLS < 0.1), Optimized assets, Smooth 60fps renders | Layout thrashing, Cumulative layout shifts on load |
| 4 | **Style Selection** | HIGH | `style` | Match product domain, Curated theme coherence, High-quality SVG icons | Mixing inconsistent styles, Using raw emojis as icon substitutes |
| 5 | **Layout & Responsive** | HIGH | `ux` | Mobile-first breakpoints (`sm:640`, `md:768`, `lg:1024`, `xl:1280`), `min-h-[100dvh]` over `h-screen`, CSS Grid over flex-math | Horizontal scrollbars, Fixed px widths without max-width, Viewport overflow |
| 6 | **Typography & Color** | MEDIUM | `typography`, `color` | Base 16px, Line-height 1.5, Clear modular scale, Semantic design tokens | Text < 12px body, Gray-on-gray unreadable text, Uncalibrated raw hex |
| 7 | **Animation & Motion** | MEDIUM | `ux` | Context-aware timing (< 300ms for UI), Purpose-driven motion, Respect `prefers-reduced-motion` | Uniform duration for everything, Animating width/height instead of transform/opacity |
| 8 | **Forms & Feedback** | MEDIUM | `ux` | Explicit labels above inputs, Contextual validation near field, Distinct loading/empty/error states | Placeholder-as-label, Errors only at page top, Disorienting error jumps |
| 9 | **Navigation Patterns** | HIGH | `ux` | Predictable back behavior, Clear active indicators, Single-line desktop navigation | Overloaded navbars, Two-line desktop navigation wrapping |
| 10 | **Charts & Visualizations** | LOW | `chart` | Distinct color cues paired with text/tooltips, Clear legends, Accessible contrast | Relying on color hue alone to convey data |

## 2. Component Design Principles
- **Buttons & CTAs**: Visible focus rings, clear hover transitions, physical press feedback (`:active { transform: scale(0.97); }`), single-line label fit at desktop.
- **Form Controls**: Labels clearly positioned above inputs, helper text for formatting requirements, inline feedback for validation errors.
- **Card Containers**: Used only where elevation or grouping communicates true semantic relationship. Consistent corner radius scale throughout.
- **Empty & Loading States**: Clean skeleton loaders mirroring exact final layout rather than generic spinners; empty states guiding user on first action.

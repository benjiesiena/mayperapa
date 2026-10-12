# Design System & Interaction Engineering

This guide documents the design tokens, visual aesthetics, color harmony, and motion physics governing the **Budget Tracker** user experience.

---

## 1. Aesthetic Dials & Core Directives

The visual design is calibrated using **Taste Skill**, **UI/UX Pro Max**, **Emil Design Engineering**, and **Impeccable**:

| Dial | Setting | Intent |
| :--- | :--- | :--- |
| **Variance** | `7-8 / 10` | Distinctive hero cards, asymmetrical data splits, custom metric pills instead of boilerplate grids. |
| **Motion** | `6 / 10` | Tactile button press feedback, smooth progress bar loads, sub-200ms spring transitions. |
| **Density** | `4-5 / 10` | High visual scannability, ample white space around numbers, zero mechanical divider lines. |

### Anti-Default Mandates:
- **No generic AI purple/neon gradients.**
- **No mechanical `const Divider()` lines.** Surfaces and spatial padding (`16pt`/`24pt`) define section boundaries.
- **Zero raw floating-point displays.** All monetary figures are formatted cleanly via `CurrencyFormatter`.

---

## 2. Color Palette & WCAG AA Contrast

The color system uses deep slate neutrals paired with calibrated, high-trust accents:

### Light Mode (`AppColors.light`)
- **Background:** `#F8FAFC` (Slate 50 — calm, crisp, paper-like foundation)
- **Surface:** `#FFFFFF` (Pure white card surfaces)
- **Surface Variant:** `#F1F5F9` (Slate 100 — subtle input and pill background)
- **Text Primary:** `#0F172A` (Slate 900 — high contrast, effortless reading)
- **Text Secondary:** `#475569` (Slate 600 — clear supporting labels)
- **Border:** `#E2E8F0` (Slate 200 — delicate card outlines)
- **Primary Accent:** `#2563EB` (Cobalt/Blue 600 — authoritative, trustworthy fintech blue)
- **Positive (Inflow):** `#059669` (Emerald 600 — calibrated for WCAG AA readability)
- **Negative (Outflow):** `#E11D48` (Rose 600 — modern alert without jarring harshness)
- **Warning (Caution):** `#D97706` (Amber 600)

### Dark Mode (`AppColors.dark`)
- **Background:** `#0F172A` (Slate 900)
- **Surface:** `#1E293B` (Slate 800)
- **Text Primary:** `#F8FAFC` (Slate 50)
- **Primary Accent:** `#3B82F6` (Blue 500)
- **Positive:** `#10B981` (Emerald 500)
- **Negative:** `#FB7185` (Rose 400)

---

## 3. Emil Kowalski Interaction Physics

To make the application feel alive and responsive under the fingers, touchable elements implement custom spring physics:

### Tactile Press Feedback (`TactileBounce`)
```dart
TactileBounce(
  onTap: () => ...,
  scaleFactor: 0.97, // Emil Kowalski standard
  child: ...,
)
```
- **Scale Factor:** Scales down to `0.97` on finger down.
- **Timing:** `120ms` quick compression (`AppDurations.quick`).
- **Easing Curve:** Custom cubic-bezier easing `Cubic(0.23, 1.0, 0.32, 1.0)` (`AppCurves.easeOut`).
- **Applied To:** `PrimaryButton`, `SecondaryButton`, dashboard quick-action chips.

---

## 4. Component Hierarchy & Patterns

### 1. Hero Total Balance Card
- **Label:** `TOTAL AVAILABLE BALANCE` in uppercase caption with `letterSpacing: 0.9`.
- **Value:** `32pt` bold primary text (`#0F172A`).
- **Cash Flow Pill:** Pill badge displaying `+PHP 2,500 net this month` with directional indicator ($\uparrow$ / $\downarrow$).

### 2. Side-by-Side Cash Flow Split (`FinancialSummaryCard`)
- Grouped into two complementary cards: **Monthly Inflow** and **Monthly Outflow**.
- Features tinted circular icon badges (`#D1FAE5` green background for inflow, `#FFE4E6` rose background for outflow).

### 3. Tiered Budget Alert Bar (`BudgetProgress`)
- Safe (`< 75%`): Green pill badge, calm progress bar.
- Caution (`75% - 99%`): Amber pill badge, warning color.
- Exceeded (`>= 100%`): Rose pill badge with "Limit Reached" indicator.

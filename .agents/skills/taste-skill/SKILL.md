---
name: taste-skill
description: >-
  Anti-slop frontend visual direction skill for premium web applications, landing pages, and products.
  Enforces distinctive aesthetics, brand-appropriate typography, color calibration, layout variance,
  and strict anti-default discipline to prevent generic AI templates.
---

# Taste Skill: Anti-Slop Visual Direction & Design Taste

Repository: `https://github.com/Leonxlnx/taste-skill`

## 0. The Design Read & Anti-Default Discipline
- **Infer user intent and audience first**: State the one-line Design Read:
  > *"Reading this as: [product kind] for [audience], with a [vibe] language, leaning toward [aesthetic family]."*
- **Anti-Default Discipline**: Proactively ban generic clichés:
  - Banned: Purple-to-blue default gradient glows.
  - Banned: Centered hero over dark mesh blobs.
  - Banned: Three identical equal feature cards with icons.
  - Banned: Infinite-loop micro-animations everywhere.
  - Banned: Inter + slate-900 as the thoughtless default.
  - Banned: Div-based "fake screenshot" illustrations.

## 1. The Three Dials
- **`DESIGN_VARIANCE: 7-8`** (1 = Strict Symmetry, 10 = Artsy Chaos)
- **`MOTION_INTENSITY: 6`** (1 = Static, 10 = Cinematic Physics)
- **`VISUAL_DENSITY: 4-5`** (1 = Art Gallery Airy, 10 = Cockpit Packed Data)

## 2. Typography Rules
- **Sans Display Hierarchy**: Bold display headlines with tight tracking (`tracking-tight` or `tracking-tighter`), readable body paragraphs (`max-w-[65ch] leading-relaxed`).
- **Font Selection**: Reach beyond standard generic sans; pair display type with legible functional body (e.g. Outfit, Plus Jakarta Sans, Satoshi, Cabinet Grotesk, Geist).
- **Serif Discipline**: Use serif only when the brand or domain explicitly demands heritage/editorial/literary elegance; never inject random serif words into sans headlines.
- **Italic Clearance**: Ensure italic display words reserve descender clearance (`pb-1` / `leading-[1.1]`) so `y`, `g`, `j`, `p`, `q` are never clipped.

## 3. Color Calibration
- **One primary accent**: Maximum 1 vivid accent color with saturation calibrated (< 80% saturation default), grounded by rich neutrals.
- **Color Consistency Lock**: Chosen palette tokens apply throughout the entire page; no random color drift between sections.
- **High Contrast**: Ensure all text, badges, and CTAs pass WCAG AA minimums (4.5:1 for body text, 3:1 for large display elements).

## 4. Layout & Content Density
- **Hero Viewport Fitting**: Hero headline and primary CTA must be visible without scrolling; headline max 2 lines, subtext concise and purposeful.
- **Eyebrow Restraint**: Maximum 1 small-caps mono eyebrow per 3 sections. Do not slap an uppercase tracking label on every single block.
- **Bento & Feature Grids**: Diversify cells with real visual weight, varied spans, and distinctive highlights—not repetitive white boxes.
- **Navigation Height & Fit**: Nav bar single line at desktop, height capped at 64-80px.

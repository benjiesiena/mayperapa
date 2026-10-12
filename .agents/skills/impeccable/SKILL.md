---
name: impeccable
description: >-
  Visual critique, UI refinement, and craft floor enforcement for web and application interfaces.
  Use when reviewing or polishing interfaces for typography, spacing, visual consistency, alignment,
  contrast, hierarchy, anti-patterns, and finishing passes.
metadata:
  version: 4.4.0
---

# Impeccable: Visual Critique & Refinement

Repository: `https://github.com/pbakaus/impeccable`

## Craft Principles
1. **Out-of-Distribution Craft**:
   - Reject timid, generic, and measured UI defaults.
   - Enforce production-grade polish, peak visual clarity, deliberate typography, and immaculate spacing.
2. **Deterministic Anti-Pattern Checks**:
   - **No AI purple/violet glow gradients** as lazy default styling.
   - **No nested generic card-in-card containers**.
   - **No uncalibrated, chaotic spacing**: enforce strict 4px/8px modular rhythm.
   - **No low-contrast illegible text**: audit contrast ratio (WCAG AA min 4.5:1).
   - **No wrapped button CTAs**: CTA labels must sit comfortably on one line.
   - **No duplicate CTA intent**: use consistent phrasing for primary user actions across nav, hero, and footer.
   - **No random corner radii**: maintain consistent border radius rules across cards, inputs, and buttons.
3. **Execution Review & Polish Workflow**:
   - Inspect visual truth at responsive breakpoints (Mobile: 375px-480px, Tablet: 768px, Desktop: 1200px+).
   - Verify alignment, visual weight, rhythm, and optical balance.
   - Conduct bounded pass review: review -> identify defects -> fix in one batched sweep -> verify -> done.

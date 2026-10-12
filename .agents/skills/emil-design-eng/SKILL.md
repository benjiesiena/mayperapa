---
name: emil-design-eng
description: >-
  Frontend craftsmanship and interaction design engineering by Emil Kowalski.
  Use when designing interactions, micro-animations, button physics, component feel,
  easing curves, and motion timing for polished, responsive interfaces.
---

# Emil Design Engineering: Frontend Craftsmanship & Interaction

Repository: `https://github.com/emilkowalski/skills`

## Core Philosophy
- **Taste is trained, not innate**: Good taste is the ability to see beyond the obvious and elevate details.
- **Unseen details compound**: Invisible correctness creates interfaces people love without knowing why.
- **Beauty is leverage**: Feel and feedback differentiate exceptional software from commodity software.

## The Animation Decision Framework
1. **Should this animate at all?**
   - High frequency (keyboard shortcuts, frequent toggles): **No animation**.
   - Medium frequency (hover effects, list clicks): **Subtle, ultra-fast or reduced**.
   - Occasional (dialogs, drawers, toasts): **Standard animation (< 300ms)**.
   - Never animate keyboard-initiated actions.
2. **Purpose-driven Motion**:
   - Feedback (press response), spatial consistency (drawers/toasts entering/exiting predictably), state transitions.
3. **Easing Curves**:
   - Entering elements: `ease-out` (starts fast, feels immediately responsive).
   - Moving/morphing elements: `ease-in-out`.
   - **Never use `ease-in` for UI animations** (it feels sluggish and delays feedback).
   - Custom easing tokens:
     ```css
     --ease-out: cubic-bezier(0.23, 1, 0.32, 1);
     --ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);
     --ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);
     ```
4. **Timing & Speed**:
   - Button press feedback: 100-160ms
   - Tooltips & small popovers: 125-200ms
   - Dropdowns & selects: 150-250ms
   - Modals & drawers: 200-300ms
   - Keep UI interactions under 300ms.

## Component Craft Rules
- **Tactile Buttons**: Always apply `:active { transform: scale(0.97); }` with `transition: transform 160ms cubic-bezier(0.23, 1, 0.32, 1);`.
- **Never animate from `scale(0)`**: Start entrances from `scale(0.95)` with `opacity: 0` to preserve physical mass.
- **Origin-aware Popovers**: Popovers and menus should scale outward from their trigger's transform-origin, not the dead center of the screen.
- **Springs for Continuous Gestures**: Use springs with subtle damping/bounce for drag, swipe, or momentum-based movement.

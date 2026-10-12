# AGENTS.md — Engineering Governance & AI System Architecture

This document defines the engineering standards, architectural patterns, workflow protocols, and AI governance for the **Budget Tracker** application. All AI agents, contributors, and automated tooling must strictly comply with these rules.

---

## 1. Governance & Skill Precedence Hierarchy

The project integrates 5 official AI skills located in [`.agents/skills/`](file:///c:/Users/jbsie/Music/mayperapa/.agents/skills/). When guidelines or instructions overlap or conflict, resolve them using this strict hierarchy:

1. **Project Explicit Requirements**: Direct user constraints, domain rules, and user-specified feature requirements.
2. **Existing Architecture & Conventions**: Existing codebase structure, design tokens, and modular contracts.
3. **Superpowers ([`obra/superpowers`](https://github.com/obra/superpowers))**: Development lifecycle, planning, TDD implementation, systematic debugging, code review.
4. **UI/UX Pro Max ([`nextlevelbuilder/ui-ux-pro-max-skill`](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill))**: Component hierarchies, responsive layout systems, accessibility standards (WCAG AA), forms, navigation.
5. **Taste Skill ([`Leonxlnx/taste-skill`](https://github.com/Leonxlnx/taste-skill))**: Visual direction, design read, 3-dial configuration (`Variance: 7-8`, `Motion: 6`, `Density: 4-5`), anti-default aesthetics, color harmony.
6. **Emil Design Engineering ([`emilkowalski/skills`](https://github.com/emilkowalski/skills))**: Interaction engineering, micro-interactions, button physics (`:active scale(0.97)`), custom cubic-bezier easing (`--ease-out`), sub-300ms timing.
7. **Impeccable ([`pbakaus/impeccable`](https://github.com/pbakaus/impeccable))**: Critical design review, craft floor enforcement, spacing rhythm, anti-pattern detection, final finish pass.

---

## 2. Advanced Data Gathering & Requirements Engineering

Before writing code or scaffolding files, agents must gather complete, unambiguous requirements:

### 2.1 Intent Discovery & Domain Probing
- **Identify Core Value & Stakeholders**: Determine the primary user jobs-to-be-done (e.g., daily expense logging, monthly category capping, savings goal tracking, financial reporting).
- **Proactive Constraint Analysis**: Probe for critical boundaries:
  - *Data Boundary*: Offline-first vs. cloud sync, localStorage limits, schema migration requirements.
  - *Financial Boundary*: Currency formatting (multi-currency vs. single fixed), decimal precision (handling cents/fractional amounts via integer cents to prevent floating-point inaccuracies), tax/fee handling.
  - *Temporal Boundary*: Frequency of budgeting (monthly, weekly, pay-period based), rollover balances, recurring transactions.
- **Socratic Clarification Protocol**: If requirements leave a major architectural branch ambiguous, formulate exactly **one** targeted, high-signal question with clear trade-offs. Never dump open-ended surveys on the user. When context is sufficient, infer reasonably, declare the assumption explicitly, and proceed.

### 2.2 Deep Environment & Repository Inspection
- Always inspect the filesystem, existing dependencies, config files, and data fixtures before making architectural choices.
- Never assume an external tool, library, or global binary exists without explicit verification (`Get-Command`, checking `package.json`, or checking paths).

---

## 3. System Design & Architectural Patterns

The codebase adheres to **Clean Architecture** principles to ensure long-term testability, maintainability, and zero code duplication.

```
src/
├── domain/         # Core business entities, calculation engines, budget math (Pure JS/TS, zero DOM dependencies)
├── storage/        # Persistence adapters, repositories, migrations, serialization (Interface-driven)
├── services/       # Application use-cases, orchestration, data aggregation, export/import
├── ui/             # View layer, component renderers, event controllers, DOM bindings
│   ├── components/ # Reusable UI components (metrics card, transaction list, category bar, modals)
│   └── views/      # Page-level compositions (Dashboard, Transactions, BudgetPlanner, Analytics)
├── styles/         # Design system tokens (typography, colors, spatial scale, easing curves)
└── utils/          # Pure helper utilities (currency formatters, date helpers, sanitizers)
```

### 3.1 Separation of Concerns & Clean Boundaries
- **Domain Layer (Core)**:
  - Contains all financial calculations (net balance, category spending percentages, threshold alerts, savings projections).
  - Must remain **100% pure**: zero DOM manipulation, zero `window` or `document` access, zero direct storage calls.
  - Must be independently unit-testable in any environment.
- **Storage Layer (Repository Pattern)**:
  - Access to `localStorage`, `IndexedDB`, or remote APIs must be encapsulated behind an abstract `StorageRepository` interface.
  - Features must interact with high-level methods (e.g., `saveTransaction()`, `getTransactionsByMonth()`), never raw storage keys directly.
  - Implement robust data serialization and schema versioning (`schemaVersion: 1`) to enable lossless future migrations.
- **UI / Presentation Layer**:
  - Components are responsible solely for rendering state and dispatching user actions.
  - No business calculations or financial math inside event listeners or render functions.

### 3.2 Single Source of Truth & DRY (Don't Repeat Yourself)
- **Centralized State Management**:
  - The application maintains a single, predictable state store following unidirectional data flow:
    $$\text{User Action} \longrightarrow \text{Domain Service / Dispatcher} \longrightarrow \text{State Store} \longrightarrow \text{UI Subscription Re-render}$$
  - No duplicated, out-of-sync state variables across different components.
- **Reusable Formatters & Constants**:
  - Currencies, dates, category metadata (labels, icons, colors), and validation thresholds must be declared in dedicated dictionary modules and reused everywhere.
  - Zero magic numbers or hardcoded string literals scattered across files.

### 3.3 Financial Data Precision & Integrity
- **Integer Cents Representation**: Store currency values as integer cents (`$49.99` $\to$ `4999`) internally to eliminate IEEE 754 floating-point rounding errors (`0.1 + 0.2 !== 0.3`). Format to display currency only at the presentation boundary.
- **Immutable Entity Updates**: Never mutate transactions or budget objects in place; always return fresh immutable instances (`{ ...item, amount: newAmount, updatedAt: Date.now() }`).
- **Defensive Validation**: Validate all user input at the boundary using schema validators before allowing data into domain storage.

---

## 4. End-to-End Application Workflow

Development follows the structured engineering process specified by **Superpowers**:

### Phase 1: Planning & Design Spec
1. Conduct the **Design Read** and define the aesthetic dials (Taste Skill).
2. Classify task scope:
   - *Bounded*: Localized modification to existing modules. Present in-chat proposal and obtain approval.
   - *Architectural*: New system or major subsystem. Produce written specification covering schema, state model, and UX wireframe.
3. Write an implementation plan with bite-sized, checkable task units.

### Phase 2: Test-Driven Development (TDD)
1. **Red**: Write a focused unit test exercising the domain logic, calculation, or storage adapter before implementation.
2. **Green**: Implement the minimal, clean code required to satisfy the test.
3. **Refactor**: Clean up duplication, enforce design patterns, and ensure strict adherence to style tokens while keeping tests green.

### Phase 3: Interaction & Frontend Craftsmanship
1. **Emil Design Engineering Principles**:
   - Provide instantaneous feedback on press (`:active { transform: scale(0.97); }`).
   - Use custom cubic-bezier easing tokens (`--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`).
   - Keep interactive transitions strictly under 300ms.
   - Never animate entering elements from `scale(0)` (start from `scale(0.95)` with opacity fade).
2. **Taste Skill Aesthetics**:
   - Distinctive typography with calibrated hierarchy.
   - One primary accent color with saturation < 80% on rich, tailored neutrals.
   - Strict ban on generic AI purple gradients, dark mesh cards, and div-based fake screenshots.

### Phase 4: Critique, Review & Hardening
1. **Impeccable Polish Pass**:
   - Execute deterministic anti-pattern checks: no wrapped CTA text, no duplicate intent buttons, no inconsistent corner radii.
   - Audit WCAG AA contrast (minimum 4.5:1 for body text, 3:1 for large display elements).
   - Verify layout stability and responsive behavior across 3 primary breakpoints: Mobile (375px–480px), Tablet (768px), and Desktop (1200px+).
2. **Defensive Error Handling**:
   - Graceful fallback for corrupted local storage or invalid import data.
   - Clear empty states indicating how the user can take action.
   - Contextual inline error messages instead of disruptive alerts.

---

## 5. Application Security & Defensive Engineering Standards

Financial software must be secure by design, even when running client-side or offline. All code contributions must adhere to these security mandates:

### 5.1 XSS Prevention & DOM Injection Mitigation
- **Zero-Unsanitized-DOM Rule**: Never use `element.innerHTML`, `outerHTML`, or `document.write` with user-supplied or unescaped data. Always use `element.textContent`, DOM creation methods (`document.createElement()`, `DocumentFragment`), or safe attribute setters.
- **Dynamic Attribute Guard**: Never bind user input directly to URL-bearing attributes (`href`, `src`, `action`) without protocol validation (permit only `http:`, `https:`, or explicit `blob:` URLs for data exports; strictly forbid `javascript:` pseudo-protocols).
- **Template Isolation**: When rendering template literals, bind dynamic text values via standard DOM text nodes or sanitize through an explicit whitelist-based utility.

### 5.2 CSV Formula Injection (DDE) & File Import Defense
- **CSV Export Sanitization**: When exporting financial records to CSV format, sanitize all cell values against spreadsheet formula execution:
  - If a cell string begins with dangerous formula operators (`=`, `+`, `-`, `@`, `\t`, `\r`), prepend a single quote (`'`) to ensure spreadsheet tools (Excel, Google Sheets, LibreOffice) treat it strictly as literal text.
- **Defensive File Ingestion**:
  - Bound file upload sizes (e.g., maximum 5MB for JSON/CSV imports) to eliminate browser memory exhaustion or Denial-of-Service (DoS).
  - Parse imported files defensively inside structured `try...catch` blocks. Validate every ingested record against the domain schema before state hydration; reject or sanitize unexpected properties.

### 5.3 Prototype Pollution & State Poisoning Guard
- **Safe Dictionary Dictionaries**: Use `Object.create(null)` or ES6 `Map` instances for dynamic lookups instead of plain object literals `{}`.
- **Forbidden Key Stripping**: Defensively reject or strip dangerous property names (`__proto__`, `constructor`, `prototype`) during deep merging, cloning, or JSON parsing.
- **Immutability of Constants**: Wrap core dictionaries (currency lists, default category metadata, validation bounds) with `Object.freeze()` to prevent runtime mutation or tampering.

### 5.4 Client Storage Hygiene & Data Privacy
- **Untrusted Storage Boundary**: Treat all data read from `localStorage` or `IndexedDB` as untrusted input. Validate every field against schema contracts before passing into domain logic.
- **Sensitive Data Minimization**: Never persist unhashed credentials, session tokens, or sensitive personal identifiers in plaintext local storage.
- **Tab-Nabbing Mitigation**: Any outbound external links must strictly specify `rel="noopener noreferrer"`.

---

## 6. AI Pair Programming & Code Integrity Standards

When proposing or implementing code changes, agents must follow these operational rules:

1. **Maintain Architectural Integrity**: Respect module boundaries. Do not write ad-hoc logic into monolithic files.
2. **Zero Dead Code & Zero Technical Debt**: Remove obsolete code, unused imports, and commented-out blocks immediately. Do not leave placeholder comments like `// TODO: Implement later`.
3. **Preserve Documentation & Context**: Maintain comprehensive JSDoc/TSDoc headers on domain functions explaining parameters, return shapes, and edge cases.
4. **Verification Before Completion**: Run automated tests, verify DOM accessibility attributes, and check console cleanliness before declaring any task complete.


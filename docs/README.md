# Budget Tracker — Documentation Hub

Welcome to the documentation repository for the **Budget Tracker** mobile application. This hub provides comprehensive technical references, architectural patterns, design standards, and audit trails.

---

## 📚 Documentation Index

### 1. Engineering Governance & Architecture
- **[AGENTS.md](file:///c:/Users/jbsie/Music/mayperapa/AGENTS.md)** — Core AI governance, skill hierarchy (Superpowers, Taste Skill, UI/UX Pro Max, Emil Design, Impeccable), Clean Architecture rules, and security best practices.
- **[System Architecture](file:///c:/Users/jbsie/Music/mayperapa/docs/architecture/system_architecture.md)** — Layer boundaries, unidirectional data flow, cold-start bootstrap/seeding flow, and on-device AI orchestration.
- **[AI Features & On-Device LLM](file:///c:/Users/jbsie/Music/mayperapa/docs/architecture/ai_features_and_llm.md)** — Complete specification of the 19 financial tools, dual-engine fallback, In-App Hugging Face model download, and "Can I Afford This?" calculation engine.
- **[PRD & Technical Specification](file:///c:/Users/jbsie/Music/mayperapa/mayperapa/PRD_AND_TECHNICAL_SPECIFICATION.md)** — Full functional specification, data models, wireframes, and business rules.

### 2. Design System & Frontend Craftsmanship
- **[Design System & Interaction Engineering](file:///c:/Users/jbsie/Music/mayperapa/docs/design/design_system.md)** — Color palettes (Slate, Cobalt, Emerald, Rose), Emil Kowalski button physics (`TactileBounce`, `:active scale(0.97)`), motion curves, and scannable card hierarchies.

### 3. Testing, Verification & Quality Assurance
- **[Testing & Verification Guide](file:///c:/Users/jbsie/Music/mayperapa/docs/guides/testing_and_verification.md)** — Automated test suite structure, unit test catalog, smoke testing, and TDD workflow.

### 4. Audit & Progress Tracking
- **[Changelog & Audit Trail](file:///c:/Users/jbsie/Music/mayperapa/CHANGELOG_AUDIT.md)** — Permanent audit log recording defect root causes, architectural fixes, files modified, and verification results.

---

## 📂 Repository Directory Map

```
c:\Users\jbsie\Music\mayperapa\
├── AGENTS.md                  # Engineering governance & security standards
├── CHANGELOG_AUDIT.md         # Permanent audit trail and remediation history
├── README.md                  # Workspace entry point
├── docs/                      # Central technical documentation hub
│   ├── README.md              # Documentation index (this file)
│   ├── architecture/          # Architecture blueprints and data flows
│   ├── design/                # Design tokens, color palettes, and motion specs
│   └── guides/                # Testing, TDD, and operational workflows
└── mayperapa/
    ├── PRD_AND_TECHNICAL_SPECIFICATION.md  # Product specification
    ├── README.md                           # Flutter app setup & user guide
    └── mayperapa/                     # Flutter / Dart application source
        ├── lib/                            # Application code
        └── test/                           # Unit and widget test suite
```

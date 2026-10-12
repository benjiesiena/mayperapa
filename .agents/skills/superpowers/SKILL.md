---
name: superpowers
description: >-
  Disciplined development workflow framework for AI coding agents. Enforces structured software development:
  planning and requirements (brainstorming, writing-plans), implementation (executing-plans),
  testing (TDD: test-driven development), debugging (systematic 4-phase root-cause analysis), and code review.
---

# Superpowers: Development Workflow Methodology

A disciplined software development methodology for AI pair programming and agentic workflows.
Repository: `https://github.com/obra/superpowers`

## Core Workflow Sequence
1. **Brainstorming & Requirements**:
   - Discover intent, constraints, and success criteria.
   - Classify path: Spike, Bounded, or Architectural.
   - For Architectural/New Projects: produce a written specification and obtain approval before code.
2. **Writing Plans**:
   - Create comprehensive, step-by-step implementation plans (`docs/plans/...` or task checklist).
   - Right-size tasks: each task has its own test cycle and checkable deliverable.
3. **Implementation & TDD**:
   - Follow RED-GREEN-REFACTOR cycle. Write test first, confirm failure, implement minimal code, verify green.
   - Maintain DRY, YAGNI, and frequent commits.
4. **Systematic Debugging**:
   - 4-phase root cause analysis: Reproduce & isolate, inspect logs/state, formulate hypothesis, verify fix before moving on.
5. **Code Review & Verification**:
   - Request and perform comprehensive code review before completing development branches.
   - Verification before completion: tests pass, lint/type checks pass, responsive verification complete.

# Testing & Quality Verification Guide

This guide details the automated test suite, TDD protocols (Superpowers), and verification steps for the **Budget Tracker** application.

---

## 1. Test Suite Architecture

The test suite is partitioned into focused unit and widget smoke tests:

| Test File | Target | Coverage |
| :--- | :--- | :--- |
| `test/widget_test.dart` | `BudgetTrackerApp` & `AppShell` | Verifies bottom navigation bar tabs (Home, Transactions, Budget, Goals, AI) render without crashing. |
| `test/unit/financial_calculator_test.dart` | `FinancialCalculator` | Exercises net balance calculation, income/expense splits, category breakdowns, savings rates, and date filters. |
| `test/unit/seed_defaults_test.dart` | `Category.defaults()` & `Account.defaults()` | Verifies that starter categories and accounts deserialize with correct types, valid icons, and default currencies. |
| `test/unit/financial_tools_registry_test.dart` | AI Tool Invocations | Tests parameter parsing, balance lookups, budget queries, and tool execution isolation with in-memory fakes. |
| `test/unit/ai_orchestrator_test.dart` | `AIOrchestrator` Pipeline | End-to-end question answering pipeline ensuring real user prompts resolve against financial tools accurately. |

---

## 2. Test-Driven Development (TDD) Workflow

In accordance with [AGENTS.md](file:///c:/Users/jbsie/Music/mayperapa/AGENTS.md) and the **Superpowers** skill, all domain and repository enhancements follow the Red-Green-Refactor cycle:

1. **Red:** Write a failing test in `test/unit/` exercising the new financial formula, tool, or repository method before writing production code.
2. **Green:** Write the minimal clean implementation in `domain/` or `data/` required to satisfy the assertion.
3. **Refactor:** Remove duplicate logic, ensure immutability (`copyWith`), enforce strict typing, and keep all tests passing.

---

## 3. Running Tests Locally

When Flutter and Dart are installed on your environment:

```bash
# Run all unit and widget tests
flutter test

# Run a specific unit test file
flutter test test/unit/seed_defaults_test.dart

# Run with test coverage
flutter test --coverage
```

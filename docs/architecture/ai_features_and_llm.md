# AI Assistant & On-Device LLM Architecture

This document defines the features, tool registry, local LLM execution pipeline, in-app download flow, and mathematical safety guardrails for the **Budget Tracker** AI Assistant.

---

## 1. Feature Specifications

The AI Assistant provides intelligent, privacy-first personal finance capabilities powered by on-device intelligence and verified financial math:

### Feature 1: "Can I Afford This?" Feasibility Calculator
- **User Story:** A user contemplating a discretionary purchase (e.g., *"Can I afford to spend ₱4,500 on a monitor this weekend?"*) asks the assistant.
- **Underlying Tools:** `calculate_affordable_spending`, `get_current_balance`, `get_remaining_budget`.
- **Logic:** Evaluates current available balance minus committed recurring bills due before the next expected income, checks the relevant category's remaining budget, and verifies whether the purchase will violate the target savings buffer.
- **Output:** Clear verdict ("Yes, comfortably", "Caution", or "No, will exceed budget") with exact numerical justification.

### Feature 2: Natural Language Spending Breakdown & Trends
- **User Story:** *"Where did I spend the most money this month?"* or *"How much did I spend on Grab/Transport in March?"*
- **Underlying Tools:** `get_expenses_by_category`, `get_top_spending_categories`, `get_spending_trends`, `search_transactions`.
- **Output:** Breakdown of total spend, percentage share per category, top merchants/transactions, and week-over-week comparisons.

### Feature 3: Budget Health & Limit Monitoring
- **User Story:** *"How is my food budget doing?"* or *"Am I close to exceeding any budget?"*
- **Underlying Tools:** `get_budget_status`, `get_remaining_budget`.
- **Output:** Categorical progress, spent vs limit, days remaining in the budgeting cycle, and recommended daily spending velocity to remain under budget.

### Feature 4: Cashflow Run-Rate & Month-End Forecasting
- **User Story:** *"How much money will I have left at the end of the month?"*
- **Underlying Tools:** `calculate_cashflow_forecast`, `get_income_vs_expense`.
- **Logic:** Projects end-of-month balance using:
  $$\text{Projected Balance} = \text{Current Balance} + \text{Remaining Income} - (\text{Daily Expense Velocity} \times \text{Remaining Days}) - \text{Pending Recurring Bills}$$

### Feature 5: Recurring Bill & Subscription Audit
- **User Story:** *"What are my recurring monthly expenses?"*
- **Underlying Tools:** `get_recurring_expenses`, `calculate_recurring_monthly_total`.
- **Output:** Comprehensive list of active subscriptions, due dates, payment accounts, and monthly total commitment.

### Feature 6: Advanced "What-If" Multi-Hop Scenario Simulation
- **User Story:** *"What if I cut dining out by ₱2,000 and buy a ₱15,000 phone, how fast will I reach my Japan Trip goal?"* or *"If I cancel my gym subscription and cut coffee, can I buy a laptop?"*
- **Underlying Tools:** `simulate_financial_scenario`, `get_all_goals`, `get_current_balance`, `calculate_cashflow_forecast`.
- **Logic:** Multi-variable financial projection linking proposed discretionary expenses, expense reductions, recurring bill changes, and target goal progress acceleration:
  $$\Delta \text{Monthly Savings} = \text{Expense Cut} + \text{Cancelled Recurring Bills}$$
  $$\text{Adjusted Balance} = \text{Current Balance} - \text{Proposed Purchase}$$
  $$\text{Months Saved to Goal} = \text{Current Months to Target} - \text{New Months to Target}$$
- **Output:** Multi-step analytical verdict with adjusted monthly savings rate, purchase safety check, and exact months shaved off target goals.

---

## 2. Dual-Engine Architecture & Safe Fallback

To ensure the app remains responsive regardless of device hardware or network status:

```
                            ┌────────────────────────┐
                            │    User Chat Prompt    │
                            └───────────┬────────────┘
                                        ▼
                            ┌────────────────────────┐
                            │     AIOrchestrator     │
                            └───────────┬────────────┘
                                        ▼
                           Is Llama 3.2 GGUF Ready?
                                  /          \
                           YES   /            \   NO / Downloading
                                ▼              ▼
                    ┌───────────────────┐  ┌───────────────────┐
                    │ LocalLLMAIEngine  │  │ RuleBasedAIEngine │
                    │ (Llama 3.2 1B)    │  │ (Instant Offline) │
                    │ + Few-Shot Prompts│  │ + Colloquial RegEx│
                    └─────────┬─────────┘  └─────────┬─────────┘
                              │                      │
                              └───────────┬──────────┘
                                          ▼
                         ┌─────────────────────────────────┐
                         │   FinancialToolsRegistry        │
                         │   (20 Local SQLite Tools)       │
                         └────────────────┬────────────────┘
                                          ▼
                         ┌─────────────────────────────────┐
                         │   AIResponseValidator           │
                         │   (Zero-Hallucination Guard)    │
                         └────────────────┬────────────────┘
                                          ▼
                         ┌─────────────────────────────────┐
                         │   Verified Natural Language UI  │
                         └─────────────────────────────────┘
```

1. **LocalLLMAIEngine (Primary when downloaded):** Uses `llama_cpp_dart` to execute `Llama-3.2-1B-Instruct.Q4_K_M.gguf` on-device. Equipped with few-shot exemplars and resilient JSON block parsing (`\{[\s\S]*?\}`) to ensure high-accuracy tool calling despite 1B parameter scale.
2. **RuleBasedAIEngine (Resilient Fallback):** Activated when the model is not downloaded or if an inference timeout occurs. Enhanced with colloquial Philippine and conversational English pattern recognition (*"wallet have enough"*, *"budget take"*, *"got enough cash"*, *"what if"*), executing multi-parameter scenario extractions with zero latency.

---

## 3. In-App Download Pipeline (`ModelDownloadService`)

Users can download the model on-demand directly inside the app without manual file management:

- **Source:** Hugging Face repository (`QuantFactory/Llama-3.2-1B-Instruct-GGUF`).
- **File:** `Llama-3.2-1B-Instruct.Q4_K_M.gguf` (~800 MB).
- **Storage Target:** `<app_documents_directory>/models/`.
- **Features:**
  - Resumable download chunks via `Dio`.
  - Real-time progress bar (received MB / total MB and percentage).
  - Validation check: verifies downloaded size exceeds minimum threshold (50MB) before activating.
  - Non-blocking: users can dismiss the sheet and use the chat via the fallback engine while downloading.

---

## 4. The 20 Financial Tools Catalog

Every tool is independently unit-tested and implemented in `financial_tools_registry.dart`:

1. `get_current_balance` — Net total across all active accounts.
2. `get_account_balances` — Breakdown by individual account (Cash, Bank, Savings).
3. `get_monthly_income` — Aggregated income for the calendar month.
4. `get_monthly_expenses` — Aggregated expenses for the calendar month.
5. `get_expenses_by_category` — Map of category ID to total spend.
6. `get_spending_trends` — Week-over-week spending velocity.
7. `get_recent_transactions` — List of latest money movements with descriptions.
8. `get_budget_status` — Overall status of active budget plan.
9. `get_remaining_budget` — Unspent allowance for current budget.
10. `get_all_goals` — Savings goals targets and deadlines.
11. `get_goal_progress` — Current funded balance vs target amount.
12. `calculate_affordable_spending` — Discretionary spending safety check.
13. `calculate_cashflow_forecast` — End-of-month balance projection.
14. `calculate_savings_rate` — Savings as a percentage of total income.
15. `get_recurring_expenses` — Active scheduled subscriptions/bills.
16. `calculate_recurring_monthly_total` — Monthly sum of recurring bills.
17. `get_top_spending_categories` — Top 3-5 categories by spend amount.
18. `get_income_vs_expense` — Inflow vs outflow ratio.
19. `search_transactions` — Keyword text search across transaction notes and descriptions.
20. `simulate_financial_scenario` — Hypothetical "what-if" multi-variable simulation evaluating proposed purchases, expense cuts, subscription cancellations, and goal completion acceleration.

---

## 5. Advanced Mathematical Verification & Hallucination Invariant

Financial queries processed through the AI pipeline strictly follow deterministic mathematics:

1. **Domain Isolation:** Neither the LLM nor the regex parser performs mental arithmetic. All totals, percentages, differences, and goal projections are computed strictly inside `FinancialCalculator`.
2. **AIResponseValidator Guarantee:** Every numerical figure emitted in the assistant's final response string is verified against the structured JSON output of the registered tools. If any unsupported number is detected, the validator flags the response to prevent user misinformation.
3. **Integer & Decimal Discipline:** Internal calculations maintain floating-point precision guards, formatting to 2 decimal places with locale-aware currency symbols (`₱`, `$`, `€`).

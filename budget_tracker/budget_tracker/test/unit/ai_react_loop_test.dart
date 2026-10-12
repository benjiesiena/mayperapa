import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/features/ai_assistant/domain/ai_orchestrator.dart';
import 'package:mayperapa/infrastructure/ai/runtime/rule_based_ai_engine.dart';
import 'package:mayperapa/infrastructure/ai/tools/financial_tools_registry.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/domain/entities/recurring_transaction.dart';
import 'package:mayperapa/shared/domain/entities/budget.dart';

import 'financial_tools_registry_test.dart';

void main() {
  group('Autonomous ReAct Cognitive Loop Tests', () {
    test('chains multiple iterations for compound affordability query', () async {
      final txns = [
        Transaction(
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.income,
          amount: 25000,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final recurring = <RecurringTransaction>[
        RecurringTransaction(
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 3500,
          frequency: RecurringFrequency.monthly,
          startDate: DateTime.now(),
          description: 'Electricity & Internet',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final budget = Budget(
        id: 1,
        userId: 1,
        name: 'October Budget',
        type: BudgetType.monthly,
        strategy: BudgetStrategy.zeroBased,
        periodStart: DateTime(2026, 10, 1),
        periodEnd: DateTime(2026, 10, 31),
        totalBudget: 20000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository(txns),
        accountRepository: FakeAccountRepository(),
        budgetRepository: FakeBudgetRepository(active: budget),
        goalRepository: FakeGoalRepository([]),
        recurringRepository: FakeRecurringRepository(recurring),
      );

      final orchestrator = AIOrchestrator(
        engine: RuleBasedAIEngine(),
        toolsRegistry: registry,
      );

      final reply = await orchestrator.sendMessage(
        userMessage: 'Can I afford to spend ₱5,000 on a laptop monitor this week?',
        conversationId: 1,
        history: const [],
      );

      // Verify multiple tools were chained across ReAct iterations:
      // 1. Balance/affordability verification
      // 2. Recurring bills inspection
      expect(reply.toolCallNames, contains('calculate_affordable_spending'));
      expect(reply.toolCallNames, contains('get_current_balance'));
      expect(reply.toolCallNames, contains('get_recurring_expenses'));

      // Verify reasoning steps show multi-phase thinking traces
      expect(reply.reasoningSteps.length, greaterThanOrEqualTo(3));
      final stepTitles = reply.reasoningSteps.map((s) => s.title.toLowerCase()).toList();
      expect(stepTitles.any((t) => t.contains('liquidity') || t.contains('balance')), isTrue);
      expect(stepTitles.any((t) => t.contains('recurring') || t.contains('bill')), isTrue);
      expect(stepTitles.any((t) => t.contains('afford') || t.contains('cashflow')), isTrue);
    });

    test('terminates in 1 iteration for simple queries without unnecessary chaining', () async {
      final txns = [
        Transaction(
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.income,
          amount: 15000,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository(txns),
        accountRepository: FakeAccountRepository(),
        budgetRepository: FakeBudgetRepository(),
        goalRepository: FakeGoalRepository([]),
        recurringRepository: FakeRecurringRepository([]),
      );

      final orchestrator = AIOrchestrator(
        engine: RuleBasedAIEngine(),
        toolsRegistry: registry,
      );

      final reply = await orchestrator.sendMessage(
        userMessage: 'How much money do I have in my wallet?',
        conversationId: 1,
        history: const [],
      );

      // Balance check requires only balance & accounts tools
      expect(reply.toolCallNames, contains('get_current_balance'));
      expect(reply.toolCallNames, contains('get_account_balances'));
      expect(reply.toolCallNames, isNot(contains('simulate_financial_scenario')));
    });

    test('terminates with 0 tools for conversational questions', () async {
      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository([]),
        accountRepository: FakeAccountRepository(),
        budgetRepository: FakeBudgetRepository(),
        goalRepository: FakeGoalRepository([]),
        recurringRepository: FakeRecurringRepository([]),
      );

      final orchestrator = AIOrchestrator(
        engine: RuleBasedAIEngine(),
        toolsRegistry: registry,
      );

      final reply = await orchestrator.sendMessage(
        userMessage: 'What is the 50/30/20 rule?',
        conversationId: 1,
        history: const [],
      );

      expect(reply.toolCallNames, isEmpty);
      expect(reply.content, contains('50/30/20'));
      expect(reply.reasoningSteps, isNotEmpty);
    });
  });
}

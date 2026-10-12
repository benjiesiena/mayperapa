import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/shared/domain/services/financial_calculator.dart';
import 'package:mayperapa/shared/domain/entities/financial_goal.dart';
import 'package:mayperapa/infrastructure/ai/runtime/rule_based_ai_engine.dart';

void main() {
  const calculator = FinancialCalculator();

  group('FinancialCalculator.simulateFinancialScenario', () {
    test('calculates impact of expense cut on goal timeline', () {
      final goal = FinancialGoal(
        id: 1,
        userId: 1,
        name: 'Emergency Fund',
        targetAmount: 50000,
        currentAmount: 20000,
        targetDate: DateTime(2027, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      // Remaining on goal: 30,000
      // Income: 35,000, Expenses: 30,000 -> net savings before: 5,000/mo (6 months)
      // Cut expenses by 2,500 -> new expenses: 27,500 -> net savings after: 7,500/mo (4 months)
      final result = calculator.simulateFinancialScenario(
        currentBalance: 25000,
        monthlyIncome: 35000,
        currentMonthlyExpenses: 30000,
        monthlyExpenseCut: 2500,
        targetGoal: goal,
      );

      expect(result.netMonthlySavingsBefore, equals(5000.0));
      expect(result.netMonthlySavingsAfter, equals(7500.0));
      expect(result.currentMonthsToGoal, equals(6));
      expect(result.simulatedMonthsToGoal, equals(4));
      expect(result.monthsSaved, equals(2));
      expect(result.summary, contains('Emergency Fund'));
      expect(result.summary, contains('2 months sooner'));
    });

    test('evaluates proposed purchase feasibility alongside recurring cut', () {
      final result = calculator.simulateFinancialScenario(
        currentBalance: 10000,
        monthlyIncome: 30000,
        currentMonthlyExpenses: 25000,
        proposedPurchase: 4000,
        cancelledRecurringSavings: 1000,
      );

      expect(result.canAffordPurchase, isTrue);
      expect(result.projectedBalanceAfterPurchase, equals(6000.0));
      expect(result.netMonthlySavingsAfter, equals(6000.0));
      expect(result.summary, contains('4000'));
    });
  });

  group('RuleBasedAIEngine Advanced Colloquial & Scenario Routing', () {
    final engine = RuleBasedAIEngine();

    test('detects colloquial affordability phrasing without explicit "can i afford"', () async {
      final decision = await engine.planToolCalls(
        userMessage: 'Does my wallet have enough room to buy a 3500 headset?',
        availableTools: const [],
        conversationHistory: const [],
      );

      expect(decision.toolNamesToCall, contains('calculate_affordable_spending'));
      final args = decision.toolArgs['calculate_affordable_spending'];
      expect(args?['proposedAmount'], equals(3500.0));
    });

    test('detects colloquial "can my budget take" phrasing', () async {
      final decision = await engine.planToolCalls(
        userMessage: 'Can my budget take a ₱4,500 grocery trip?',
        availableTools: const [],
        conversationHistory: const [],
      );

      expect(decision.toolNamesToCall, contains('calculate_affordable_spending'));
      final args = decision.toolArgs['calculate_affordable_spending'];
      expect(args?['proposedAmount'], equals(4500.0));
    });

    test('routes "what if" hypothetical query to simulate_financial_scenario', () async {
      final decision = await engine.planToolCalls(
        userMessage: 'What if I cut dining out by 2000, how fast will I reach my Emergency Fund goal?',
        availableTools: const [],
        conversationHistory: const [],
      );

      expect(decision.toolNamesToCall, contains('simulate_financial_scenario'));
      expect(decision.toolNamesToCall, contains('get_all_goals'));
    });

    test('routes greeting queries to zero tool calls and returns intro', () async {
      final decision = await engine.planToolCalls(
        userMessage: 'hi',
        availableTools: const [],
        conversationHistory: const [],
      );

      expect(decision.toolNamesToCall, isEmpty);
      final reply = await engine.generateResponse(
        userMessage: 'hi',
        toolResults: const {},
        conversationHistory: const [],
      );
      expect(reply, contains('offline financial assistant'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_deliberation_engine.dart';

void main() {
  group('AIDeliberationEngine Domain Tests (TDD)', () {
    const engine = AIDeliberationEngine();

    test('deliberation directives include all 4 foundational financial axioms', () {
      final directives = engine.getDeliberationDirectives();

      expect(directives, isNotEmpty);
      expect(directives, contains('LIQUIDITY DEFENSE FIRST'));
      expect(directives, contains('GUARANTEED RETURN PRIORITY'));
      expect(directives, contains('SACRIFICE HIERARCHY'));
      expect(directives, contains('TAKE AN OPINIONATED STANCE'));
    });

    test('golden exemplars provide curated high-conviction decision scenarios', () {
      final exemplars = engine.getGoldenExemplars();

      expect(exemplars.length, greaterThanOrEqualTo(3));

      // Exemplar 1: Fixed cost shock (Rent increase)
      final rentExemplar = exemplars.firstWhere((e) => e.title.contains('Fixed Cost Shock'));
      expect(rentExemplar.userPrompt, contains('rent'));
      expect(rentExemplar.deliberationSteps, isNotEmpty);
      expect(rentExemplar.mayaVerdict, contains('recommendation'));

      // Exemplar 2: High interest debt vs savings
      final debtExemplar = exemplars.firstWhere((e) => e.title.contains('Debt vs Savings'));
      expect(debtExemplar.userPrompt, contains('credit card'));
      expect(debtExemplar.mayaVerdict, contains('Guaranteed return'));

      // Exemplar 3: Splurge vs Goal Runway
      final splurgeExemplar = exemplars.firstWhere((e) => e.title.contains('Discretionary Splurge'));
      expect(splurgeExemplar.userPrompt, contains('buy'));
    });

    test('evaluateDebtVsSavingsPriority recommends debt payoff when APR exceeds yield', () {
      final evaluation = engine.evaluateDebtVsSavingsPriority(
        debtAmount: 15000,
        debtAprPercent: 36.0,
        savingsBalance: 25000,
        savingsYieldPercent: 4.0,
        monthlyEssentialExpenses: 12000,
      );

      expect(evaluation.recommendation, DeliberationRecommendation.payOffDebtFirst);
      expect(evaluation.primaryRationale, contains('36.0%'));
      expect(evaluation.isEmergencyBufferSafeAfterPayoff, isFalse); // 25000 - 15000 = 10000 < 12000
      expect(evaluation.suggestedStrategy, contains('staged payoff'));
    });

    test('evaluateDebtVsSavingsPriority recommends payoff immediately when buffer remains intact', () {
      final evaluation = engine.evaluateDebtVsSavingsPriority(
        debtAmount: 10000,
        debtAprPercent: 24.0,
        savingsBalance: 35000,
        savingsYieldPercent: 4.0,
        monthlyEssentialExpenses: 12000,
      );

      expect(evaluation.recommendation, DeliberationRecommendation.payOffDebtFirst);
      expect(evaluation.isEmergencyBufferSafeAfterPayoff, isTrue); // 35000 - 10000 = 25000 >= 12000
      expect(evaluation.suggestedStrategy, contains('lump-sum'));
    });

    test('rankSacrificeCategories orders discretionary categories before essential ones', () {
      final categories = [
        'Bills & Utilities',
        'Dining Out',
        'Groceries',
        'Shopping',
        'Healthcare',
        'Entertainment',
      ];

      final ranked = engine.rankSacrificeCandidates(categories);

      // Top sacrifice candidates must be discretionary
      expect(ranked.take(3), containsAll(['Dining Out', 'Shopping', 'Entertainment']));
      // Bottom sacrifice candidates must be essential
      expect(ranked.skip(3), containsAll(['Bills & Utilities', 'Groceries', 'Healthcare']));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_draft.dart';
import 'package:mayperapa/features/ai_assistant/domain/scenario_comparison_matrix.dart';

void main() {
  group('ScenarioComparisonMatrix Domain Tests (TDD)', () {
    test('computes comparison matrix between current, rebalanced, and aggressive paths', () {
      final now = DateTime.now();
      final matrix = ScenarioComparisonMatrix(
        title: 'Fixed Cost Rebalancing Scenarios',
        aiVerdictSummary: 'Rebalancing discretionary spending achieves the optimal balance of safety and goal velocity.',
        scenarios: [
          const FinancialScenarioOption(
            id: 'current_pace',
            title: 'Current Pace',
            badge: 'Status Quo',
            discretionarySpend: 8500,
            monthlySavings: 1500,
            emergencyRunwayMonths: 1.8,
            goalTargetMonths: 24,
            isRecommended: false,
          ),
          FinancialScenarioOption(
            id: 'auto_rebalanced',
            title: 'Auto-Rebalanced',
            badge: 'Maya Recommendation',
            discretionarySpend: 6000,
            monthlySavings: 4000,
            emergencyRunwayMonths: 3.2,
            goalTargetMonths: 14,
            isRecommended: true,
            actionDraft: AIActionDraft(
              id: 'draft_rebalance',
              type: AIActionType.createBudget,
              title: 'Apply Rebalanced Budget',
              subtitle: 'Reallocate ₱2,500 from dining to emergency buffer',
              payload: const {'rebalance': true},
              createdAt: now,
            ),
          ),
          const FinancialScenarioOption(
            id: 'aggressive_saver',
            title: 'Aggressive Saver',
            badge: 'Maximum Velocity',
            discretionarySpend: 3500,
            monthlySavings: 6500,
            emergencyRunwayMonths: 5.0,
            goalTargetMonths: 9,
            isRecommended: false,
          ),
        ],
      );

      expect(matrix.scenarios.length, equals(3));
      expect(matrix.recommendedScenario.id, equals('auto_rebalanced'));
      expect(matrix.recommendedScenario.emergencyRunwayMonths, equals(3.2));
      expect(matrix.recommendedScenario.actionDraft, isNotNull);
      expect(matrix.scenarios.first.isRecommended, isFalse);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_draft.dart';
import 'package:mayperapa/features/ai_assistant/domain/scenario_comparison_matrix.dart';
import 'package:mayperapa/features/ai_assistant/presentation/widgets/scenario_comparison_grid_card.dart';

void main() {
  group('ScenarioComparisonGridCard Widget Tests (TDD)', () {
    final testMatrix = ScenarioComparisonMatrix(
      title: 'Emergency Buffer vs Debt Scenarios',
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
          badge: 'Maya Pick',
          discretionarySpend: 6000,
          monthlySavings: 4000,
          emergencyRunwayMonths: 3.2,
          goalTargetMonths: 14,
          isRecommended: true,
          actionDraft: AIActionDraft(
            id: 'draft_1',
            type: AIActionType.createBudget,
            title: 'Auto-Pilot Budget Rebalance',
            subtitle: 'Reallocate ₱2,500 from dining to emergency fund',
            payload: const {'rebalance': true},
            createdAt: DateTime.now(),
          ),
        ),
        const FinancialScenarioOption(
          id: 'aggressive_saver',
          title: 'Aggressive Saver',
          badge: 'Max Velocity',
          discretionarySpend: 3500,
          monthlySavings: 6500,
          emergencyRunwayMonths: 5.0,
          goalTargetMonths: 9,
          isRecommended: false,
        ),
      ],
    );

    testWidgets('renders matrix title, verdict, and all 3 scenario columns', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScenarioComparisonGridCard(
                matrix: testMatrix,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Emergency Buffer vs Debt Scenarios'), findsOneWidget);
      expect(find.textContaining('Maya Verdict:'), findsOneWidget);
      expect(find.text('Current Pace'), findsOneWidget);
      expect(find.text('Auto-Rebalanced'), findsOneWidget);
      expect(find.text('Aggressive Saver'), findsOneWidget);
      expect(find.text('Maya Pick'), findsOneWidget);
    });

    testWidgets('triggers callback when a scenario option is selected', (tester) async {
      FinancialScenarioOption? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScenarioComparisonGridCard(
                matrix: testMatrix,
                onSelectScenario: (option) => selectedOption = option,
              ),
            ),
          ),
        ),
      );

      // Find the action button on the recommended scenario
      final applyButton = find.widgetWithText(ElevatedButton, 'Apply Plan').first;
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      expect(selectedOption, isNotNull);
      expect(selectedOption!.id, equals('auto_rebalanced'));
      expect(selectedOption!.isRecommended, isTrue);
    });
  });
}

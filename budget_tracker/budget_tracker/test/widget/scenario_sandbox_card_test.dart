import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_message.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_scenario_sandbox.dart';
import 'package:mayperapa/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';
import 'package:mayperapa/features/ai_assistant/presentation/widgets/scenario_sandbox_card.dart';

void main() {
  group('ScenarioSandboxCard Widget Tests', () {
    testWidgets('renders what-if sandbox card with category, initial cut, and timeline metrics',
        (WidgetTester tester) async {
      double? appliedCut;

      const sandbox = AIScenarioSandbox(
        id: 'sandbox_test_1',
        categoryName: 'Dining Out',
        currentMonthlySpending: 6000,
        baselineCutAmount: 1500,
        minCutAmount: 300,
        maxCutAmount: 4500,
        goalTargetAmount: 60000,
        goalCurrentAmount: 20000,
        goalName: 'Emergency Fund',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: ScenarioSandboxCard(
              sandbox: sandbox,
              onApplyCut: (cut) => appliedCut = cut,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('WHAT-IF SCENARIO SANDBOX'), findsOneWidget);
      expect(find.text('Dining Out'), findsOneWidget);

      // Verify Baseline Values
      expect(find.text('-₱1,500.00 / mo'), findsOneWidget);
      expect(find.text('Annual Wealth Boost:'), findsOneWidget);
      expect(find.text('+₱18,000.00 / year'), findsOneWidget);
      expect(find.text('Emergency Fund Timeline:'), findsOneWidget);

      // Verify Slider exists
      expect(find.byType(Slider), findsOneWidget);

      // Verify Apply Cut button
      expect(find.text('Apply ₱1,500.00 Monthly Cut'), findsOneWidget);

      // Tap Apply Cut
      await tester.tap(find.text('Apply ₱1,500.00 Monthly Cut'));
      await tester.pump();
      expect(appliedCut, 1500.0);
    });

    testWidgets('dragging slider updates monthly cut and re-calculates annual wealth boost',
        (WidgetTester tester) async {
      const sandbox = AIScenarioSandbox(
        id: 'sandbox_test_2',
        categoryName: 'Food & Dining',
        currentMonthlySpending: 5000,
        baselineCutAmount: 1000,
        minCutAmount: 0,
        maxCutAmount: 5000,
        goalTargetAmount: 50000,
        goalCurrentAmount: 10000,
        goalName: 'Vacation Trip',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: ScenarioSandboxCard(
              sandbox: sandbox,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('-₱1,000.00 / mo'), findsOneWidget);

      // Drag the slider to the right
      final sliderFinder = find.byType(Slider);
      await tester.drag(sliderFinder, const Offset(120, 0));
      await tester.pumpAndSettle();

      // Monthly cut value should have changed from baseline 1000
      expect(find.text('-₱1,000.00 / mo'), findsNothing);
    });

    testWidgets('AIMessageBubble embeds ScenarioSandboxCard when scenarioSandbox is present',
        (WidgetTester tester) async {
      const sandbox = AIScenarioSandbox(
        id: 'sandbox_test_3',
        categoryName: 'Entertainment',
        currentMonthlySpending: 4000,
        baselineCutAmount: 1000,
        minCutAmount: 200,
        maxCutAmount: 3000,
        goalTargetAmount: 30000,
        goalCurrentAmount: 10000,
        goalName: 'Laptop Fund',
      );

      final message = AIMessage(
        conversationId: 1,
        role: AIMessageRole.assistant,
        content: 'Here is what happens if you adjust your entertainment spending:',
        scenarioSandbox: sandbox,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: AIMessageBubble(message: message),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify both message text and sandbox card are rendered
      expect(
        find.text('Here is what happens if you adjust your entertainment spending:'),
        findsOneWidget,
      );
      expect(find.text('WHAT-IF SCENARIO SANDBOX'), findsOneWidget);
      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.byType(ScenarioSandboxCard), findsOneWidget);
    });
  });
}

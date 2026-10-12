import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_reasoning_step.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_message.dart';
import 'package:mayperapa/features/ai_assistant/presentation/widgets/thinking_process_card.dart';
import 'package:mayperapa/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';

void main() {
  group('ThinkingProcessCard Widget Tests', () {
    testWidgets('renders collapsed thinking header and expands on tap', (WidgetTester tester) async {
      final steps = [
        AIReasoningStep(
          title: 'Auditing available liquidity',
          detail: 'Verified total balance across active accounts.',
          type: AIReasoningStepType.inspect,
          timestamp: DateTime.now(),
          durationMs: 35,
        ),
        AIReasoningStep(
          title: 'Evaluating purchase affordability & cashflow impact',
          detail: 'Purchase fits within safe liquidity buffer.',
          type: AIReasoningStepType.calculate,
          timestamp: DateTime.now(),
          durationMs: 50,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: ThinkingProcessCard(
              steps: steps,
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify collapsed header elements
      expect(find.text('Thought for 0.3s'), findsOneWidget);
      expect(find.text('2 checks'), findsOneWidget);

      // Verify details are not yet visible while collapsed
      expect(find.text('Auditing available liquidity'), findsNothing);

      // Tap header to expand
      await tester.tap(find.text('Thought for 0.3s'));
      await tester.pumpAndSettle();

      // Verify step details are now visible
      expect(find.text('Auditing available liquidity'), findsOneWidget);
      expect(find.text('Verified total balance across active accounts.'), findsOneWidget);
      expect(find.text('Evaluating purchase affordability & cashflow impact'), findsOneWidget);
      expect(find.text('35ms'), findsOneWidget);
      expect(find.text('50ms'), findsOneWidget);

      // Tap header again to collapse
      await tester.tap(find.text('Thought for 0.3s'));
      await tester.pumpAndSettle();

      expect(find.text('Auditing available liquidity'), findsNothing);
    });

    testWidgets('AIMessageBubble embeds ThinkingProcessCard for assistant messages with reasoning steps',
        (WidgetTester tester) async {
      final message = AIMessage(
        conversationId: 1,
        role: AIMessageRole.assistant,
        content: 'Yes, that fits in your budget comfortably.',
        createdAt: DateTime.now(),
        reasoningSteps: [
          AIReasoningStep(
            title: 'Verifying active budget caps & remaining headroom',
            type: AIReasoningStepType.calculate,
            timestamp: DateTime.now(),
          ),
        ],
        thinkingDuration: const Duration(milliseconds: 180),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: AIMessageBubble(message: message),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thought for 0.2s'), findsOneWidget);
      expect(find.text('1 checks'), findsOneWidget);
      expect(find.text('Yes, that fits in your budget comfortably.'), findsOneWidget);
    });

    testWidgets('renders verified sources chips when toolCallNames are provided and expanded',
        (WidgetTester tester) async {
      final steps = [
        AIReasoningStep(
          title: 'Auditing available liquidity',
          detail: 'Verified total balance across active accounts.',
          type: AIReasoningStepType.inspect,
          timestamp: DateTime.now(),
          durationMs: 35,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: ThinkingProcessCard(
              steps: steps,
              duration: const Duration(milliseconds: 300),
              toolCallNames: const ['get_current_balance', 'calculate_affordable_spending'],
              initialExpanded: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VERIFIED SOURCES'), findsOneWidget);
      expect(find.text('Liquidity Audited'), findsOneWidget);
      expect(find.text('Affordability Model'), findsOneWidget);
    });
  });
}

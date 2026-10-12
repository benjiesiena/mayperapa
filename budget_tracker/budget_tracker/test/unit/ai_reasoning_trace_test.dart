import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/features/ai_assistant/domain/ai_message.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_orchestrator.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_reasoning_step.dart';
import 'package:mayperapa/infrastructure/ai/runtime/rule_based_ai_engine.dart';
import 'package:mayperapa/infrastructure/ai/tools/financial_tools_registry.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';

import 'financial_tools_registry_test.dart';

void main() {
  group('Chain-of-Thought & Reasoning Trace Tests', () {
    test('AIReasoningStep models individual reasoning checkpoints with metadata', () {
      final step = AIReasoningStep(
        title: 'Inspecting available liquidity',
        detail: 'Found ₱15,000 across 2 accounts',
        type: AIReasoningStepType.inspect,
        timestamp: DateTime.now(),
        durationMs: 45,
      );

      expect(step.title, 'Inspecting available liquidity');
      expect(step.detail, contains('15,000'));
      expect(step.type, AIReasoningStepType.inspect);
      expect(step.durationMs, 45);
      expect(step.isCompleted, isTrue);
    });

    test('AIMessage holds reasoning steps and total thinking duration', () {
      final now = DateTime.now();
      final steps = [
        AIReasoningStep(
          title: 'Reviewing budget constraints',
          type: AIReasoningStepType.calculate,
          timestamp: now,
        ),
        AIReasoningStep(
          title: 'Synthesizing recommendation',
          type: AIReasoningStepType.synthesize,
          timestamp: now.add(const Duration(milliseconds: 50)),
        ),
      ];

      final message = AIMessage(
        conversationId: 1,
        role: AIMessageRole.assistant,
        content: 'Your balance looks healthy!',
        createdAt: now,
        reasoningSteps: steps,
        thinkingDuration: const Duration(milliseconds: 150),
      );

      expect(message.reasoningSteps.length, 2);
      expect(message.thinkingDuration?.inMilliseconds, 150);
      expect(message.reasoningSteps.first.title, 'Reviewing budget constraints');
    });

    test('AIOrchestrator generates visible reasoning trace during financial analysis', () async {
      final txns = [
        Transaction(
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.income,
          amount: 20000,
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
        userMessage: 'Can I afford to spend ₱3,000 this weekend?',
        conversationId: 1,
        history: const [],
      );

      expect(reply.reasoningSteps, isNotEmpty);
      expect(reply.thinkingDuration, isNotNull);

      // Verify reasoning steps cover planning, tool execution, and synthesis
      final stepTitles = reply.reasoningSteps.map((s) => s.title.toLowerCase()).toList();
      expect(stepTitles.any((t) => t.contains('evaluat') || t.contains('plan') || t.contains('afford')), isTrue);
      expect(stepTitles.any((t) => t.contains('synthesiz') || t.contains('conclus') || t.contains('recommend')), isTrue);
    });
  });
}

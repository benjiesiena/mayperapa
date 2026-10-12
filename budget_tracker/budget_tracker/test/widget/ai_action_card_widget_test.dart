import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_draft.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_executor.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_message.dart';
import 'package:mayperapa/features/ai_assistant/presentation/providers/ai_chat_provider.dart';
import 'package:mayperapa/features/ai_assistant/presentation/widgets/ai_action_card.dart';
import 'package:mayperapa/features/ai_assistant/presentation/widgets/ai_message_bubble.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';

void main() {
  group('AIActionCard Widget Tests', () {
    testWidgets('renders transaction action card with pending status and invokes callbacks',
        (WidgetTester tester) async {
      bool confirmed = false;
      bool cancelled = false;

      final draft = AIActionDraft(
        id: 'draft-txn-1',
        type: AIActionType.createTransaction,
        title: 'Add Expense: ₱150.00',
        subtitle: 'Food · Cash · coffee',
        payload: const {
          'amount': 150.0,
          'type': 'expense',
          'categoryName': 'Food',
          'accountName': 'Cash',
          'description': 'coffee',
        },
        status: AIActionStatus.pending,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: AIActionCard(
              draft: draft,
              onConfirm: () => confirmed = true,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and badges
      expect(find.text('EXPENSE DRAFT'), findsOneWidget);
      expect(find.text('Requires Confirmation'), findsOneWidget);

      // Verify title and subtitle
      expect(find.text('Add Expense: ₱150.00'), findsOneWidget);
      expect(find.text('Food · Cash · coffee'), findsOneWidget);

      // Verify metadata chips
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('coffee'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Confirm & Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Confirm
      await tester.tap(find.text('Confirm & Save'));
      await tester.pump();
      expect(confirmed, isTrue);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(cancelled, isTrue);
    });

    testWidgets('renders 50/30/20 plan card with segmented allocations',
        (WidgetTester tester) async {
      final draft = AIActionDraft(
        id: 'draft-plan-1',
        type: AIActionType.applyFinancialPlan,
        title: 'Apply 50/30/20 Plan for ₱30,000.00',
        subtitle: 'Needs: ₱15,000 | Wants: ₱9,000 | Savings: ₱6,000',
        payload: const {
          'salary': 30000.0,
          'needsBudget': 15000.0,
          'wantsBudget': 9000.0,
          'savingsGoal': 6000.0,
        },
        status: AIActionStatus.pending,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: AIActionCard(
              draft: draft,
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('50/30/20 PLAN'), findsOneWidget);
      expect(find.text('Monthly Salary: ₱30,000.00'), findsOneWidget);
      expect(find.text('Needs (50%)'), findsOneWidget);
      expect(find.text('Wants (30%)'), findsOneWidget);
      expect(find.text('Savings (20%)'), findsOneWidget);
      expect(find.text('Apply Plan'), findsOneWidget);
    });

    testWidgets('renders executed state with success badge and message banner',
        (WidgetTester tester) async {
      final draft = AIActionDraft(
        id: 'draft-executed-1',
        type: AIActionType.createTransaction,
        title: 'Add Expense: ₱150.00',
        subtitle: 'Food · Cash · coffee',
        payload: const {
          'amount': 150.0,
          'type': 'expense',
          'categoryName': 'Food',
          'accountName': 'Cash',
        },
        status: AIActionStatus.executed,
        executionResult: 'Saved ₱150.00 expense in Food (Cash).',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: AIActionCard(
              draft: draft,
              onConfirm: () {},
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check badges and banner
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Saved ₱150.00 expense in Food (Cash).'), findsOneWidget);

      // Action buttons should no longer appear
      expect(find.text('Confirm & Save'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('renders batch bundle card with step checklist and confirms all',
        (WidgetTester tester) async {
      bool confirmed = false;

      final bundleDraft = AIActionDraft(
        id: 'draft-bundle-1',
        type: AIActionType.batchBundle,
        title: '50/30/20 Complete Salary Setup',
        subtitle: 'Executes 3 budgets & 1 savings goal atomically',
        payload: const {
          'actions': [
            {
              'type': 'createBudget',
              'title': 'Needs Budget (50%)',
              'subtitle': 'Bills & Utilities • ₱15,000.00',
            },
            {
              'type': 'createBudget',
              'title': 'Wants Budget (30%)',
              'subtitle': 'Shopping • ₱9,000.00',
            },
            {
              'type': 'createGoal',
              'title': 'Emergency Fund (20%)',
              'subtitle': 'Monthly target: ₱6,000.00',
            },
          ],
        },
        status: AIActionStatus.pending,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: AIActionCard(
              draft: bundleDraft,
              onConfirm: () => confirmed = true,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('ACTION BUNDLE'), findsOneWidget);
      expect(find.text('50/30/20 Complete Salary Setup'), findsOneWidget);

      // Verify Sub-action Checklist Steps
      expect(find.text('Needs Budget (50%)'), findsOneWidget);
      expect(find.text('Bills & Utilities • ₱15,000.00'), findsOneWidget);
      expect(find.text('Wants Budget (30%)'), findsOneWidget);
      expect(find.text('Shopping • ₱9,000.00'), findsOneWidget);
      expect(find.text('Emergency Fund (20%)'), findsOneWidget);
      expect(find.text('Monthly target: ₱6,000.00'), findsOneWidget);

      // Verify Step Number Badges
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Verify Bundle Button Text
      expect(find.text('Confirm All (3 Actions)'), findsOneWidget);

      // Tap Confirm All
      await tester.tap(find.text('Confirm All (3 Actions)'));
      await tester.pump();
      expect(confirmed, isTrue);
    });

    testWidgets('AIMessageBubble integrates with aiChatProvider to confirm action',
        (WidgetTester tester) async {
      final draft = AIActionDraft(
        id: 'draft-confirm-1',
        type: AIActionType.createTransaction,
        title: 'Add Expense: ₱150.00',
        subtitle: 'Food · Cash · coffee',
        payload: const {
          'amount': 150.0,
          'type': 'expense',
          'categoryName': 'Food',
          'accountName': 'Cash',
          'description': 'coffee',
        },
        status: AIActionStatus.pending,
        createdAt: DateTime.now(),
      );

      final message = AIMessage(
        conversationId: 1,
        role: AIMessageRole.assistant,
        content: 'I have prepared this transaction for you:',
        actionDraft: draft,
        createdAt: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          aiActionExecutorProvider.overrideWithValue(
            _FakeActionExecutor(
              const AIActionExecutionResult(
                success: true,
                message: 'Saved ₱150.00 expense in Food (Cash).',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Preload the chat state with the message
      container.read(aiChatProvider.notifier).state = AIChatState(messages: [message]);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.dark(),
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final chatState = ref.watch(aiChatProvider);
                  return ListView(
                    children: chatState.messages.map((m) => AIMessageBubble(message: m)).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Card is initially pending
      expect(find.text('Requires Confirmation'), findsOneWidget);
      expect(find.text('Confirm & Save'), findsOneWidget);

      // Tap Confirm & Save
      await tester.tap(find.text('Confirm & Save'));
      await tester.pumpAndSettle();

      // Card should now be executed
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('✓ Saved ₱150.00 expense in Food (Cash).'), findsOneWidget);
    });
  });
}

class _FakeActionExecutor implements AIActionExecutor {
  final AIActionExecutionResult result;
  _FakeActionExecutor(this.result);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #execute) {
      return Future.value(result);
    }
    return super.noSuchMethod(invocation);
  }
}


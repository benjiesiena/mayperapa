import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/ai_assistant/domain/maya_copilot_service.dart';
import 'package:mayperapa/features/home/presentation/widgets/maya_briefing_card.dart';
import 'package:mayperapa/features/transactions/presentation/widgets/inline_budget_coaching_pill.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/recurring_transaction.dart';
import 'package:mayperapa/shared/presentation/widgets/maya_floating_capsule.dart';

void main() {
  group('Maya Ambient Intelligence & Copilot Widget Tests', () {
    testWidgets('MayaBriefingCard renders daily allowance, upcoming bills, and invokes callback',
        (WidgetTester tester) async {
      bool tapped = false;

      final upcoming = [
        RecurringTransaction(
          id: 1,
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 1899,
          description: 'Globe Fiber Internet',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2026, 1, 1),
          nextDueDate: DateTime.now().add(const Duration(hours: 24)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: MayaBriefingCard(
              dailyAllowance: 1250,
              daysRemainingInMonth: 12,
              remainingBudget: 15000,
              upcomingBills: upcoming,
              onAskMaya: () => tapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MAYA INTELLIGENCE BRIEFING'), findsOneWidget);
      expect(find.text('₱1,250.00'), findsOneWidget);
      expect(find.text('/ day safe allowance'), findsOneWidget);
      expect(find.text('12 days left'), findsOneWidget);
      expect(find.textContaining('Globe Fiber Internet'), findsOneWidget);

      await tester.tap(find.text("Ask Maya about today's pacing"));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('InlineBudgetCoachingPill displays contextual coaching and reacts to budget overrun',
        (WidgetTester tester) async {
      // 1. Safe purchase
      const safeImpact = BudgetImpactResult(
        isExceeded: false,
        remainingAfter: 1200,
        message: '₱800.00 on Food leaves ₱1,200.00 in your budget.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: InlineBudgetCoachingPill(
              impact: safeImpact,
              isVisible: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₱800.00 on Food leaves ₱1,200.00 in your budget.'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      // 2. Budget overrun purchase
      const overImpact = BudgetImpactResult(
        isExceeded: true,
        remainingAfter: -500,
        message: 'Exceeds Food budget by ₱500.00.',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: InlineBudgetCoachingPill(
              impact: overImpact,
              isVisible: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exceeds Food budget by ₱500.00.'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // 3. Hidden pill
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: const Scaffold(
            body: InlineBudgetCoachingPill(
              impact: safeImpact,
              isVisible: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('₱800.00 on Food leaves ₱1,200.00 in your budget.'), findsNothing);
    });

    testWidgets('MayaFloatingCapsule renders and triggers callback', (WidgetTester tester) async {
      bool invoked = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: MayaFloatingCapsule(
              onTap: () => invoked = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ask Maya'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);

      await tester.tap(find.text('Ask Maya'));
      await tester.pumpAndSettle();
      expect(invoked, isTrue);
    });
  });
}

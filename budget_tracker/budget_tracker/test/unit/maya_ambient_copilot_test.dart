import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/features/ai_assistant/domain/maya_copilot_service.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/recurring_transaction.dart';
import 'package:mayperapa/features/budgets/presentation/providers/budgets_provider.dart';
import 'package:mayperapa/shared/domain/entities/budget.dart';

void main() {
  group('Maya Ambient Copilot Domain Tests', () {
    test('calculates daily spending allowance based on days remaining in month', () {
      // ₱15,000 remaining with 10 days left -> ₱1,500/day
      final allowance = MayaCopilotService.calculateDailyAllowance(
        remainingBudget: 15000,
        daysRemainingInMonth: 10,
      );
      expect(allowance, 1500.0);

      // Edge case: 0 or negative days clamped to 1
      final singleDayAllowance = MayaCopilotService.calculateDailyAllowance(
        remainingBudget: 3000,
        daysRemainingInMonth: 0,
      );
      expect(singleDayAllowance, 3000.0);

      // Negative remaining budget returns 0 allowance
      final zeroAllowance = MayaCopilotService.calculateDailyAllowance(
        remainingBudget: -500,
        daysRemainingInMonth: 5,
      );
      expect(zeroAllowance, 0.0);
    });

    test('detects recurring bills due within the next 72 hours', () {
      final now = DateTime(2026, 10, 10, 10, 0);

      final bills = [
        RecurringTransaction(
          id: 1,
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 2500,
          description: 'Internet Bill',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2026, 1, 10),
          nextDueDate: DateTime(2026, 10, 11, 12, 0), // within 26 hours -> DUE
          createdAt: now,
          updatedAt: now,
        ),
        RecurringTransaction(
          id: 2,
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 500,
          description: 'Gym Membership',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2026, 1, 10),
          nextDueDate: DateTime(2026, 10, 25), // 15 days out -> NOT DUE
          createdAt: now,
          updatedAt: now,
        ),
        RecurringTransaction(
          id: 3,
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.income, // Income -> ignored for bills due
          amount: 30000,
          description: 'Salary',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2026, 1, 15),
          nextDueDate: DateTime(2026, 10, 12),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final dueBills = MayaCopilotService.findBillsDueWithin(
        recurringTransactions: bills,
        now: now,
        window: const Duration(hours: 72),
      );

      expect(dueBills.length, 1);
      expect(dueBills.first.description, 'Internet Bill');
      expect(dueBills.first.amount, 2500);
    });

    test('evaluates real-time transaction budget impact with remaining headroom', () {
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

      final items = [
        BudgetItem(
          id: 1,
          budgetId: 1,
          categoryId: 5, // Food
          amount: 6000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final budgetState = ActiveBudgetState(
        budget: budget,
        items: items,
        spent: 8000,
        remaining: 12000,
        percentUsed: 40.0,
      );

      // Case A: ₱1,500 on Food when ₱3,000 was already spent (leaving ₱1,500)
      final impact = MayaCopilotService.evaluateTransactionBudgetImpact(
        budgetState: budgetState,
        categoryId: 5,
        categoryName: 'Food',
        categorySpent: 3000,
        proposedAmount: 1500,
      );

      expect(impact.isExceeded, isFalse);
      expect(impact.remainingAfter, 1500.0);
      expect(impact.message, contains('₱1,500'));
      expect(impact.message, contains('leaves ₱1,500.00'));

      // Case B: ₱4,000 on Food when ₱3,000 was already spent (allocated: ₱6,000 -> exceeds by ₱1,000)
      final overImpact = MayaCopilotService.evaluateTransactionBudgetImpact(
        budgetState: budgetState,
        categoryId: 5,
        categoryName: 'Food',
        categorySpent: 3000,
        proposedAmount: 4000,
      );

      expect(overImpact.isExceeded, isTrue);
      expect(overImpact.remainingAfter, -1000.0);
      expect(overImpact.message, contains('Exceeds Food budget by ₱1,000.00'));
    });
  });
}

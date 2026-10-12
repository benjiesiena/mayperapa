import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/features/notifications/domain/entities/scheduled_alert.dart';
import 'package:mayperapa/features/notifications/domain/services/budget_alert_evaluator.dart';
import 'package:mayperapa/shared/domain/entities/budget.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/financial_goal.dart';
import 'package:mayperapa/shared/domain/entities/recurring_transaction.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';

void main() {
  const evaluator = BudgetAlertEvaluator();
  final now = DateTime(2026, 10, 15, 12, 0);

  Budget makeBudget({required int id, required String name, required double totalBudget}) {
    return Budget(
      id: id,
      userId: 1,
      name: name,
      type: BudgetType.monthly,
      strategy: BudgetStrategy.zeroBased,
      totalBudget: totalBudget,
      periodStart: DateTime(2026, 10, 1),
      periodEnd: DateTime(2026, 10, 31),
      createdAt: now,
      updatedAt: now,
    );
  }

  Transaction makeTxn({required double amount, required DateTime date}) {
    return Transaction(
      id: 1,
      userId: 1,
      accountId: 1,
      categoryId: 1,
      type: TransactionType.expense,
      amount: amount,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('BudgetAlertEvaluator Tests', () {
    test('does not trigger alert when spending is under 85%', () {
      final budgets = [makeBudget(id: 1, name: 'Food', totalBudget: 10000)];
      final txns = [makeTxn(amount: 8000, date: now)]; // 80%

      final alerts = evaluator.evaluateBudgetThresholds(budgets: budgets, transactions: txns, referenceDate: now);
      expect(alerts.isEmpty, true);
    });

    test('triggers 85% warning alert when spending is between 85% and 99%', () {
      final budgets = [makeBudget(id: 1, name: 'Food', totalBudget: 10000)];
      final txns = [makeTxn(amount: 8700, date: now)]; // 87%

      final alerts = evaluator.evaluateBudgetThresholds(budgets: budgets, transactions: txns, referenceDate: now);
      expect(alerts.length, 1);
      expect(alerts.first.triggerType, AlertTriggerType.budgetThreshold85);
      expect(alerts.first.title, contains('Budget Warning'));
      expect(alerts.first.body, contains('87%'));
    });

    test('triggers budget exceeded alert when spending is >= 100%', () {
      final budgets = [makeBudget(id: 1, name: 'Food', totalBudget: 10000)];
      final txns = [makeTxn(amount: 11500, date: now)]; // 115%

      final alerts = evaluator.evaluateBudgetThresholds(budgets: budgets, transactions: txns, referenceDate: now);
      expect(alerts.length, 1);
      expect(alerts.first.title, contains('Budget Exceeded'));
      expect(alerts.first.body, contains('exceeded'));
    });

    test('evaluates upcoming bills at 48h and 24h horizons', () {
      final bills = [
        RecurringTransaction(
          id: 1,
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 1500,
          description: 'Internet Bill',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          nextDueDate: now.add(const Duration(hours: 18)), // due in 18h (< 24h)
          createdAt: now,
          updatedAt: now,
        ),
        RecurringTransaction(
          id: 2,
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 2500,
          description: 'Electricity Bill',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          nextDueDate: now.add(const Duration(hours: 40)), // due in 40h (24-48h)
          createdAt: now,
          updatedAt: now,
        ),
        RecurringTransaction(
          id: 3,
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 500,
          description: 'Gym Membership',
          frequency: RecurringFrequency.monthly,
          startDate: DateTime(2026, 9, 1),
          nextDueDate: now.add(const Duration(days: 10)), // far out
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final alerts = evaluator.evaluateUpcomingBills(recurringBills: bills, referenceDate: now);
      expect(alerts.length, 2);
      expect(alerts.any((a) => a.title.contains('Internet Bill') && a.title.contains('Tomorrow')), true);
      expect(alerts.any((a) => a.title.contains('Electricity Bill') && a.body.contains('2 days')), true);
    });

    test('evaluates financial goal milestones', () {
      final goals = [
        FinancialGoal(
          id: 1,
          userId: 1,
          name: 'Emergency Fund',
          targetAmount: 50000,
          currentAmount: 50000, // 100%
          targetDate: DateTime(2026, 12, 31),
          createdAt: now,
          updatedAt: now,
        ),
        FinancialGoal(
          id: 2,
          userId: 1,
          name: 'Japan Trip',
          targetAmount: 100000,
          currentAmount: 51000, // 51% (halfway)
          targetDate: DateTime(2027, 4, 30),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final alerts = evaluator.evaluateGoalMilestones(goals: goals, referenceDate: now);
      expect(alerts.length, 2);
      expect(alerts.first.title, contains('Goal Achieved: Emergency Fund'));
      expect(alerts.last.title, contains('Halfway Milestone: Japan Trip'));
    });
  });
}

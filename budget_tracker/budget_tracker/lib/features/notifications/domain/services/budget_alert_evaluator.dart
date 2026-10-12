import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/domain/entities/budget.dart';
import '../../../../shared/domain/entities/enums.dart';
import '../../../../shared/domain/entities/financial_goal.dart';
import '../../../../shared/domain/entities/recurring_transaction.dart';
import '../../../../shared/domain/entities/transaction.dart';
import '../entities/scheduled_alert.dart';

/// Pure domain evaluation engine detecting financial thresholds,
/// bill due dates, and milestone achievements. Free of device I/O.
class BudgetAlertEvaluator {
  const BudgetAlertEvaluator();

  /// Evaluates monthly category spending against budget allocations and returns
  /// alerts for categories at or above 85% usage.
  List<ScheduledAlert> evaluateBudgetThresholds({
    required List<Budget> budgets,
    required List<Transaction> transactions,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final alerts = <ScheduledAlert>[];

    for (final budget in budgets) {
      if (!budget.isActive) continue;

      // Sum expenses within the current month
      final currentMonthExpenses = transactions
          .where((t) => t.type == TransactionType.expense)
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalLimit = budget.totalBudget;
      if (totalLimit <= 0) continue;

      final ratio = currentMonthExpenses / totalLimit;

      if (ratio >= 1.0) {
        final overspent = currentMonthExpenses - totalLimit;
        alerts.add(
          ScheduledAlert(
            id: budget.id ?? 100,
            title: 'Budget Exceeded: ${budget.name}',
            body: 'You have exceeded your ${CurrencyFormatter.format(totalLimit)} budget by ${CurrencyFormatter.format(overspent)}.',
            triggerType: AlertTriggerType.budgetThreshold85,
            scheduledDate: now,
            payload: {'budgetId': '${budget.id}', 'ratio': ratio.toStringAsFixed(2)},
          ),
        );
      } else if (ratio >= 0.85) {
        final percentUsed = (ratio * 100).toStringAsFixed(0);
        alerts.add(
          ScheduledAlert(
            id: budget.id ?? 100,
            title: 'Budget Warning: ${budget.name}',
            body: 'You have used $percentUsed% of your ${CurrencyFormatter.format(totalLimit)} monthly budget.',
            triggerType: AlertTriggerType.budgetThreshold85,
            scheduledDate: now,
            payload: {'budgetId': '${budget.id}', 'ratio': ratio.toStringAsFixed(2)},
          ),
        );
      }
    }

    return List.unmodifiable(alerts);
  }

  /// Evaluates recurring bills and identifies those due within the next 48 hours.
  List<ScheduledAlert> evaluateUpcomingBills({
    required List<RecurringTransaction> recurringBills,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final alerts = <ScheduledAlert>[];

    for (final bill in recurringBills) {
      if (!bill.isActive || bill.type != TransactionType.expense) continue;

      final nextDue = bill.nextDueDate ?? bill.nextOccurrence(now.subtract(const Duration(seconds: 1)));
      final diff = nextDue.difference(now);

      if (diff.isNegative) continue;

      if (diff.inHours <= 24) {
        alerts.add(
          ScheduledAlert(
            id: (bill.id ?? 0) * 10 + 1,
            title: 'Bill Due Tomorrow: ${bill.description.isEmpty ? "Recurring Bill" : bill.description}',
            body: '${CurrencyFormatter.format(bill.amount)} is scheduled for tomorrow.',
            triggerType: AlertTriggerType.upcomingBill,
            scheduledDate: nextDue.subtract(const Duration(hours: 24)),
            payload: {'billId': '${bill.id}', 'amount': bill.amount.toString()},
          ),
        );
      } else if (diff.inHours <= 48) {
        alerts.add(
          ScheduledAlert(
            id: (bill.id ?? 0) * 10 + 2,
            title: 'Upcoming Bill: ${bill.description.isEmpty ? "Recurring Bill" : bill.description}',
            body: '${CurrencyFormatter.format(bill.amount)} is due in 2 days.',
            triggerType: AlertTriggerType.upcomingBill,
            scheduledDate: nextDue.subtract(const Duration(hours: 48)),
            payload: {'billId': '${bill.id}', 'amount': bill.amount.toString()},
          ),
        );
      }
    }

    return List.unmodifiable(alerts);
  }

  /// Evaluates financial goal progress and returns milestone alerts (e.g. 50%, 100%).
  List<ScheduledAlert> evaluateGoalMilestones({
    required List<FinancialGoal> goals,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final alerts = <ScheduledAlert>[];

    for (final goal in goals) {
      if (goal.targetAmount <= 0) continue;

      final progress = goal.currentAmount / goal.targetAmount;
      if (progress >= 1.0) {
        alerts.add(
          ScheduledAlert(
            id: (goal.id ?? 0) * 100 + 1,
            title: 'Goal Achieved: ${goal.name}',
            body: 'Congratulations! You reached your goal of ${CurrencyFormatter.format(goal.targetAmount)}!',
            triggerType: AlertTriggerType.goalMilestone,
            scheduledDate: now,
            payload: {'goalId': '${goal.id}', 'progress': '1.0'},
          ),
        );
      } else if (progress >= 0.50 && progress < 0.55) {
        alerts.add(
          ScheduledAlert(
            id: (goal.id ?? 0) * 100 + 2,
            title: 'Halfway Milestone: ${goal.name}',
            body: 'You are 50% on your way to ${CurrencyFormatter.format(goal.targetAmount)}.',
            triggerType: AlertTriggerType.goalMilestone,
            scheduledDate: now,
            payload: {'goalId': '${goal.id}', 'progress': '0.5'},
          ),
        );
      }
    }

    return List.unmodifiable(alerts);
  }
}

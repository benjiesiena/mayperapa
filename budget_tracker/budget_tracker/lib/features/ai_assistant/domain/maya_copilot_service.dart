import '../../../core/utils/currency_formatter.dart';
import '../../../features/budgets/presentation/providers/budgets_provider.dart';
import '../../../shared/domain/entities/enums.dart';
import '../../../shared/domain/entities/recurring_transaction.dart';

/// Pure domain calculations for ambient AI assistance and contextual coaching.
/// Zero direct DOM or Flutter framework rendering dependencies.
class MayaCopilotService {
  const MayaCopilotService._();

  /// Calculates safe daily spending allowance for the remainder of the calendar month.
  static double calculateDailyAllowance({
    required double remainingBudget,
    required int daysRemainingInMonth,
  }) {
    if (remainingBudget <= 0) return 0.0;
    final effectiveDays = daysRemainingInMonth < 1 ? 1 : daysRemainingInMonth;
    return remainingBudget / effectiveDays;
  }

  /// Filters recurring transactions for upcoming expense obligations within the specified window.
  static List<RecurringTransaction> findBillsDueWithin({
    required List<RecurringTransaction> recurringTransactions,
    required DateTime now,
    required Duration window,
  }) {
    final cutoff = now.add(window);
    final due = <RecurringTransaction>[];

    for (final bill in recurringTransactions) {
      if (!bill.isActive || bill.type != TransactionType.expense) continue;

      final dueDate = bill.nextDueDate ?? bill.startDate;
      if (!dueDate.isBefore(now) && !dueDate.isAfter(cutoff)) {
        due.add(bill);
      }
    }

    due.sort((a, b) {
      final dateA = a.nextDueDate ?? a.startDate;
      final dateB = b.nextDueDate ?? b.startDate;
      return dateA.compareTo(dateB);
    });

    return due;
  }

  /// Evaluates real-time impact of a proposed transaction on category and overall budget headroom.
  static BudgetImpactResult evaluateTransactionBudgetImpact({
    required ActiveBudgetState budgetState,
    int? categoryId,
    String? categoryName,
    double categorySpent = 0,
    required double proposedAmount,
  }) {
    if (proposedAmount <= 0) {
      return const BudgetImpactResult(
        isExceeded: false,
        remainingAfter: 0,
        message: '',
      );
    }

    final catName = categoryName ?? 'Category';

    // 1. Check if category-specific allocation exists in active budget
    if (categoryId != null && budgetState.items.isNotEmpty) {
      final matchingItem = budgetState.items.where((i) => i.categoryId == categoryId).firstOrNull;
      if (matchingItem != null) {
        final remainingBefore = matchingItem.amount - categorySpent;
        final remainingAfter = remainingBefore - proposedAmount;
        final isExceeded = remainingAfter < 0;

        final message = isExceeded
            ? 'Exceeds $catName budget by ${CurrencyFormatter.format(-remainingAfter)}.'
            : '${CurrencyFormatter.format(proposedAmount)} on $catName leaves ${CurrencyFormatter.format(remainingAfter)} in your budget.';

        return BudgetImpactResult(
          isExceeded: isExceeded,
          remainingAfter: remainingAfter,
          message: message,
          allocated: matchingItem.amount,
        );
      }
    }

    // 2. Check against overall active budget
    if (budgetState.budget != null) {
      final remainingAfter = budgetState.remaining - proposedAmount;
      final isExceeded = remainingAfter < 0;

      final message = isExceeded
          ? 'Exceeds monthly budget by ${CurrencyFormatter.format(-remainingAfter)}.'
          : '${CurrencyFormatter.format(proposedAmount)} leaves ${CurrencyFormatter.format(remainingAfter)} in your monthly budget.';

      return BudgetImpactResult(
        isExceeded: isExceeded,
        remainingAfter: remainingAfter,
        message: message,
        allocated: budgetState.budget!.totalBudget,
      );
    }

    // 3. Fallback when no active budget is configured
    return BudgetImpactResult(
      isExceeded: false,
      remainingAfter: 0,
      message: '${CurrencyFormatter.format(proposedAmount)} logged to $catName.',
    );
  }
}

class BudgetImpactResult {
  final bool isExceeded;
  final double remainingAfter;
  final String message;
  final double allocated;

  const BudgetImpactResult({
    required this.isExceeded,
    required this.remainingAfter,
    required this.message,
    this.allocated = 0,
  });
}

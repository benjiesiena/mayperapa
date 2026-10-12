import 'package:intl/intl.dart';

import '../../../../shared/domain/entities/category.dart';
import '../../../../shared/domain/entities/enums.dart';
import '../../../../shared/domain/entities/transaction.dart';
import '../entities/financial_time_series.dart';

/// Pure domain calculation engine for financial trends, cash flow analysis,
/// and spending distributions. Free of DOM and Flutter dependencies.
class SpendingTrendEngine {
  const SpendingTrendEngine();

  /// Filters transactions according to the selected time horizon.
  List<Transaction> filterTransactionsByPeriod(
    List<Transaction> transactions,
    AnalyticsPeriod period, {
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();

    DateTime? cutoff;
    switch (period) {
      case AnalyticsPeriod.days30:
        cutoff = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
        break;
      case AnalyticsPeriod.months3:
        cutoff = DateTime(now.year, now.month - 3, now.day);
        break;
      case AnalyticsPeriod.months6:
        cutoff = DateTime(now.year, now.month - 6, now.day);
        break;
      case AnalyticsPeriod.yearToDate:
        cutoff = DateTime(now.year, 1, 1);
        break;
      case AnalyticsPeriod.allTime:
        cutoff = null;
        break;
    }

    if (cutoff == null) return List.unmodifiable(transactions);
    return transactions.where((t) => !t.date.isBefore(cutoff!)).toList();
  }

  /// Builds chronological monthly inflow vs outflow series for bar charts.
  List<MonthlyCashFlowPoint> buildMonthlyCashFlow(
    List<Transaction> transactions, {
    int monthCount = 6,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final points = <MonthlyCashFlowPoint>[];

    for (var i = monthCount - 1; i >= 0; i--) {
      // Calculate target year and month
      final targetDate = DateTime(now.year, now.month - i, 1);
      final year = targetDate.year;
      final month = targetDate.month;
      final monthLabel = DateFormat('MMM').format(targetDate);

      double monthlyInflow = 0;
      double monthlyOutflow = 0;

      for (final t in transactions) {
        if (t.date.year == year && t.date.month == month) {
          if (t.type == TransactionType.income) {
            monthlyInflow += t.amount;
          } else if (t.type == TransactionType.expense) {
            monthlyOutflow += t.amount;
          }
        }
      }

      points.add(
        MonthlyCashFlowPoint(
          year: year,
          month: month,
          monthLabel: monthLabel,
          inflow: monthlyInflow,
          outflow: monthlyOutflow,
          net: monthlyInflow - monthlyOutflow,
        ),
      );
    }

    return List.unmodifiable(points);
  }

  /// Builds expense breakdown by category for donut/pie charts with percentage shares.
  List<CategorySpendingSlice> buildCategoryBreakdown(
    List<Transaction> transactions,
    List<Category> categories,
  ) {
    final categoryMap = {for (final c in categories) c.id!: c};
    final expenseMap = <int, double>{};
    double totalExpense = 0;

    for (final t in transactions) {
      if (t.type == TransactionType.expense) {
        expenseMap[t.categoryId] = (expenseMap[t.categoryId] ?? 0) + t.amount;
        totalExpense += t.amount;
      }
    }

    if (totalExpense <= 0) return const [];

    final slices = <CategorySpendingSlice>[];
    expenseMap.forEach((catId, amount) {
      final category = categoryMap[catId];
      final name = category?.name ?? 'Other';
      final colorHex = category?.color ?? '#64748B';
      final percentage = (amount / totalExpense) * 100.0;

      slices.add(
        CategorySpendingSlice(
          categoryId: catId,
          categoryName: name,
          amount: amount,
          percentage: double.parse(percentage.toStringAsFixed(1)),
          colorHex: colorHex,
          icon: category?.icon,
        ),
      );
    });

    // Sort descending by amount
    slices.sort((a, b) => b.amount.compareTo(a.amount));

    // Limit to top 5 categories + bundle remaining into "Other"
    if (slices.length > 5) {
      final top5 = slices.take(5).toList();
      final remaining = slices.skip(5);

      double remainingAmount = 0;
      for (final r in remaining) {
        remainingAmount += r.amount;
      }

      if (remainingAmount > 0) {
        final remainingPercentage = (remainingAmount / totalExpense) * 100.0;
        top5.add(
          CategorySpendingSlice(
            categoryId: -1,
            categoryName: 'Other',
            amount: remainingAmount,
            percentage: double.parse(remainingPercentage.toStringAsFixed(1)),
            colorHex: '#94A3B8',
            icon: 'more_horiz',
          ),
        );
      }
      return List.unmodifiable(top5);
    }

    return List.unmodifiable(slices);
  }

  /// Builds net worth progression curve over time.
  List<NetWorthPoint> buildNetWorthTrajectory(
    List<Transaction> transactions, {
    int days = 30,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final points = <NetWorthPoint>[];

    // Compute cumulative balance up to a date
    double balanceUpTo(DateTime cutoffDate) {
      final endOfDay = DateTime(cutoffDate.year, cutoffDate.month, cutoffDate.day, 23, 59, 59);
      return transactions
          .where((t) => !t.date.isAfter(endOfDay))
          .fold(0.0, (sum, t) => sum + t.signedAmount);
    }

    // Interval step based on period length
    final stepDays = days <= 30 ? 5 : (days <= 90 ? 15 : 30);
    final count = (days / stepDays).ceil();

    for (var i = count; i >= 0; i--) {
      final pointDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i * stepDays));
      final label = DateFormat('M/d').format(pointDate);
      final netWorth = balanceUpTo(pointDate);

      points.add(
        NetWorthPoint(
          date: pointDate,
          netWorth: netWorth,
          label: label,
        ),
      );
    }

    return List.unmodifiable(points);
  }

  /// Calculates top-level financial metrics for the active period.
  AnalyticsFinancialSummary calculateSummary(
    List<Transaction> transactions,
    AnalyticsPeriod period, {
    DateTime? referenceDate,
  }) {
    final filtered = filterTransactionsByPeriod(transactions, period, referenceDate: referenceDate);

    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in filtered) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else if (t.type == TransactionType.expense) {
        totalExpense += t.amount;
      }
    }

    final netSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (netSavings / totalIncome).clamp(0.0, 1.0) : 0.0;

    return AnalyticsFinancialSummary(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      netSavings: netSavings,
      savingsRate: savingsRate,
      period: period,
      transactionCount: filtered.length,
    );
  }
}

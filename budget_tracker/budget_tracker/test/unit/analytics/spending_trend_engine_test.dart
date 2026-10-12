import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/features/analytics/domain/entities/financial_time_series.dart';
import 'package:mayperapa/features/analytics/domain/services/spending_trend_engine.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';

void main() {
  const engine = SpendingTrendEngine();
  final now = DateTime(2026, 10, 15, 12, 0);

  final testCategories = [
    Category(id: 1, userId: 1, name: 'Food & Dining', type: CategoryType.expense, color: '#F97316', icon: 'restaurant', createdAt: now, updatedAt: now),
    Category(id: 2, userId: 1, name: 'Transportation', type: CategoryType.expense, color: '#3B82F6', icon: 'directions_car', createdAt: now, updatedAt: now),
    Category(id: 3, userId: 1, name: 'Housing & Utilities', type: CategoryType.expense, color: '#10B981', icon: 'home', createdAt: now, updatedAt: now),
    Category(id: 4, userId: 1, name: 'Shopping', type: CategoryType.expense, color: '#EC4899', icon: 'shopping_bag', createdAt: now, updatedAt: now),
    Category(id: 5, userId: 1, name: 'Entertainment', type: CategoryType.expense, color: '#8B5CF6', icon: 'movie', createdAt: now, updatedAt: now),
    Category(id: 6, userId: 1, name: 'Healthcare', type: CategoryType.expense, color: '#EF4444', icon: 'medical_services', createdAt: now, updatedAt: now),
  ];

  Transaction makeTxn({
    required int id,
    required TransactionType type,
    required double amount,
    required DateTime date,
    int categoryId = 1,
    int accountId = 1,
  }) {
    return Transaction(
      id: id,
      userId: 1,
      accountId: accountId,
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: date,
      createdAt: date,
      updatedAt: date,
    );
  }

  group('SpendingTrendEngine Tests', () {
    test('filterTransactionsByPeriod filters correctly by cutoff horizon', () {
      final txns = [
        makeTxn(id: 1, type: TransactionType.expense, amount: 100, date: DateTime(2026, 10, 10)), // 5 days ago
        makeTxn(id: 2, type: TransactionType.expense, amount: 200, date: DateTime(2026, 9, 1)),   // ~45 days ago
        makeTxn(id: 3, type: TransactionType.expense, amount: 300, date: DateTime(2026, 6, 1)),   // ~4.5 months ago
        makeTxn(id: 4, type: TransactionType.expense, amount: 400, date: DateTime(2025, 12, 1)),  // Last year
      ];

      final days30 = engine.filterTransactionsByPeriod(txns, AnalyticsPeriod.days30, referenceDate: now);
      expect(days30.length, 1);
      expect(days30.first.id, 1);

      final months3 = engine.filterTransactionsByPeriod(txns, AnalyticsPeriod.months3, referenceDate: now);
      expect(months3.length, 2);

      final months6 = engine.filterTransactionsByPeriod(txns, AnalyticsPeriod.months6, referenceDate: now);
      expect(months6.length, 3);

      final ytd = engine.filterTransactionsByPeriod(txns, AnalyticsPeriod.yearToDate, referenceDate: now);
      expect(ytd.length, 3); // 2026 transactions only

      final all = engine.filterTransactionsByPeriod(txns, AnalyticsPeriod.allTime, referenceDate: now);
      expect(all.length, 4);
    });

    test('buildMonthlyCashFlow produces 6 consecutive months with accurate inflows/outflows', () {
      final txns = [
        makeTxn(id: 1, type: TransactionType.income, amount: 50000, date: DateTime(2026, 10, 1)),
        makeTxn(id: 2, type: TransactionType.expense, amount: 20000, date: DateTime(2026, 10, 5)),
        makeTxn(id: 3, type: TransactionType.income, amount: 48000, date: DateTime(2026, 9, 15)),
        makeTxn(id: 4, type: TransactionType.expense, amount: 15000, date: DateTime(2026, 9, 20)),
      ];

      final points = engine.buildMonthlyCashFlow(txns, monthCount: 6, referenceDate: now);
      expect(points.length, 6);

      // Latest month (Oct 2026)
      final octPoint = points.last;
      expect(octPoint.month, 10);
      expect(octPoint.inflow, 50000);
      expect(octPoint.outflow, 20000);
      expect(octPoint.net, 30000);

      // Previous month (Sep 2026)
      final sepPoint = points[points.length - 2];
      expect(sepPoint.month, 9);
      expect(sepPoint.inflow, 48000);
      expect(sepPoint.outflow, 15000);
      expect(sepPoint.net, 33000);
    });

    test('buildCategoryBreakdown calculates percentages and bundles top 5 + Other', () {
      final txns = [
        makeTxn(id: 1, type: TransactionType.expense, amount: 1000, categoryId: 1, date: now),
        makeTxn(id: 2, type: TransactionType.expense, amount: 800, categoryId: 2, date: now),
        makeTxn(id: 3, type: TransactionType.expense, amount: 600, categoryId: 3, date: now),
        makeTxn(id: 4, type: TransactionType.expense, amount: 400, categoryId: 4, date: now),
        makeTxn(id: 5, type: TransactionType.expense, amount: 200, categoryId: 5, date: now),
        makeTxn(id: 6, type: TransactionType.expense, amount: 100, categoryId: 6, date: now), // 6th category -> Other
      ];

      // Total = 3100
      final breakdown = engine.buildCategoryBreakdown(txns, testCategories);
      expect(breakdown.length, 6); // 5 top + 1 Other

      expect(breakdown.first.categoryName, 'Food & Dining');
      expect(breakdown.first.amount, 1000);
      expect(breakdown.first.percentage, closeTo(32.3, 0.2));

      expect(breakdown.last.categoryName, 'Other');
      expect(breakdown.last.amount, 100);
      expect(breakdown.last.percentage, closeTo(3.2, 0.2));
    });

    test('buildNetWorthTrajectory computes cumulative curve points', () {
      final txns = [
        makeTxn(id: 1, type: TransactionType.income, amount: 10000, date: now.subtract(const Duration(days: 20))),
        makeTxn(id: 2, type: TransactionType.expense, amount: 2000, date: now.subtract(const Duration(days: 10))),
        makeTxn(id: 3, type: TransactionType.income, amount: 5000, date: now.subtract(const Duration(days: 2))),
      ];

      final trajectory = engine.buildNetWorthTrajectory(txns, days: 30, referenceDate: now);
      expect(trajectory.isNotEmpty, true);
      // Final point should reflect all cumulative transactions: 10000 - 2000 + 5000 = 13000
      expect(trajectory.last.netWorth, 13000);
    });

    test('calculateSummary returns accurate savings rate and net savings', () {
      final txns = [
        makeTxn(id: 1, type: TransactionType.income, amount: 50000, date: now),
        makeTxn(id: 2, type: TransactionType.expense, amount: 35000, date: now),
      ];

      final summary = engine.calculateSummary(txns, AnalyticsPeriod.days30, referenceDate: now);
      expect(summary.totalIncome, 50000);
      expect(summary.totalExpense, 35000);
      expect(summary.netSavings, 15000);
      expect(summary.savingsRate, 0.3); // 15,000 / 50,000 = 30%
      expect(summary.transactionCount, 2);
    });
  });
}

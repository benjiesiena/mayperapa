import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../categories/presentation/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../domain/entities/financial_time_series.dart';
import '../../domain/services/spending_trend_engine.dart';

/// Provider for the pure trend calculation engine.
final spendingTrendEngineProvider = Provider<SpendingTrendEngine>((ref) {
  return const SpendingTrendEngine();
});

/// Active time filter period for analytics.
final selectedAnalyticsPeriodProvider = StateProvider<AnalyticsPeriod>((ref) {
  return AnalyticsPeriod.months3;
});

/// Top-level metrics summary (Inflow, Outflow, Net Saved, Savings Rate)
/// recalculated whenever transactions or the active period change.
final analyticsSummaryProvider = Provider<AnalyticsFinancialSummary>((ref) {
  final engine = ref.watch(spendingTrendEngineProvider);
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final period = ref.watch(selectedAnalyticsPeriodProvider);

  return engine.calculateSummary(transactions, period);
});

/// Monthly cash flow bars (Inflow vs Outflow) for the last 6 months.
final monthlyCashFlowProvider = Provider<List<MonthlyCashFlowPoint>>((ref) {
  final engine = ref.watch(spendingTrendEngineProvider);
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];

  return engine.buildMonthlyCashFlow(transactions, monthCount: 6);
});

/// Expense distribution by category filtered by active period.
final categoryBreakdownProvider = Provider<List<CategorySpendingSlice>>((ref) {
  final engine = ref.watch(spendingTrendEngineProvider);
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  final period = ref.watch(selectedAnalyticsPeriodProvider);

  final filtered = engine.filterTransactionsByPeriod(transactions, period);
  return engine.buildCategoryBreakdown(filtered, categories);
});

/// Trajectory of net balance over the last 30 or 90 days depending on period.
final netWorthTrajectoryProvider = Provider<List<NetWorthPoint>>((ref) {
  final engine = ref.watch(spendingTrendEngineProvider);
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final period = ref.watch(selectedAnalyticsPeriodProvider);

  final days = switch (period) {
    AnalyticsPeriod.days30 => 30,
    AnalyticsPeriod.months3 => 90,
    AnalyticsPeriod.months6 => 180,
    AnalyticsPeriod.yearToDate => 180,
    AnalyticsPeriod.allTime => 365,
  };

  return engine.buildNetWorthTrajectory(transactions, days: days);
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../providers/analytics_provider.dart';
import '../widgets/cashflow_bar_chart.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/net_worth_line_chart.dart';
import '../widgets/period_selector_chip_group.dart';
import '../widgets/savings_gauge_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(analyticsSummaryProvider);
    final cashFlow = ref.watch(monthlyCashFlowProvider);
    final categorySlices = ref.watch(categoryBreakdownProvider);
    final netWorthTrajectory = ref.watch(netWorthTrajectoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Analytics',
            onPressed: () {
              ref.invalidate(transactionsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          children: [
            // 1. Period Selector Chip Group
            const PeriodSelectorChipGroup(),
            const SizedBox(height: AppSpacing.md),

            // 2. Savings Rate & Financial Summary Gauge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: SavingsGaugeCard(summary: summary),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. 6-Month Cash Flow Bar Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: CashflowBarChart(points: cashFlow),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Spending Distribution Donut Chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: CategoryDonutChart(slices: categorySlices),
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. Net Worth Trajectory Curve
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: NetWorthLineChart(points: netWorthTrajectory),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

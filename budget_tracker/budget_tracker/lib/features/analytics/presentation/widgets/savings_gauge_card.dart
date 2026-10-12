import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/financial_time_series.dart';

class SavingsGaugeCard extends StatelessWidget {
  final AnalyticsFinancialSummary summary;

  const SavingsGaugeCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    final savingsPercent = (summary.savingsRate * 100).toStringAsFixed(1);
    final meetsBenchmark = summary.savingsRate >= 0.20;
    final isPositiveSavings = summary.netSavings >= 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERIOD PERFORMANCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: palette.textTertiary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: meetsBenchmark
                      ? palette.positive.withValues(alpha: 0.12)
                      : palette.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      meetsBenchmark ? Icons.check_circle : Icons.trending_up,
                      size: 12,
                      color: meetsBenchmark ? palette.positive : palette.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      meetsBenchmark ? 'Healthy 20%+ Rate' : 'Target: 20% Saved',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: meetsBenchmark ? palette.positive : palette.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Savings Rate & Net Saved
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$savingsPercent%',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Savings Rate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: palette.textSecondary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Net Saved',
                    style: TextStyle(fontSize: 11, color: palette.textTertiary),
                  ),
                  Text(
                    CurrencyFormatter.format(summary.netSavings),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isPositiveSavings ? palette.positive : palette.negative,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress Gauge Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: summary.savingsRate.clamp(0.0, 1.0),
                backgroundColor: palette.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  meetsBenchmark ? palette.positive : palette.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Inflow vs Outflow Mini Summary
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Inflow', style: TextStyle(fontSize: 11, color: palette.textTertiary)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(summary.totalIncome),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.positive),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Outflow', style: TextStyle(fontSize: 11, color: palette.textTertiary)),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(summary.totalExpense),
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.negative),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Activity Count', style: TextStyle(fontSize: 11, color: palette.textTertiary)),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.transactionCount} logs',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

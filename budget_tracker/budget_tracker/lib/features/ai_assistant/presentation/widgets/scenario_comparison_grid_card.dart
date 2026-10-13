import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/scenario_comparison_matrix.dart';

/// Interactive generative UI artifact displaying side-by-side financial scenarios.
///
/// Implements Emil Design Engineering micro-interactions with tactile card physics
/// and explicit visual highlighting for Maya's recommended path.
class ScenarioComparisonGridCard extends StatelessWidget {
  final ScenarioComparisonMatrix matrix;
  final ValueChanged<FinancialScenarioOption>? onSelectScenario;

  const ScenarioComparisonGridCard({
    super.key,
    required this.matrix,
    this.onSelectScenario,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  size: 16,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Expanded(
                child: Text(
                  matrix.title,
                  style: AppTypography.subheading.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          if (matrix.aiVerdictSummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: palette.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 15,
                    color: palette.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Maya Verdict: ${matrix.aiVerdictSummary}',
                      style: AppTypography.caption.copyWith(
                        color: palette.textPrimary,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Horizontal comparison cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < matrix.scenarios.length; i++) ...[
                  _ScenarioColumnCard(
                    scenario: matrix.scenarios[i],
                    onSelect: onSelectScenario,
                  ),
                  if (i < matrix.scenarios.length - 1)
                    const SizedBox(width: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioColumnCard extends StatefulWidget {
  final FinancialScenarioOption scenario;
  final ValueChanged<FinancialScenarioOption>? onSelect;

  const _ScenarioColumnCard({
    required this.scenario,
    this.onSelect,
  });

  @override
  State<_ScenarioColumnCard> createState() => _ScenarioColumnCardState();
}

class _ScenarioColumnCardState extends State<_ScenarioColumnCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final sc = widget.scenario;
    final isRec = sc.isRecommended;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: isRec
              ? palette.primary.withValues(alpha: 0.08)
              : palette.surfaceVariant.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isRec ? palette.primary : palette.border.withValues(alpha: 0.5),
            width: isRec ? 2.0 : 1.0,
          ),
          boxShadow: isRec
              ? [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (sc.badge.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isRec
                          ? palette.primary
                          : palette.border.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      sc.badge,
                      style: AppTypography.caption.copyWith(
                        color: isRec ? Colors.white : palette.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                if (isRec)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: palette.primary,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs + 2),

            // Title
            Text(
              sc.title,
              style: AppTypography.subheading.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Key Metrics
            _MetricRow(
              label: 'Discretionary',
              value: CurrencyFormatter.format(sc.discretionarySpend),
            ),
            const SizedBox(height: 4),
            _MetricRow(
              label: 'Monthly Savings',
              value: CurrencyFormatter.format(sc.monthlySavings),
              valueColor: palette.positive,
              isBold: true,
            ),
            const SizedBox(height: 4),
            _MetricRow(
              label: 'Defense Runway',
              value: '${sc.emergencyRunwayMonths.toStringAsFixed(1)} mos',
            ),
            const SizedBox(height: 4),
            _MetricRow(
              label: 'Goal Horizon',
              value: '${sc.goalTargetMonths} months',
            ),
            const SizedBox(height: AppSpacing.md),

            // Action Button
            Listener(
              onPointerDown: (_) => setState(() => _isPressed = true),
              onPointerUp: (_) => setState(() => _isPressed = false),
              onPointerCancel: (_) => setState(() => _isPressed = false),
              child: SizedBox(
                height: 36,
                child: isRec || sc.actionDraft != null
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        onPressed: () => widget.onSelect?.call(sc),
                        child: const Text(
                          'Apply Plan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.textPrimary,
                          side: BorderSide(color: palette.border.withValues(alpha: 0.6)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        ),
                        onPressed: () => widget.onSelect?.call(sc),
                        child: const Text(
                          'Select Pace',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: palette.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: valueColor ?? palette.textPrimary,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

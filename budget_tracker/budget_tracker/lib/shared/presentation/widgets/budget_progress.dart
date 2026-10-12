import "package:flutter/material.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_typography.dart";
import "../../../core/theme/app_spacing.dart";
import "../../../core/utils/currency_formatter.dart";

/// Linear budget progress bar with tiered alert states:
/// - Safe (<75%): Calibrated emerald
/// - Caution (75-99%): Warm amber
/// - Exceeded (>=100%): Muted rose/crimson
class BudgetProgress extends StatelessWidget {
  final String label;
  final double spent;
  final double budget;

  const BudgetProgress({
    super.key,
    required this.label,
    required this.spent,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final pct = budget <= 0 ? 0.0 : (spent / budget);
    final isExceeded = pct >= 1.0;
    final isWarning = !isExceeded && pct >= 0.75;

    final color = isExceeded ? palette.negative : (isWarning ? palette.warning : palette.positive);
    final badgeBg = isExceeded
        ? palette.negativeLight
        : (isWarning ? palette.warningLight : palette.positiveLight);

    final remaining = budget - spent;
    final pctString = (pct * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(label, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: AppSpacing.xs + 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    "$pctString%",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              "${CurrencyFormatter.format(spent)} / ${CurrencyFormatter.format(budget)}",
              style: AppTypography.supporting.copyWith(
                color: palette.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: palette.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              remaining >= 0
                  ? "${CurrencyFormatter.format(remaining)} remaining"
                  : "${CurrencyFormatter.format(remaining.abs())} over budget",
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: remaining >= 0 ? palette.textSecondary : palette.negative,
              ),
            ),
            if (isExceeded)
              Text(
                "Limit Reached",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.negative),
              ),
          ],
        ),
      ],
    );
  }
}

import "package:flutter/material.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_typography.dart";
import "../../../core/theme/app_spacing.dart";
import "../../../core/utils/currency_formatter.dart";

/// Legacy or compact presentation of financial metrics.
class FinancialSummary extends StatelessWidget {
  final String label;
  final double amount;
  final String? subtitle;
  final bool? isPositive;

  const FinancialSummary({
    super.key,
    required this.label,
    required this.amount,
    this.subtitle,
    this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final color = isPositive == null ? palette.textPrimary : (isPositive! ? palette.positive : palette.negative);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.supporting.copyWith(color: palette.textSecondary)),
        const SizedBox(height: 4),
        Text(CurrencyFormatter.format(amount), style: AppTypography.primaryValue.copyWith(color: color, fontSize: 22)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: AppTypography.caption.copyWith(color: palette.textTertiary)),
        ],
      ],
    );
  }
}

/// Containerized financial summary tile with scannable icon badge and clean surface styling.
class FinancialSummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String? subtitle;
  final bool? isPositive;
  final IconData? icon;

  const FinancialSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    this.subtitle,
    this.isPositive,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final color = isPositive == null ? palette.textPrimary : (isPositive! ? palette.positive : palette.negative);
    final badgeBg = isPositive == null
        ? palette.surfaceVariant
        : (isPositive! ? palette.positiveLight : palette.negativeLight);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            CurrencyFormatter.format(amount),
            style: AppTypography.primaryValue.copyWith(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppTypography.caption.copyWith(color: palette.textTertiary)),
          ],
        ],
      ),
    );
  }
}

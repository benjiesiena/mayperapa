import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/domain/entities/recurring_transaction.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';

/// Ambient intelligence card displayed prominently on the Home Dashboard.
///
/// Surfaces daily spending velocity, upcoming 72h obligations, and 1-tap access
/// to Maya's conversational advisory without forcing the user to switch tabs.
class MayaBriefingCard extends StatelessWidget {
  final double dailyAllowance;
  final int daysRemainingInMonth;
  final double remainingBudget;
  final List<RecurringTransaction> upcomingBills;
  final VoidCallback? onAskMaya;

  const MayaBriefingCard({
    super.key,
    required this.dailyAllowance,
    required this.daysRemainingInMonth,
    required this.remainingBudget,
    this.upcomingBills = const [],
    this.onAskMaya,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final hasBillsDue = upcomingBills.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: palette.primary.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm + 4, AppSpacing.md, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  'MAYA INTELLIGENCE BRIEFING',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    fontSize: 11,
                    color: palette.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '$daysRemainingInMonth days left',
                    style: AppTypography.caption.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Daily Allowance Metric Row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  CurrencyFormatter.format(dailyAllowance),
                  style: AppTypography.primaryValue.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ day safe allowance',
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Proactive 72h Upcoming Bills Notification
          if (hasBillsDue) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
                decoration: BoxDecoration(
                  color: palette.warningLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: palette.warning.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 15, color: palette.warning),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: Text(
                        _buildBillsNotificationText(upcomingBills),
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xs),

          // 1-Tap Quick Action Row
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm + 2),
            child: TactileBounce(
              onTap: onAskMaya,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: palette.border.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 13,
                      color: palette.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Ask Maya about today's pacing",
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: palette.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _buildBillsNotificationText(List<RecurringTransaction> bills) {
    if (bills.isEmpty) return '';
    final first = bills.first;
    final formattedAmount = CurrencyFormatter.format(first.amount);
    if (bills.length == 1) {
      return '${first.description} ($formattedAmount) due in 72h';
    }
    return '${bills.length} bills due in 72h (${first.description} + others)';
  }
}

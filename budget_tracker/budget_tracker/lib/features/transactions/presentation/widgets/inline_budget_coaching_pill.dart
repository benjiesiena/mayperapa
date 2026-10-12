import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../ai_assistant/domain/maya_copilot_service.dart';

/// Contextual micro-coaching indicator shown in [AddTransactionScreen].
///
/// Provides instantaneous, sub-second ambient feedback on how the user's
/// proposed expense will impact their monthly and category budget headroom.
class InlineBudgetCoachingPill extends StatelessWidget {
  final BudgetImpactResult? impact;
  final bool isVisible;

  const InlineBudgetCoachingPill({
    super.key,
    required this.impact,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final show = isVisible && impact != null && impact!.message.isNotEmpty;

    return AnimatedSize(
      duration: AppDurations.standard,
      curve: AppCurves.easeOut,
      child: show
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: impact!.isExceeded
                      ? palette.negativeLight.withValues(alpha: 0.6)
                      : palette.primaryLight.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: impact!.isExceeded
                        ? palette.negative.withValues(alpha: 0.4)
                        : palette.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      impact!.isExceeded
                          ? Icons.warning_amber_rounded
                          : Icons.auto_awesome_rounded,
                      size: 14,
                      color: impact!.isExceeded ? palette.negative : palette.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        impact!.message,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: impact!.isExceeded ? palette.negative : palette.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import '../../domain/entities/financial_time_series.dart';
import '../providers/analytics_provider.dart';

class PeriodSelectorChipGroup extends ConsumerWidget {
  const PeriodSelectorChipGroup({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.appColors;
    final activePeriod = ref.watch(selectedAnalyticsPeriodProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: AnalyticsPeriod.values.map((period) {
          final isSelected = period == activePeriod;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: TactileBounce(
              onTap: () {
                if (!isSelected) {
                  HapticFeedback.selectionClick();
                  ref.read(selectedAnalyticsPeriodProvider.notifier).state = period;
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? palette.primary : palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: isSelected ? palette.primary : palette.border,
                    width: 1,
                  ),
                ),
                child: Text(
                  period.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : palette.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

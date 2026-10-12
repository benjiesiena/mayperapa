import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/ai_scenario_sandbox.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';

/// Dynamic interactive generative UI artifact.
///
/// Renders an interactive slider card in the AI chat bubble that enables the user
/// to drag and explore what-if scenario cut amounts with real-time recalculation of
/// goal completion acceleration and annual wealth accumulation.
class ScenarioSandboxCard extends StatefulWidget {
  final AIScenarioSandbox sandbox;
  final ValueChanged<double>? onApplyCut;

  const ScenarioSandboxCard({
    super.key,
    required this.sandbox,
    this.onApplyCut,
  });

  @override
  State<ScenarioSandboxCard> createState() => _ScenarioSandboxCardState();
}

class _ScenarioSandboxCardState extends State<ScenarioSandboxCard> {
  late double _currentCut;

  @override
  void initState() {
    super.initState();
    _currentCut = widget.sandbox.baselineCutAmount;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final calc = widget.sandbox.calculateImpact(_currentCut);

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
                  Icons.tune_rounded,
                  size: 15,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                'WHAT-IF SCENARIO SANDBOX',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontSize: 10.5,
                  color: palette.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: palette.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  widget.sandbox.categoryName,
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Slider Value Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Monthly Reduction:',
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
              Text(
                '-${CurrencyFormatter.format(_currentCut)} / mo',
                style: AppTypography.sectionHeading.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.positive,
                ),
              ),
            ],
          ),

          // Interactive Tactile Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: palette.primary,
              inactiveTrackColor: palette.border.withValues(alpha: 0.5),
              thumbColor: palette.primary,
              overlayColor: palette.primary.withValues(alpha: 0.15),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              trackHeight: 4,
            ),
            child: Slider(
              value: _currentCut.clamp(widget.sandbox.minCutAmount, widget.sandbox.maxCutAmount),
              min: widget.sandbox.minCutAmount,
              max: widget.sandbox.maxCutAmount,
              divisions: ((widget.sandbox.maxCutAmount - widget.sandbox.minCutAmount) / 100).round().clamp(1, 100),
              onChanged: (val) {
                setState(() {
                  _currentCut = (val / 50).round() * 50.0;
                });
              },
            ),
          ),

          // Real-Time Dynamic Simulation Metrics
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: palette.surfaceVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: palette.border.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Annual Wealth Boost:',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                    Text(
                      '+${CurrencyFormatter.format(calc.annualSavings)} / year',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: palette.positive,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.sandbox.goalName} Timeline:',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        color: palette.textSecondary,
                      ),
                    ),
                    Text(
                      calc.monthsToGoal > 0
                          ? '${calc.monthsToGoal.toStringAsFixed(1)} months'
                          : 'Completed!',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (calc.monthsSavedFaster > 0.1) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.bolt_rounded, size: 12, color: palette.warning),
                      const SizedBox(width: 2),
                      Text(
                        '${calc.monthsSavedFaster.toStringAsFixed(1)} months faster!',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: palette.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm + 2),

          // Apply Reduction Action Button
          TactileBounce(
            onTap: widget.onApplyCut != null
                ? () => widget.onApplyCut!(_currentCut)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: palette.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Apply ${CurrencyFormatter.format(_currentCut)} Monthly Cut',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

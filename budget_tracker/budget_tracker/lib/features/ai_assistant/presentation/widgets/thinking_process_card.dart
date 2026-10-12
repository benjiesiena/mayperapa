import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_reasoning_step.dart';

/// Interactive, collapsible thinking trace card inspired by frontier AI reasoning interfaces
/// (Claude 3.7 Extended Thinking & DeepSeek-R1).
///
/// Gives users immediate visual proof that mathematical checks and trade-off constraints
/// were evaluated with precision before the final answer was synthesized.
class ThinkingProcessCard extends StatefulWidget {
  final List<AIReasoningStep> steps;
  final Duration? duration;
  final List<String> toolCallNames;
  final bool initialExpanded;

  const ThinkingProcessCard({
    super.key,
    required this.steps,
    this.duration,
    this.toolCallNames = const [],
    this.initialExpanded = false,
  });

  @override
  State<ThinkingProcessCard> createState() => _ThinkingProcessCardState();
}

class _ThinkingProcessCardState extends State<ThinkingProcessCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    final palette = context.appColors;
    final totalMs = widget.duration?.inMilliseconds ??
        widget.steps.fold<int>(0, (sum, s) => sum + (s.durationMs ?? 0));
    final durationLabel = totalMs > 0
        ? '${(totalMs / 1000).toStringAsFixed(1)}s'
        : '${widget.steps.length} steps';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm + 2,
                  vertical: AppSpacing.xs + 2,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 16,
                      color: palette.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      'Thought for $durationLabel',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.surfaceVariant.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        '${widget.steps.length} checks',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: palette.textTertiary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: AppDurations.standard,
                      curve: AppCurves.easeOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: palette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsible Steps Details
          AnimatedSize(
            duration: AppDurations.standard,
            curve: AppCurves.easeOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm + 2,
                      AppSpacing.xs,
                      AppSpacing.sm + 2,
                      AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: palette.border.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < widget.steps.length; i++)
                          _buildStepRow(
                            context,
                            widget.steps[i],
                            isLast: i == widget.steps.length - 1 && widget.toolCallNames.isEmpty,
                          ),
                        if (widget.toolCallNames.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs + 4),
                          Divider(
                            height: 1,
                            color: palette.border.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: AppSpacing.xs + 4),
                          Text(
                            'VERIFIED SOURCES',
                            style: AppTypography.caption.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: palette.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: widget.toolCallNames
                                .map((t) => _buildToolChip(context, t))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(BuildContext context, AIReasoningStep step, {required bool isLast}) {
    final palette = context.appColors;

    IconData icon;
    Color iconColor;

    switch (step.type) {
      case AIReasoningStepType.plan:
        icon = Icons.rule_rounded;
        iconColor = palette.primary;
        break;
      case AIReasoningStepType.inspect:
        icon = Icons.search_rounded;
        iconColor = palette.primary;
        break;
      case AIReasoningStepType.calculate:
        icon = Icons.calculate_outlined;
        iconColor = palette.positive;
        break;
      case AIReasoningStepType.simulate:
        icon = Icons.show_chart_rounded;
        iconColor = palette.warning;
        break;
      case AIReasoningStepType.synthesize:
        icon = Icons.auto_awesome_rounded;
        iconColor = palette.primary;
        break;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.xs + 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 12, color: iconColor),
          ),
          const SizedBox(width: AppSpacing.xs + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        step.title,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    if (step.durationMs != null && step.durationMs! > 0)
                      Text(
                        '${step.durationMs}ms',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: palette.textTertiary,
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
                if (step.detail != null && step.detail!.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    step.detail!,
                    style: AppTypography.caption.copyWith(
                      color: palette.textSecondary,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolChip(BuildContext context, String toolName) {
    final palette = context.appColors;
    final meta = _getToolChipMeta(toolName);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: palette.surfaceVariant.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: palette.border.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.$2, size: 11, color: palette.primary),
          const SizedBox(width: 4),
          Text(
            meta.$1,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  (String, IconData) _getToolChipMeta(String toolName) {
    switch (toolName) {
      case 'get_current_balance':
        return ('Liquidity Audited', Icons.account_balance_wallet_outlined);
      case 'get_account_balances':
        return ('Accounts Verified', Icons.account_balance_outlined);
      case 'calculate_affordable_spending':
        return ('Affordability Model', Icons.verified_outlined);
      case 'get_recurring_expenses':
      case 'calculate_recurring_monthly_total':
        return ('Recurring Bills Checked', Icons.repeat_rounded);
      case 'get_budget_status':
      case 'get_remaining_budget':
        return ('Budget Limits Audited', Icons.pie_chart_outline_rounded);
      case 'get_monthly_expenses':
        return ('Monthly Outflows', Icons.insights_rounded);
      case 'get_expenses_by_category':
      case 'get_top_spending_categories':
        return ('Top Categories', Icons.category_outlined);
      case 'get_all_goals':
      case 'get_goal_progress':
        return ('Savings Goals', Icons.flag_outlined);
      case 'simulate_financial_scenario':
        return ('Scenario Sandbox', Icons.trending_up_rounded);
      case 'calculate_savings_rate':
        return ('Savings Rate', Icons.percent_rounded);
      case 'get_recent_transactions':
      case 'search_transactions':
        return ('Ledger Records', Icons.receipt_long_outlined);
      default:
        return (toolName.replaceAll('_', ' '), Icons.check_circle_outline_rounded);
    }
  }
}

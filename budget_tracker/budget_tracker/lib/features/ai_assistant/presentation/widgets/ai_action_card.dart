import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_action_draft.dart';

/// Interactive Confirmation Card rendered inside chat bubbles when the AI
/// drafts a database mutation (transaction, budget, goal, or financial plan).
/// Adheres strictly to Emil Design Engineering physics, custom easing curves,
/// and high-contrast WCAG AA standards.
class AIActionCard extends StatefulWidget {
  final AIActionDraft draft;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AIActionCard({
    super.key,
    required this.draft,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<AIActionCard> createState() => _AIActionCardState();
}

class _AIActionCardState extends State<AIActionCard> {
  bool _isConfirmPressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final draft = widget.draft;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: _getBorderColor(palette, draft.status),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, palette, draft),
          const SizedBox(height: AppSpacing.sm),
          _buildBody(context, palette, draft),
          const SizedBox(height: AppSpacing.md),
          _buildFooter(context, palette, draft),
        ],
      ),
    );
  }

  Color _getBorderColor(AppColorPalette palette, AIActionStatus status) {
    switch (status) {
      case AIActionStatus.executed:
        return palette.positive.withValues(alpha: 0.5);
      case AIActionStatus.cancelled:
        return palette.border;
      case AIActionStatus.failed:
        return palette.negative.withValues(alpha: 0.5);
      case AIActionStatus.pending:
      case AIActionStatus.confirmed:
        return palette.primary.withValues(alpha: 0.35);
    }
  }

  Widget _buildHeader(BuildContext context, AppColorPalette palette, AIActionDraft draft) {
    final (typeLabel, icon, iconColor) = _getTypeMetadata(palette, draft.type);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          typeLabel,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: iconColor,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        _buildStatusBadge(palette, draft.status),
      ],
    );
  }

  (String, IconData, Color) _getTypeMetadata(AppColorPalette palette, AIActionType type) {
    switch (type) {
      case AIActionType.createTransaction:
        final isIncome = widget.draft.payload['type'] == 'income';
        return (
          isIncome ? 'INCOME DRAFT' : 'EXPENSE DRAFT',
          isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
          isIncome ? palette.positive : palette.negative,
        );
      case AIActionType.createBudget:
        return ('BUDGET DRAFT', Icons.pie_chart_rounded, palette.primary);
      case AIActionType.createGoal:
        return ('SAVINGS GOAL', Icons.flag_rounded, const Color(0xFF8B5CF6));
      case AIActionType.applyFinancialPlan:
        return ('50/30/20 PLAN', Icons.auto_awesome_rounded, const Color(0xFF0EA5E9));
      case AIActionType.batchBundle:
        return ('ACTION BUNDLE', Icons.layers_outlined, const Color(0xFF6366F1));
    }
  }

  Widget _buildStatusBadge(AppColorPalette palette, AIActionStatus status) {
    switch (status) {
      case AIActionStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: palette.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            'Requires Confirmation',
            style: AppTypography.caption.copyWith(
              color: palette.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case AIActionStatus.confirmed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: palette.primary),
              ),
              const SizedBox(width: 4),
              Text(
                'Saving...',
                style: AppTypography.caption.copyWith(
                  color: palette.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case AIActionStatus.executed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: palette.positive.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 12, color: palette.positive),
              const SizedBox(width: 4),
              Text(
                'Saved',
                style: AppTypography.caption.copyWith(
                  color: palette.positive,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      case AIActionStatus.cancelled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: palette.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            'Cancelled',
            style: AppTypography.caption.copyWith(
              color: palette.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case AIActionStatus.failed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: palette.negative.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            'Failed',
            style: AppTypography.caption.copyWith(
              color: palette.negative,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    }
  }

  Widget _buildBody(BuildContext context, AppColorPalette palette, AIActionDraft draft) {
    if (draft.type == AIActionType.applyFinancialPlan) {
      return _buildPlanBody(palette, draft);
    }
    if (draft.type == AIActionType.batchBundle) {
      return _buildBundleBody(context, palette, draft);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.title,
          style: AppTypography.sectionHeading.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          draft.subtitle,
          style: AppTypography.supporting.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildMetadataChips(palette, draft),
      ],
    );
  }

  Widget _buildMetadataChips(AppColorPalette palette, AIActionDraft draft) {
    final chips = <Widget>[];

    if (draft.type == AIActionType.createTransaction) {
      final category = draft.payload['categoryName'] as String?;
      final account = draft.payload['accountName'] as String?;
      final desc = draft.payload['description'] as String?;

      if (category != null) {
        chips.add(_chip(palette, Icons.label_outline_rounded, category));
      }
      if (account != null) {
        chips.add(_chip(palette, Icons.account_balance_wallet_outlined, account));
      }
      if (desc != null && desc.isNotEmpty) {
        chips.add(_chip(palette, Icons.edit_note_rounded, desc));
      }
    } else if (draft.type == AIActionType.createBudget) {
      final period = draft.subtitle;
      chips.add(_chip(palette, Icons.calendar_today_rounded, period));
    } else if (draft.type == AIActionType.createGoal) {
      final target = draft.payload['targetAmount'];
      if (target != null) {
        final formatted = NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(target);
        chips.add(_chip(palette, Icons.track_changes_rounded, 'Target: $formatted'));
      }
    }

    return Wrap(
      spacing: AppSpacing.xs + 2,
      runSpacing: AppSpacing.xs,
      children: chips,
    );
  }

  Widget _chip(AppColorPalette palette, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: palette.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBody(AppColorPalette palette, AIActionDraft draft) {
    final salary = (draft.payload['salary'] as num?)?.toDouble() ?? 0.0;
    final needs = (draft.payload['needsBudget'] as num?)?.toDouble() ?? (salary * 0.50);
    final wants = (draft.payload['wantsBudget'] as num?)?.toDouble() ?? (salary * 0.30);
    final savings = (draft.payload['savingsGoal'] as num?)?.toDouble() ?? (salary * 0.20);

    final currency = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Salary: ${NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(salary)}',
          style: AppTypography.sectionHeading.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Target allocations based on the 50/30/20 balanced wealth formula:',
          style: AppTypography.caption.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Visual multi-segment bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(flex: 50, child: Container(color: const Color(0xFF10B981))),
                Expanded(flex: 30, child: Container(color: const Color(0xFFF59E0B))),
                Expanded(flex: 20, child: Container(color: const Color(0xFF8B5CF6))),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // 3 mini breakdown cards
        Row(
          children: [
            Expanded(
              child: _planBreakdownCard(
                palette: palette,
                color: const Color(0xFF10B981),
                label: 'Needs (50%)',
                amount: currency.format(needs),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _planBreakdownCard(
                palette: palette,
                color: const Color(0xFFF59E0B),
                label: 'Wants (30%)',
                amount: currency.format(wants),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _planBreakdownCard(
                palette: palette,
                color: const Color(0xFF8B5CF6),
                label: 'Savings (20%)',
                amount: currency.format(savings),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _planBreakdownCard({
    required AppColorPalette palette,
    required Color color,
    required String label,
    required String amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: AppTypography.supporting.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBundleBody(BuildContext context, AppColorPalette palette, AIActionDraft draft) {
    final rawActions = draft.payload['actions'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          draft.title,
          style: AppTypography.sectionHeading.copyWith(
            fontWeight: FontWeight.w800,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          draft.subtitle,
          style: AppTypography.supporting.copyWith(
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: palette.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: palette.border.withValues(alpha: 0.5)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: rawActions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: palette.border.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final actMap = Map<String, dynamic>.from(rawActions[index] as Map);
              final actTitle = (actMap['title'] as String?) ?? 'Action ${index + 1}';
              final actSubtitle = (actMap['subtitle'] as String?) ?? '';
              final actTypeStr = (actMap['type'] as String?) ?? '';

              IconData stepIcon;
              Color stepColor;
              if (actTypeStr == 'createBudget') {
                stepIcon = Icons.pie_chart_rounded;
                stepColor = palette.primary;
              } else if (actTypeStr == 'createGoal') {
                stepIcon = Icons.flag_rounded;
                stepColor = const Color(0xFF8B5CF6);
              } else {
                stepIcon = Icons.account_balance_wallet_outlined;
                stepColor = palette.positive;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: stepColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: stepColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs + 4),
                    Icon(stepIcon, size: 14, color: stepColor),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            actTitle,
                            style: AppTypography.supporting.copyWith(
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (actSubtitle.isNotEmpty)
                            Text(
                              actSubtitle,
                              style: AppTypography.caption.copyWith(
                                color: palette.textSecondary,
                                fontSize: 10.5,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 14,
                      color: palette.textTertiary,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppColorPalette palette, AIActionDraft draft) {
    if (draft.status == AIActionStatus.executed) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: palette.positive.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: palette.positive.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, size: 18, color: palette.positive),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                draft.executionResult ?? 'Successfully saved to your local database.',
                style: AppTypography.caption.copyWith(
                  color: palette.positive,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (draft.status == AIActionStatus.cancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Text(
          'Action cancelled.',
          style: AppTypography.caption.copyWith(
            color: palette.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final isConfirmed = draft.status == AIActionStatus.confirmed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: isConfirmed ? null : widget.onCancel,
          style: TextButton.styleFrom(
            foregroundColor: palette.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(color: palette.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Emil Design Engineering tactile animated button
        AnimatedScale(
          scale: _isConfirmPressed ? 0.96 : 1.0,
          duration: AppDurations.quick,
          curve: AppCurves.easeOut,
          child: ElevatedButton(
            onPressed: isConfirmed ? null : widget.onConfirm,
            onHover: (hovering) {},
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Listener(
              onPointerDown: (_) => setState(() => _isConfirmPressed = true),
              onPointerUp: (_) => setState(() => _isConfirmPressed = false),
              onPointerCancel: (_) => setState(() => _isConfirmPressed = false),
              child: isConfirmed
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          draft.type == AIActionType.applyFinancialPlan
                              ? 'Apply Plan'
                              : draft.type == AIActionType.batchBundle
                                  ? 'Confirm All (${(draft.payload['actions'] as List?)?.length ?? 0} Actions)'
                                  : 'Confirm & Save',
                          style: AppTypography.button.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

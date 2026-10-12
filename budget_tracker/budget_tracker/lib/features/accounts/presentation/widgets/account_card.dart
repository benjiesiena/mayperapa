import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/domain/entities/account.dart';
import '../../../../shared/domain/entities/enums.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import 'add_edit_account_sheet.dart';
import 'transfer_funds_sheet.dart';

class AccountCard extends ConsumerWidget {
  final Account account;
  final double currentBalance;
  final VoidCallback? onDelete;

  const AccountCard({
    super.key,
    required this.account,
    required this.currentBalance,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.appColors;
    final color = _parseColor(account.color);
    final isNegative = currentBalance < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
              // Icon Badge with Solid Tint
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(_iconForAccount(account.type), color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.name,
                            style: AppTypography.subheading.copyWith(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.accountNumberMasked != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: palette.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: palette.border),
                            ),
                            child: Text(
                              account.accountNumberMasked!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: palette.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _typeLabel(account.type),
                      style: AppTypography.caption.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),

              // Overflow Menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 20, color: palette.textSecondary),
                onSelected: (value) {
                  if (value == 'transfer') {
                    TransferFundsSheet.show(context, sourceAccountId: account.id);
                  } else if (value == 'edit') {
                    AddEditAccountSheet.show(context, account: account);
                  } else if (value == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'transfer',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 18),
                        SizedBox(width: 8),
                        Text('Transfer Funds'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Account'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: palette.negative),
                        const SizedBox(width: 8),
                        Text('Deactivate', style: TextStyle(color: palette.negative)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Balance Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE BALANCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: palette.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(currentBalance),
                    style: AppTypography.secondaryValue.copyWith(
                      color: isNegative ? palette.negative : palette.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),

              // Quick Transfer Action Button
              TactileBounce(
                onTap: () => TransferFundsSheet.show(context, sourceAccountId: account.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz, size: 14, color: palette.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Transfer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: palette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForAccount(AccountType type) => switch (type) {
        AccountType.cash => Icons.payments_outlined,
        AccountType.bank => Icons.account_balance_outlined,
        AccountType.digitalWallet => Icons.account_balance_wallet_outlined,
        AccountType.creditCard => Icons.credit_card_outlined,
        AccountType.investment => Icons.trending_up_outlined,
      };

  String _typeLabel(AccountType type) => switch (type) {
        AccountType.cash => 'Cash Wallet',
        AccountType.bank => 'Bank Account',
        AccountType.digitalWallet => 'Digital E-Wallet',
        AccountType.creditCard => 'Credit Card',
        AccountType.investment => 'Investment Account',
      };

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF3B82F6);
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }
}

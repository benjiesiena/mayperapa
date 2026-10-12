import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/domain/entities/account.dart';
import '../../../../shared/domain/entities/enums.dart';
import '../../../../shared/domain/services/financial_calculator.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import 'package:mayperapa/features/transactions/presentation/providers/transactions_provider.dart';
import '../accounts_provider.dart';
import '../widgets/account_card.dart';
import '../widgets/add_edit_account_sheet.dart';
import '../widgets/transfer_funds_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.appColors;
    final accountsAsync = ref.watch(accountsProvider);
    final txns = ref.watch(transactionsProvider).valueOrNull ?? [];
    const calculator = FinancialCalculator();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounts & Wallets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'Transfer Funds',
            onPressed: () => TransferFundsSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Account',
            onPressed: () => AddEditAccountSheet.show(context),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Failed to load accounts: $err', style: TextStyle(color: palette.negative)),
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 56, color: palette.textTertiary),
                  const SizedBox(height: AppSpacing.md),
                  const Text('No accounts found', style: AppTypography.subheading),
                  const SizedBox(height: AppSpacing.sm),
                  TactileBounce(
                    onTap: () => AddEditAccountSheet.show(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      decoration: BoxDecoration(color: palette.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: const Text('Add Your First Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          }

          // Calculate balances per account
          final accountBalances = {
            for (final a in accounts) a.id!: calculator.calculateCurrentBalance(txns, accountId: a.id)
          };

          // Liquid Assets vs Liabilities
          double totalAssets = 0;
          double totalLiabilities = 0;

          for (final a in accounts) {
            final bal = accountBalances[a.id!] ?? 0;
            if (a.type == AccountType.creditCard) {
              totalLiabilities += bal.abs();
            } else {
              totalAssets += bal;
            }
          }

          final netWorth = totalAssets - totalLiabilities;

          // Group by type
          final eWallets = accounts.where((a) => a.type == AccountType.digitalWallet).toList();
          final banks = accounts.where((a) => a.type == AccountType.bank).toList();
          final cash = accounts.where((a) => a.type == AccountType.cash).toList();
          final credit = accounts.where((a) => a.type == AccountType.creditCard).toList();
          final investments = accounts.where((a) => a.type == AccountType.investment).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(accountsProvider);
              ref.invalidate(transactionsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // 1. Net Worth Hero Summary Card (Solid tailored surface, zero glassmorphism)
                _buildNetWorthHeroCard(
                  context,
                  netWorth: netWorth,
                  totalAssets: totalAssets,
                  totalLiabilities: totalLiabilities,
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Action Shortcuts Bar
                Row(
                  children: [
                    Expanded(
                      child: TactileBounce(
                        onTap: () => TransferFundsSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_horiz, size: 18, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Transfer Funds', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TactileBounce(
                        onTap: () => AddEditAccountSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: palette.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: palette.border),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 18, color: palette.textPrimary),
                              const SizedBox(width: 6),
                              Text('Add Account', style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. E-Wallets Section
                if (eWallets.isNotEmpty) ...[
                  _sectionHeader(context, 'E-WALLETS & DIGITAL'),
                  ...eWallets.map((a) => AccountCard(
                        account: a,
                        currentBalance: accountBalances[a.id!] ?? 0,
                        onDelete: () => _confirmDeactivation(context, ref, a),
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 4. Bank Accounts Section
                if (banks.isNotEmpty) ...[
                  _sectionHeader(context, 'BANK ACCOUNTS'),
                  ...banks.map((a) => AccountCard(
                        account: a,
                        currentBalance: accountBalances[a.id!] ?? 0,
                        onDelete: () => _confirmDeactivation(context, ref, a),
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 5. Cash & Envelopes Section
                if (cash.isNotEmpty) ...[
                  _sectionHeader(context, 'PHYSICAL CASH & ENVELOPES'),
                  ...cash.map((a) => AccountCard(
                        account: a,
                        currentBalance: accountBalances[a.id!] ?? 0,
                        onDelete: () => _confirmDeactivation(context, ref, a),
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 6. Credit Cards Section
                if (credit.isNotEmpty) ...[
                  _sectionHeader(context, 'CREDIT CARDS & LIABILITIES'),
                  ...credit.map((a) => AccountCard(
                        account: a,
                        currentBalance: accountBalances[a.id!] ?? 0,
                        onDelete: () => _confirmDeactivation(context, ref, a),
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],

                // 7. Investments Section
                if (investments.isNotEmpty) ...[
                  _sectionHeader(context, 'INVESTMENTS & OTHER ASSETS'),
                  ...investments.map((a) => AccountCard(
                        account: a,
                        currentBalance: accountBalances[a.id!] ?? 0,
                        onDelete: () => _confirmDeactivation(context, ref, a),
                      )),
                  const SizedBox(height: AppSpacing.md),
                ],

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetWorthHeroCard(
    BuildContext context, {
    required double netWorth,
    required double totalAssets,
    required double totalLiabilities,
  }) {
    final palette = context.appColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL NET WORTH',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: palette.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(netWorth),
            style: AppTypography.primaryValue.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: palette.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: palette.positive, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Total Assets', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalAssets),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: palette.negative, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('Liabilities', style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.format(totalLiabilities),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final palette = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
      child: Text(
        title,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: palette.textTertiary),
      ),
    );
  }

  void _confirmDeactivation(BuildContext context, WidgetRef ref, Account account) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Deactivate Account?'),
        content: Text(
          'Are you sure you want to deactivate "${account.name}"? Past transactions will remain intact, but it will be hidden from new transfers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              HapticFeedback.mediumImpact();
              await ref.read(accountsProvider.notifier).deleteAccount(account.id!);
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }
}

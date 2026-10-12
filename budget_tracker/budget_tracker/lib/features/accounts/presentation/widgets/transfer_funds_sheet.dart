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

class TransferFundsSheet extends ConsumerStatefulWidget {
  final int? initialSourceAccountId;
  final int? initialDestinationAccountId;

  const TransferFundsSheet({
    super.key,
    this.initialSourceAccountId,
    this.initialDestinationAccountId,
  });

  static Future<void> show(
    BuildContext context, {
    int? sourceAccountId,
    int? destinationAccountId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransferFundsSheet(
        initialSourceAccountId: sourceAccountId,
        initialDestinationAccountId: destinationAccountId,
      ),
    );
  }

  @override
  ConsumerState<TransferFundsSheet> createState() => _TransferFundsSheetState();
}

class _TransferFundsSheetState extends ConsumerState<TransferFundsSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _sourceAccountId;
  int? _destAccountId;
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _sourceAccountId = widget.initialSourceAccountId;
    _destAccountId = widget.initialDestinationAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _parseAmount() {
    final clean = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  void _applyQuickAmount(double amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _amountController.text = amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
      _error = null;
    });
  }

  Future<void> _submitTransfer(List<Account> accounts) async {
    final amount = _parseAmount();
    if (_sourceAccountId == null || _destAccountId == null) {
      setState(() => _error = 'Please select both source and destination accounts.');
      return;
    }
    if (_sourceAccountId == _destAccountId) {
      setState(() => _error = 'Source and destination accounts must be different.');
      return;
    }
    if (amount <= 0) {
      setState(() => _error = 'Please enter an amount greater than zero.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      HapticFeedback.mediumImpact();
      await ref.read(accountsProvider.notifier).transferFunds(
            sourceAccountId: _sourceAccountId!,
            destinationAccountId: _destAccountId!,
            amount: amount,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully transferred ${CurrencyFormatter.format(amount)}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = 'Transfer failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final accountsAsync = ref.watch(accountsProvider);
    final txns = ref.watch(transactionsProvider).valueOrNull ?? [];
    const calculator = FinancialCalculator();

    return accountsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Text('Error loading accounts: $e', style: TextStyle(color: palette.negative)),
      ),
      data: (accounts) {
        // Initialize default selection if not set
        if (_sourceAccountId == null && accounts.isNotEmpty) {
          _sourceAccountId = accounts.first.id;
        }
        if (_destAccountId == null && accounts.length > 1) {
          _destAccountId = accounts.firstWhere((a) => a.id != _sourceAccountId, orElse: () => accounts.last).id;
        }

        final sourceAccount = accounts.where((a) => a.id == _sourceAccountId).firstOrNull;
        final destAccount = accounts.where((a) => a.id == _destAccountId).firstOrNull;

        final sourceBalance = sourceAccount != null ? calculator.calculateCurrentBalance(txns, accountId: sourceAccount.id) : 0.0;
        final destBalance = destAccount != null ? calculator.calculateCurrentBalance(txns, accountId: destAccount.id) : 0.0;
        final transferAmount = _parseAmount();

        return Container(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.md,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
            border: Border.all(color: palette.border),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transfer Funds',
                      style: AppTypography.sectionHeader.copyWith(color: palette.textPrimary),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Source Account Selector
                Text('FROM ACCOUNT', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                _buildAccountDropdown(
                  context,
                  value: _sourceAccountId,
                  accounts: accounts,
                  onChanged: (id) => setState(() => _sourceAccountId = id),
                ),
                if (sourceAccount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Available: ${CurrencyFormatter.format(sourceBalance)}',
                    style: TextStyle(fontSize: 12, color: palette.textTertiary),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Destination Account Selector
                Text('TO ACCOUNT', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                _buildAccountDropdown(
                  context,
                  value: _destAccountId,
                  accounts: accounts,
                  onChanged: (id) => setState(() => _destAccountId = id),
                ),
                if (destAccount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Current balance: ${CurrencyFormatter.format(destBalance)}',
                    style: TextStyle(fontSize: 12, color: palette.textTertiary),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),

                // Amount Input
                Text('TRANSFER AMOUNT', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: palette.textPrimary),
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    prefixText: '₱ ',
                    prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: palette.primary),
                    hintText: '0.00',
                    hintStyle: TextStyle(fontSize: 24, color: palette.textTertiary),
                    filled: true,
                    fillColor: palette.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: palette.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Quick Amount Chips
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _quickChip(context, 500, label: '+₱500'),
                    _quickChip(context, 1000, label: '+₱1k'),
                    _quickChip(context, 2000, label: '+₱2k'),
                    _quickChip(context, 5000, label: '+₱5k'),
                    if (sourceBalance > 0)
                      _quickChip(context, sourceBalance, label: 'All (₱${sourceBalance.toStringAsFixed(0)})'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Note (Optional)
                Text('NOTE (OPTIONAL)', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Load GCash, savings transfer',
                    filled: true,
                    fillColor: palette.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: palette.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: palette.border),
                    ),
                  ),
                ),

                // Transfer Impact Preview
                if (transferAmount > 0 && sourceAccount != null && destAccount != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: palette.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: palette.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${sourceAccount.name} after:', style: const TextStyle(fontSize: 12)),
                            Text(
                              CurrencyFormatter.format(sourceBalance - transferAmount),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: (sourceBalance - transferAmount) < 0 ? palette.negative : palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${destAccount.name} after:', style: const TextStyle(fontSize: 12)),
                            Text(
                              CurrencyFormatter.format(destBalance + transferAmount),
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.positive),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Error Message
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: TextStyle(color: palette.negative, fontSize: 13, fontWeight: FontWeight.w500)),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Submit Button
                TactileBounce(
                  onTap: _isSubmitting ? null : () => _submitTransfer(accounts),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Confirm & Transfer',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountDropdown(
    BuildContext context, {
    required int? value,
    required List<Account> accounts,
    required ValueChanged<int?> onChanged,
  }) {
    final palette = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: accounts.map((acc) {
            return DropdownMenuItem<int>(
              value: acc.id,
              child: Row(
                children: [
                  Icon(
                    _iconForAccount(acc.type),
                    size: 18,
                    color: acc.color != null ? _parseColor(acc.color!) : palette.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      acc.name,
                      style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (acc.accountNumberMasked != null)
                    Text(
                      acc.accountNumberMasked!,
                      style: TextStyle(fontSize: 12, color: palette.textTertiary),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _quickChip(BuildContext context, double amount, {required String label}) {
    final palette = context.appColors;
    return TactileBounce(
      onTap: () => _applyQuickAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: palette.border),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textPrimary),
        ),
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

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }
}

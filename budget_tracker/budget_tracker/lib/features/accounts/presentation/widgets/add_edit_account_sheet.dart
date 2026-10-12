import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/entities/account.dart';
import '../../../../shared/domain/entities/enums.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import '../accounts_provider.dart';

class _InstitutionPreset {
  final String name;
  final String institution;
  final AccountType type;
  final String colorHex;
  final IconData icon;

  const _InstitutionPreset({
    required this.name,
    required this.institution,
    required this.type,
    required this.colorHex,
    required this.icon,
  });
}

const _kPresets = [
  _InstitutionPreset(
    name: 'GCash',
    institution: 'GCash',
    type: AccountType.digitalWallet,
    colorHex: '#007DFE',
    icon: Icons.account_balance_wallet_outlined,
  ),
  _InstitutionPreset(
    name: 'Maya',
    institution: 'Maya',
    type: AccountType.digitalWallet,
    colorHex: '#00D09C',
    icon: Icons.account_balance_wallet_outlined,
  ),
  _InstitutionPreset(
    name: 'ShopeePay',
    institution: 'ShopeePay',
    type: AccountType.digitalWallet,
    colorHex: '#EE4D2D',
    icon: Icons.shopping_bag_outlined,
  ),
  _InstitutionPreset(
    name: 'BDO Unibank',
    institution: 'BDO',
    type: AccountType.bank,
    colorHex: '#003366',
    icon: Icons.account_balance_outlined,
  ),
  _InstitutionPreset(
    name: 'BPI',
    institution: 'BPI',
    type: AccountType.bank,
    colorHex: '#B5121B',
    icon: Icons.account_balance_outlined,
  ),
  _InstitutionPreset(
    name: 'UnionBank',
    institution: 'UnionBank',
    type: AccountType.bank,
    colorHex: '#FF6E00',
    icon: Icons.account_balance_outlined,
  ),
  _InstitutionPreset(
    name: 'Metrobank',
    institution: 'Metrobank',
    type: AccountType.bank,
    colorHex: '#002D72',
    icon: Icons.account_balance_outlined,
  ),
  _InstitutionPreset(
    name: 'Physical Cash',
    institution: 'Cash',
    type: AccountType.cash,
    colorHex: '#10B981',
    icon: Icons.payments_outlined,
  ),
  _InstitutionPreset(
    name: 'Credit Card',
    institution: 'Credit Card',
    type: AccountType.creditCard,
    colorHex: '#6366F1',
    icon: Icons.credit_card_outlined,
  ),
];

class AddEditAccountSheet extends ConsumerStatefulWidget {
  final Account? initialAccount;

  const AddEditAccountSheet({super.key, this.initialAccount});

  static Future<void> show(BuildContext context, {Account? account}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditAccountSheet(initialAccount: account),
    );
  }

  @override
  ConsumerState<AddEditAccountSheet> createState() => _AddEditAccountSheetState();
}

class _AddEditAccountSheetState extends ConsumerState<AddEditAccountSheet> {
  final _nameController = TextEditingController();
  final _institutionController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _balanceController = TextEditingController();

  late AccountType _type;
  late String _selectedColorHex;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final acc = widget.initialAccount;
    if (acc != null) {
      _nameController.text = acc.name;
      _institutionController.text = acc.institutionName ?? '';
      _accountNumberController.text = acc.accountNumberMasked ?? '';
      _balanceController.text = acc.balance.toStringAsFixed(2);
      _type = acc.type;
      _selectedColorHex = acc.color ?? '#3B82F6';
    } else {
      _type = AccountType.digitalWallet;
      _selectedColorHex = '#007DFE';
      _balanceController.text = '0.00';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _accountNumberController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _applyPreset(_InstitutionPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _nameController.text = preset.name;
      _institutionController.text = preset.institution;
      _type = preset.type;
      _selectedColorHex = preset.colorHex;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Account name cannot be empty.');
      return;
    }

    final balance = double.tryParse(_balanceController.text.replaceAll(',', '').trim()) ?? 0.0;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      HapticFeedback.mediumImpact();
      if (widget.initialAccount != null) {
        final updated = widget.initialAccount!.copyWith(
          name: name,
          type: _type,
          institutionName: _institutionController.text.trim().isEmpty ? null : _institutionController.text.trim(),
          accountNumberMasked: _accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim(),
          color: _selectedColorHex,
        );
        await ref.read(accountsProvider.notifier).updateAccount(updated);
      } else {
        await ref.read(accountsProvider.notifier).createAccount(
              name: name,
              type: _type,
              initialBalance: balance,
              institutionName: _institutionController.text.trim().isEmpty ? null : _institutionController.text.trim(),
              accountNumberMasked: _accountNumberController.text.trim().isEmpty ? null : _accountNumberController.text.trim(),
              colorHex: _selectedColorHex,
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialAccount != null ? 'Account updated' : 'Account created successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Error saving account: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final isEditing = widget.initialAccount != null;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Edit Account' : 'Add New Account',
                  style: AppTypography.sectionHeader.copyWith(color: palette.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            if (!isEditing) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('POPULAR PRESETS', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _kPresets.map((preset) {
                    final isSelected = _institutionController.text == preset.institution;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: TactileBounce(
                        onTap: () => _applyPreset(preset),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? palette.primary : palette.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: isSelected ? palette.primary : palette.border),
                          ),
                          child: Row(
                            children: [
                              Icon(preset.icon, size: 14, color: isSelected ? Colors.white : palette.textPrimary),
                              const SizedBox(width: 4),
                              Text(
                                preset.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : palette.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Account Name
            Text('ACCOUNT NAME', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. GCash Main, BDO Savings',
                filled: true,
                fillColor: palette.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: palette.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: palette.border)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Account Type
            Text('ACCOUNT TYPE', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: palette.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: palette.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<AccountType>(
                  value: _type,
                  isExpanded: true,
                  items: AccountType.values.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(_labelForAccountType(t), style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (t) {
                    if (t != null) setState(() => _type = t);
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Starting Balance (Only when creating)
            if (!isEditing) ...[
              Text('STARTING BALANCE', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  hintText: '0.00',
                  filled: true,
                  fillColor: palette.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: palette.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: palette.border)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Masked Account Number
            Text('MASKED ACCOUNT NUMBER (OPTIONAL)', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _accountNumberController,
              decoration: InputDecoration(
                hintText: 'e.g. *8892',
                filled: true,
                fillColor: palette.surfaceVariant,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: palette.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide(color: palette.border)),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: TextStyle(color: palette.negative, fontSize: 13, fontWeight: FontWeight.w500)),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Submit Button
            TactileBounce(
              onTap: _isSaving ? null : _save,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        isEditing ? 'Save Changes' : 'Create Account',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForAccountType(AccountType type) => switch (type) {
        AccountType.cash => 'Physical Cash',
        AccountType.bank => 'Bank Account',
        AccountType.digitalWallet => 'E-Wallet (GCash, Maya)',
        AccountType.creditCard => 'Credit Card',
        AccountType.investment => 'Investment Account',
      };
}

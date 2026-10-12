import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/domain/entities/transaction.dart';
import '../../../../shared/domain/entities/enums.dart';
import '../../../../shared/domain/entities/category.dart';
import '../../../../shared/domain/entities/account.dart';
import '../../../../shared/presentation/providers/app_providers.dart';
import '../../../../shared/presentation/widgets/amount_input.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import '../../../accounts/presentation/accounts_provider.dart';
import '../../../categories/presentation/categories_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../ai_assistant/domain/maya_copilot_service.dart';
import '../providers/transactions_provider.dart';
import '../widgets/inline_budget_coaching_pill.dart';

/// Add/edit transaction screen (PRD wireframe 9.5).
/// Clean, card-based form eliminating raw dividers in favor of spatial visual rhythm.
class AddTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? initial;

  const AddTransactionScreen({super.key, this.initial});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  late TransactionType _type;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  int? _categoryId;
  int? _accountId;
  int? _destAccountId;
  bool _saving = false;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _type = t?.type ?? TransactionType.expense;
    _amountController.text = t != null ? t.amount.toStringAsFixed(0) : '';
    _descriptionController.text = t?.description ?? '';
    _notesController.text = t?.notes ?? '';
    _date = t?.date ?? DateTime.now();
    _categoryId = t?.categoryId;
    _accountId = t?.accountId;
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() => setState(() {});

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final budgetAsync = ref.watch(activeBudgetProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final calculator = ref.watch(financialCalculatorProvider);
    final palette = context.appColors;
    final isEditing = widget.initial != null;

    final rawAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    BudgetImpactResult? coachingImpact;

    if (_type == TransactionType.expense && rawAmount > 0) {
      final categories = categoriesAsync.valueOrNull ?? [];
      final category = categories.where((c) => c.id == _categoryId).firstOrNull;
      final categorySpent = _categoryId != null && transactionsAsync.hasValue
          ? calculator.calculateMonthlyExpenses(transactionsAsync.value!, DateTime.now(), categoryId: _categoryId)
          : 0.0;

      coachingImpact = MayaCopilotService.evaluateTransactionBudgetImpact(
        budgetState: budgetAsync.valueOrNull ?? const ActiveBudgetState(),
        categoryId: _categoryId,
        categoryName: category?.name,
        categorySpent: categorySpent,
        proposedAmount: rawAmount,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: palette.textSecondary, fontWeight: FontWeight.w600)),
        ),
        centerTitle: true,
        title: Text(
          isEditing ? 'Edit ${_typeLabel(_type)}' : 'New ${_typeLabel(_type)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Transaction Type Selector
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.expense, label: Text('Expense')),
                ButtonSegment(value: TransactionType.income, label: Text('Income')),
                ButtonSegment(value: TransactionType.transfer, label: Text('Transfer')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() {
                _type = s.first;
                _categoryId = null;
              }),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Amount Input Section
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AMOUNT',
                    style: AppTypography.caption.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AmountInput(controller: _amountController, errorText: _amountError),
                  InlineBudgetCoachingPill(
                    impact: coachingImpact,
                    isVisible: _type == TransactionType.expense && rawAmount > 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Classification & Account Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Selection (Optional for Transfer)
                  if (_type != TransactionType.transfer) ...[
                    Text(
                      'CATEGORY',
                      style: AppTypography.caption.copyWith(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    categoriesAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading categories: $e'),
                      data: (categories) {
                        final relevant = categories.where((c) => c.type.dbValue == _type.dbValue).toList();
                        final effective = relevant.isNotEmpty ? relevant : categories;
                        _categoryId ??= effective.isNotEmpty ? effective.first.id : null;
                        return _picker<Category>(
                          value: effective.where((c) => c.id == _categoryId).firstOrNull,
                          items: effective,
                          labelOf: (c) => c.name,
                          onSelect: (c) => setState(() => _categoryId = c.id),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // Account Selection
                  Text(
                    _type == TransactionType.transfer ? 'SOURCE ACCOUNT' : 'ACCOUNT',
                    style: AppTypography.caption.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  accountsAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error loading accounts: $e'),
                    data: (accounts) {
                      _accountId ??= accounts.isNotEmpty ? accounts.first.id : null;
                      return _picker<Account>(
                        value: accounts.where((a) => a.id == _accountId).firstOrNull,
                        items: accounts,
                        labelOf: (a) => a.name,
                        onSelect: (a) => setState(() => _accountId = a.id),
                      );
                    },
                  ),
                  if (_type == TransactionType.transfer) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'DESTINATION ACCOUNT',
                      style: AppTypography.caption.copyWith(
                        color: palette.textSecondary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    accountsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading accounts: $e'),
                      data: (accounts) {
                        _destAccountId ??= accounts.where((a) => a.id != _accountId).firstOrNull?.id;
                        return _picker<Account>(
                          value: accounts.where((a) => a.id == _destAccountId).firstOrNull,
                          items: accounts,
                          labelOf: (a) => a.name,
                          onSelect: (a) => setState(() => _destAccountId = a.id),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),

                  // Date Picker
                  Text(
                    'DATE',
                    style: AppTypography.caption.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat.yMMMd().format(_date), style: AppTypography.body),
                          Icon(Icons.calendar_today, size: 18, color: palette.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Description & Notes Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESCRIPTION & NOTES',
                    style: AppTypography.caption.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Lunch with team, Groceries',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Additional notes or transfer memo (optional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 5. Submit Button with Emil Kowalski press physics
            PrimaryButton(
              label: 'Save ${_typeLabel(_type)}',
              onPressed: _saving ? null : _save,
              isLoading: _saving,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _picker<T>({
    required T? value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T> onSelect,
  }) {
    final palette = context.appColors;
    return InkWell(
      onTap: items.isEmpty
          ? null
          : () async {
              final selected = await showModalBottomSheet<T>(
                context: context,
                backgroundColor: palette.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                ),
                builder: (ctx) => SafeArea(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    children: [
                      for (final item in items)
                        ListTile(
                          title: Text(labelOf(item), style: AppTypography.body),
                          onTap: () => Navigator.pop(ctx, item),
                        ),
                    ],
                  ),
                ),
              );
              if (selected != null) onSelect(selected);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value != null ? labelOf(value) : (items.isEmpty ? 'None available' : 'Select'),
                style: AppTypography.body),
            Icon(Icons.chevron_right, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Enter a valid amount');
      return;
    }

    final effectiveCategoryId = _categoryId;

    if (_type == TransactionType.transfer) {
      if (_destAccountId == null || _accountId == _destAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select two different accounts for transfer.')),
        );
        return;
      }
      setState(() {
        _saving = true;
        _amountError = null;
      });
      await ref.read(accountsProvider.notifier).transferFunds(
            sourceAccountId: _accountId!,
            destinationAccountId: _destAccountId!,
            amount: amount,
            note: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            date: _date,
          );
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_accountId == null || effectiveCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account and category.')),
      );
      return;
    }

    setState(() {
      _saving = true;
      _amountError = null;
    });

    final userId = ref.read(currentUserIdProvider);
    final now = DateTime.now();
    final transaction = Transaction(
      id: widget.initial?.id,
      userId: userId,
      accountId: _accountId!,
      categoryId: effectiveCategoryId,
      type: _type,
      amount: amount,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      date: _date,
      createdAt: widget.initial?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(transactionsProvider.notifier);
    if (widget.initial != null) {
      await notifier.updateTransaction(transaction);
    } else {
      await notifier.addTransaction(transaction);
    }

    if (mounted) Navigator.of(context).pop();
  }

  String _typeLabel(TransactionType type) => switch (type) {
        TransactionType.expense => 'Expense',
        TransactionType.income => 'Income',
        TransactionType.transfer => 'Transfer',
      };
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/presentation/providers/app_providers.dart';
import '../../../shared/presentation/widgets/financial_summary.dart';
import '../../../shared/presentation/widgets/budget_progress.dart';
import '../../../shared/presentation/widgets/insight_card.dart';
import '../../../shared/presentation/widgets/app_buttons.dart';
import '../../budgets/presentation/providers/budgets_provider.dart';
import '../../categories/presentation/categories_provider.dart';
import '../../transactions/presentation/providers/transactions_provider.dart';
import '../../transactions/presentation/screens/add_transaction_screen.dart';
import '../../accounts/presentation/accounts_provider.dart';
import '../../accounts/presentation/screens/accounts_screen.dart';
import '../../accounts/presentation/widgets/transfer_funds_sheet.dart';
import '../../analytics/presentation/screens/analytics_screen.dart';
import '../../ai_assistant/domain/maya_copilot_service.dart';
import 'widgets/maya_briefing_card.dart';

/// Home screen (PRD 9.3): scannable financial dashboard featuring
/// hero net balance, directional cash flow metrics, budget status,
/// category spending breakdown, and on-device AI insights.
class HomeScreen extends ConsumerWidget {
  final VoidCallback? onOpenAssistant;
  final VoidCallback? onOpenSettings;

  const HomeScreen({super.key, this.onOpenAssistant, this.onOpenSettings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final budgetAsync = ref.watch(activeBudgetProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final recurringAsync = ref.watch(recurringTransactionsProvider);
    final calculator = ref.watch(financialCalculatorProvider);
    final palette = context.appColors;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MayPeraPa', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(
              DateFormat('MMMM yyyy').format(now).toUpperCase(),
              style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.8),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: onOpenSettings,
            tooltip: 'Settings',
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn\'t load your data: $e')),
        data: (transactions) {
          final balance = calculator.calculateCurrentBalance(transactions);
          final income = calculator.calculateMonthlyIncome(transactions, now);
          final expenses = calculator.calculateMonthlyExpenses(transactions, now);
          final netCashFlow = income - expenses;
          final byCategory = calculator.calculateExpensesByCategory(transactions, now);
          final categories = categoriesAsync.valueOrNull ?? [];

          final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
          final daysRemaining = (lastDayOfMonth - now.day + 1).clamp(1, 31);
          final activeBudget = budgetAsync.valueOrNull?.budget;
          final budgetRemaining = activeBudget != null
              ? (budgetAsync.valueOrNull?.remaining ?? 0.0)
              : balance;
          final dailyAllowance = MayaCopilotService.calculateDailyAllowance(
            remainingBudget: budgetRemaining,
            daysRemainingInMonth: daysRemaining,
          );
          final upcomingBills = MayaCopilotService.findBillsDueWithin(
            recurringTransactions: recurringAsync.valueOrNull ?? const [],
            now: now,
            window: const Duration(hours: 72),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(transactionsProvider);
              ref.invalidate(accountsProvider);
              ref.invalidate(activeBudgetProvider);
              ref.invalidate(recurringTransactionsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              children: [
                // 1. Hero Total Balance Card
                _buildHeroBalanceCard(context, balance: balance, netCashFlow: netCashFlow),
                const SizedBox(height: AppSpacing.md),

                // 2. Maya Ambient Intelligence Briefing Card (Phase 3)
                MayaBriefingCard(
                  dailyAllowance: dailyAllowance,
                  daysRemainingInMonth: daysRemaining,
                  remainingBudget: budgetRemaining,
                  upcomingBills: upcomingBills,
                  onAskMaya: onOpenAssistant,
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Cashflow Split Cards (Inflow & Outflow)
                Row(
                  children: [
                    Expanded(
                      child: FinancialSummaryCard(
                        label: 'Monthly Inflow',
                        amount: income,
                        isPositive: true,
                        icon: Icons.south_west_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FinancialSummaryCard(
                        label: 'Monthly Outflow',
                        amount: expenses,
                        isPositive: false,
                        icon: Icons.north_east_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 3. Quick Action Bar
                Row(
                  children: [
                    Expanded(
                      child: TactileBounce(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Add',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: TactileBounce(
                        onTap: () => TransferFundsSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: palette.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: palette.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.swap_horiz, size: 16, color: palette.textPrimary),
                              const SizedBox(width: 4),
                              Text(
                                'Transfer',
                                style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (onOpenAssistant != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: TactileBounce(
                          onTap: onOpenAssistant,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: palette.surfaceVariant,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: palette.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_awesome, size: 15, color: palette.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Ask AI',
                                  style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // 4. Accounts & Wallets Preview Carousel
                accountsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (accounts) {
                    if (accounts.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ACCOUNTS & WALLETS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: palette.textTertiary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AccountsScreen()),
                              ),
                              child: Text(
                                'See all (${accounts.length})',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ...accounts.map((acc) {
                                final accBalance = calculator.calculateCurrentBalance(transactions, accountId: acc.id);
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                                  child: TactileBounce(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const AccountsScreen()),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: palette.surface,
                                        borderRadius: BorderRadius.circular(AppRadius.md),
                                        border: Border.all(color: palette.border),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(acc.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textSecondary)),
                                              if (acc.accountNumberMasked != null) ...[
                                                const SizedBox(width: 4),
                                                Text(acc.accountNumberMasked!, style: TextStyle(fontSize: 10, color: palette.textTertiary)),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.format(accBalance),
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: palette.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              TactileBounce(
                                onTap: () => TransferFundsSheet.show(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                                  decoration: BoxDecoration(
                                    color: palette.surfaceVariant,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(color: palette.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.swap_horiz, size: 16, color: palette.primary),
                                      const SizedBox(width: 4),
                                      Text('Transfer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.primary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                    );
                  },
                ),

                // 4. Budget Status Card
                budgetAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (budgetState) {
                    if (budgetState.budget == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: Container(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Active Budget', style: AppTypography.sectionHeading.copyWith(fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: (budgetState.spent > budgetState.budget!.totalBudget)
                                        ? palette.negativeLight
                                        : palette.positiveLight,
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    (budgetState.spent > budgetState.budget!.totalBudget)
                                        ? 'Exceeded'
                                        : 'Active',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: (budgetState.spent > budgetState.budget!.totalBudget)
                                          ? palette.negative
                                          : palette.positive,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            BudgetProgress(
                              label: budgetState.budget!.name,
                              spent: budgetState.spent,
                              budget: budgetState.budget!.totalBudget,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // 5. Category Spending Breakdown Card
                if (byCategory.isNotEmpty) ...[
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Spending by Category', style: AppTypography.sectionHeading.copyWith(fontSize: 15)),
                            GestureDetector(
                              onTap: () => AnalyticsScreen.push(context),
                              child: Row(
                                children: [
                                  Text(
                                    'Trends',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.primary),
                                  ),
                                  Icon(Icons.chevron_right, size: 14, color: palette.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ..._spendingOverviewRows(context, byCategory, categories, expenses),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // 6. AI Insight Card
                InsightCard(
                  title: 'AI Financial Insight',
                  message: byCategory.isEmpty
                      ? 'Add a few transactions and your local AI will surface spending habits and savings opportunities here.'
                      : 'You spent ${CurrencyFormatter.format(expenses)} this month. Ask the assistant: "How can I optimize my food budget?"',
                  actionLabel: 'Chat with AI',
                  onAction: onOpenAssistant,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroBalanceCard(
    BuildContext context, {
    required double balance,
    required double netCashFlow,
  }) {
    final palette = context.appColors;
    final isFlowPositive = netCashFlow >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL AVAILABLE BALANCE',
                style: AppTypography.caption.copyWith(
                  color: palette.textSecondary,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TactileBounce(
                    onTap: () => AnalyticsScreen.push(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insights, size: 12, color: palette.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Analytics',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  TactileBounce(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AccountsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: palette.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: palette.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 12, color: palette.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Accounts',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.primary),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.chevron_right, size: 14, color: palette.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CurrencyFormatter.format(balance),
            style: AppTypography.primaryValue.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFlowPositive ? palette.positiveLight : palette.negativeLight,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFlowPositive ? Icons.trending_up : Icons.trending_down,
                      size: 13,
                      color: isFlowPositive ? palette.positive : palette.negative,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${isFlowPositive ? "+" : ""}${CurrencyFormatter.format(netCashFlow)} net this month',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isFlowPositive ? palette.positive : palette.negative,
                      ),
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

  List<Widget> _spendingOverviewRows(
    BuildContext context,
    Map<int, double> byCategory,
    List categories,
    double totalExpenses,
  ) {
    final palette = context.appColors;
    final entries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).map((e) {
      final category = categories.where((c) => c.id == e.key).firstOrNull;
      final name = category?.name ?? 'Category #${e.key}';
      final fraction = totalExpenses <= 0 ? 0.0 : (e.value / totalExpenses).clamp(0.0, 1.0);
      final percentage = (fraction * 100).toStringAsFixed(0);

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(name, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(width: AppSpacing.xs),
                    Text('($percentage%)', style: AppTypography.caption.copyWith(color: palette.textTertiary)),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(e.value),
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: palette.surfaceVariant,
                valueColor: AlwaysStoppedAnimation(palette.primary),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

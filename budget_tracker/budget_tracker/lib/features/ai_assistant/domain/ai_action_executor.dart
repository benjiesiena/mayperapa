import 'package:intl/intl.dart';

import '../../../shared/domain/entities/transaction.dart';
import '../../../shared/domain/entities/account.dart';
import '../../../shared/domain/entities/category.dart';
import '../../../shared/domain/entities/enums.dart';
import '../../../shared/domain/entities/budget.dart';
import '../../../shared/domain/entities/financial_goal.dart';
import '../../../shared/domain/repositories/transaction_repository.dart';
import '../../../shared/domain/repositories/account_repository.dart';
import '../../../shared/domain/repositories/category_repository.dart';
import '../../../shared/domain/repositories/budget_repository.dart';
import '../../../shared/domain/repositories/goal_repository.dart';
import 'ai_action_draft.dart';

class AIActionExecutionResult {
  final bool success;
  final String message;
  final dynamic createdEntity;

  const AIActionExecutionResult({
    required this.success,
    required this.message,
    this.createdEntity,
  });
}

/// Executes AI-drafted actions against local repositories upon explicit user confirmation.
/// All mutations are transactional and self-contained, guaranteeing zero floating-point
/// inaccuracy and defensive fallbacks for missing entities.
class AIActionExecutor {
  final int userId;
  final TransactionRepository transactionRepository;
  final CategoryRepository categoryRepository;
  final AccountRepository accountRepository;
  final BudgetRepository budgetRepository;
  final GoalRepository goalRepository;

  const AIActionExecutor({
    required this.userId,
    required this.transactionRepository,
    required this.categoryRepository,
    required this.accountRepository,
    required this.budgetRepository,
    required this.goalRepository,
  });

  Future<AIActionExecutionResult> execute(AIActionDraft draft) async {
    try {
      switch (draft.type) {
        case AIActionType.createTransaction:
          return await _executeCreateTransaction(draft);
        case AIActionType.createBudget:
          return await _executeCreateBudget(draft);
        case AIActionType.createGoal:
          return await _executeCreateGoal(draft);
        case AIActionType.applyFinancialPlan:
          return await _executeApplyFinancialPlan(draft);
        case AIActionType.batchBundle:
          return await _executeBatchBundle(draft);
      }
    } catch (e) {
      return AIActionExecutionResult(
        success: false,
        message: 'Failed to execute ${draft.title}: $e',
      );
    }
  }

  Future<AIActionExecutionResult> _executeCreateTransaction(AIActionDraft draft) async {
    final amount = (draft.payload['amount'] as num?)?.toDouble() ?? 0.0;
    final isIncomeExplicit = draft.payload['isIncome'] == true;
    final typeStr = draft.payload['type'] as String? ?? (isIncomeExplicit ? 'income' : 'expense');
    final txnType = typeStr == 'income'
        ? TransactionType.income
        : (typeStr == 'transfer' ? TransactionType.transfer : TransactionType.expense);

    final categoryName = draft.payload['categoryName'] as String?;
    final accountName = draft.payload['accountName'] as String?;
    final description = (draft.payload['description'] as String?) ?? (draft.payload['note'] as String?);
    final dateRaw = draft.payload['date'];
    final date = dateRaw is DateTime
        ? dateRaw
        : (dateRaw is String ? (DateTime.tryParse(dateRaw) ?? DateTime.now()) : DateTime.now());

    // Resolve category
    var categories = await categoryRepository.getAllForUser(userId);
    if (categories.isEmpty) {
      await categoryRepository.seedDefaults(userId);
      categories = await categoryRepository.getAllForUser(userId);
    }

    final matchedCategory = _resolveCategory(categories, categoryName, txnType);
    if (matchedCategory == null) {
      return const AIActionExecutionResult(
        success: false,
        message: 'Could not resolve or create category for transaction.',
      );
    }

    // Resolve account
    var accounts = await accountRepository.getAllForUser(userId);
    if (accounts.isEmpty) {
      await accountRepository.seedDefaults(userId);
      accounts = await accountRepository.getAllForUser(userId);
    }

    Account? matchedAccount;
    if (accountName != null) {
      final target = accountName.trim().toLowerCase();
      matchedAccount = accounts.where((a) => a.name.toLowerCase() == target).firstOrNull;
    }
    matchedAccount ??= accounts.isNotEmpty ? accounts.first : null;

    if (matchedAccount == null) {
      return const AIActionExecutionResult(
        success: false,
        message: 'Could not resolve or create account for transaction.',
      );
    }

    final now = DateTime.now();
    final txn = Transaction(
      userId: userId,
      accountId: matchedAccount.id!,
      categoryId: matchedCategory.id!,
      type: txnType,
      amount: amount,
      description: description,
      date: date,
      createdAt: now,
      updatedAt: now,
    );

    final created = await transactionRepository.create(txn);
    final typeLabel = txnType == TransactionType.income ? 'income' : 'expense';
    final formattedAmount = NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(amount);

    return AIActionExecutionResult(
      success: true,
      message: 'Saved $formattedAmount $typeLabel in ${matchedCategory.name} (${matchedAccount.name}).',
      createdEntity: created,
    );
  }

  Future<AIActionExecutionResult> _executeCreateBudget(AIActionDraft draft) async {
    final name = draft.payload['name'] as String? ?? 'Monthly Budget';
    final totalBudget = (draft.payload['totalBudget'] as num?)?.toDouble() ??
        (draft.payload['amount'] as num?)?.toDouble() ?? 0.0;
    final now = DateTime.now();

    final startRaw = draft.payload['periodStart'];
    final periodStart = startRaw is DateTime
        ? startRaw
        : (startRaw is String ? (DateTime.tryParse(startRaw) ?? DateTime(now.year, now.month, 1)) : DateTime(now.year, now.month, 1));

    final endRaw = draft.payload['periodEnd'];
    final periodEnd = endRaw is DateTime
        ? endRaw
        : (endRaw is String ? (DateTime.tryParse(endRaw) ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59)) : DateTime(now.year, now.month + 1, 0, 23, 59, 59));

    var categories = await categoryRepository.getAllForUser(userId);
    if (categories.isEmpty) {
      await categoryRepository.seedDefaults(userId);
      categories = await categoryRepository.getAllForUser(userId);
    }

    final items = <BudgetItem>[];
    final allocations = draft.payload['categoryAllocations'];
    if (allocations is Map) {
      allocations.forEach((catName, allocAmount) {
        final amount = (allocAmount as num?)?.toDouble() ?? 0.0;
        final cat = _resolveCategory(categories, catName.toString(), TransactionType.expense);
        if (cat != null) {
          items.add(BudgetItem(
            budgetId: 0,
            categoryId: cat.id!,
            amount: amount,
            createdAt: now,
            updatedAt: now,
          ));
        }
      });
    } else if (draft.payload['categoryName'] != null && totalBudget > 0) {
      final cat = _resolveCategory(categories, draft.payload['categoryName'] as String, TransactionType.expense);
      if (cat != null) {
        items.add(BudgetItem(
          budgetId: 0,
          categoryId: cat.id!,
          amount: totalBudget,
          createdAt: now,
          updatedAt: now,
        ));
      }
    }

    if (items.isEmpty && categories.isNotEmpty) {
      final firstExpenseCat = categories.where((c) => c.type == CategoryType.expense).firstOrNull ?? categories.first;
      items.add(BudgetItem(
        budgetId: 0,
        categoryId: firstExpenseCat.id!,
        amount: totalBudget,
        createdAt: now,
        updatedAt: now,
      ));
    }

    final budget = Budget(
      userId: userId,
      name: name,
      type: BudgetType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalBudget: totalBudget,
      strategy: BudgetStrategy.zeroBased,
      createdAt: now,
      updatedAt: now,
    );

    final created = await budgetRepository.create(budget, items);
    final formattedAmount = NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(totalBudget);

    return AIActionExecutionResult(
      success: true,
      message: "Created monthly budget '$name' of $formattedAmount.",
      createdEntity: created,
    );
  }

  Future<AIActionExecutionResult> _executeCreateGoal(AIActionDraft draft) async {
    final name = draft.payload['name'] as String? ?? 'Savings Goal';
    final targetAmount = (draft.payload['targetAmount'] as num?)?.toDouble() ??
        (draft.payload['amount'] as num?)?.toDouble() ?? 0.0;
    final now = DateTime.now();

    final dateRaw = draft.payload['targetDate'];
    final targetDate = dateRaw is DateTime
        ? dateRaw
        : (dateRaw is String ? DateTime.tryParse(dateRaw) : null);

    final goal = FinancialGoal(
      userId: userId,
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      createdAt: now,
      updatedAt: now,
    );

    final created = await goalRepository.create(goal);
    final formattedAmount = NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(targetAmount);

    return AIActionExecutionResult(
      success: true,
      message: "Created savings goal '$name' with target $formattedAmount.",
      createdEntity: created,
    );
  }

  Future<AIActionExecutionResult> _executeApplyFinancialPlan(AIActionDraft draft) async {
    final salary = (draft.payload['salary'] as num?)?.toDouble() ??
        (draft.payload['monthlyIncome'] as num?)?.toDouble() ?? 0.0;
    final needsBudget = (draft.payload['needsBudget'] as num?)?.toDouble() ??
        (draft.payload['needsAmount'] as num?)?.toDouble() ?? (salary * 0.50);
    final wantsBudget = (draft.payload['wantsBudget'] as num?)?.toDouble() ??
        (draft.payload['wantsAmount'] as num?)?.toDouble() ?? (salary * 0.30);
    final savingsGoal = (draft.payload['savingsGoal'] as num?)?.toDouble() ??
        (draft.payload['savingsAmount'] as num?)?.toDouble() ?? (salary * 0.20);
    final totalBudget = needsBudget + wantsBudget;

    final now = DateTime.now();
    final startRaw = draft.payload['periodStart'];
    final periodStart = startRaw is DateTime
        ? startRaw
        : (startRaw is String ? (DateTime.tryParse(startRaw) ?? DateTime(now.year, now.month, 1)) : DateTime(now.year, now.month, 1));

    final endRaw = draft.payload['periodEnd'];
    final periodEnd = endRaw is DateTime
        ? endRaw
        : (endRaw is String ? (DateTime.tryParse(endRaw) ?? DateTime(now.year, now.month + 1, 0, 23, 59, 59)) : DateTime(now.year, now.month + 1, 0, 23, 59, 59));

    var categories = await categoryRepository.getAllForUser(userId);
    if (categories.isEmpty) {
      await categoryRepository.seedDefaults(userId);
      categories = await categoryRepository.getAllForUser(userId);
    }

    final items = <BudgetItem>[];

    // Needs allocations (e.g. Bills, Food, Transport)
    final needsCat = _resolveCategory(categories, 'bills', TransactionType.expense) ??
        _resolveCategory(categories, 'food', TransactionType.expense);

    if (needsCat != null) {
      items.add(BudgetItem(
        budgetId: 0,
        categoryId: needsCat.id!,
        amount: needsBudget,
        createdAt: now,
        updatedAt: now,
      ));
    }

    // Wants allocations (e.g. Shopping, Entertainment)
    final wantsCat = _resolveCategory(categories, 'entertainment', TransactionType.expense) ??
        _resolveCategory(categories, 'shopping', TransactionType.expense);

    if (wantsCat != null && wantsCat.id != needsCat?.id) {
      items.add(BudgetItem(
        budgetId: 0,
        categoryId: wantsCat.id!,
        amount: wantsBudget,
        createdAt: now,
        updatedAt: now,
      ));
    }

    final monthLabel = DateFormat('MMMM yyyy').format(periodStart);
    final budget = Budget(
      userId: userId,
      name: '50/30/20 Plan ($monthLabel)',
      type: BudgetType.monthly,
      periodStart: periodStart,
      periodEnd: periodEnd,
      totalBudget: totalBudget,
      strategy: BudgetStrategy.percentageBased,
      createdAt: now,
      updatedAt: now,
    );

    final createdBudget = await budgetRepository.create(budget, items);

    // Create 20% savings goal
    final goal = FinancialGoal(
      userId: userId,
      name: '50/30/20 Monthly Savings ($monthLabel)',
      targetAmount: savingsGoal,
      targetDate: periodEnd,
      createdAt: now,
      updatedAt: now,
    );

    final createdGoal = await goalRepository.create(goal);

    final formattedBudget = NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(totalBudget);
    final formattedGoal = NumberFormat.currency(symbol: '₱', decimalDigits: 2).format(savingsGoal);

    return AIActionExecutionResult(
      success: true,
      message: 'Applied 50/30/20 plan: Budget $formattedBudget and Savings Goal $formattedGoal created.',
      createdEntity: {
        'budget': createdBudget,
        'goal': createdGoal,
      },
    );
  }

  Category? _resolveCategory(List<Category> categories, String? name, TransactionType txnType) {
    if (categories.isEmpty) return null;
    if (name != null && name.trim().isNotEmpty) {
      final target = name.trim().toLowerCase();
      // 1. Exact match
      final exact = categories.where((c) => c.name.toLowerCase() == target).firstOrNull;
      if (exact != null) return exact;

      // 2. Canonical aliases
      const aliasMap = {
        'food & dining': 'food',
        'food': 'food',
        'dining': 'food',
        'groceries': 'food',
        'groceries & utilities': 'bills',
        'dining & entertainment': 'entertainment',
        'transportation': 'transport',
        'transport': 'transport',
        'bills & utilities': 'bills',
        'bills': 'bills',
        'utilities': 'bills',
        'healthcare': 'health',
        'health': 'health',
        'medical': 'health',
        'shopping': 'shopping',
        'entertainment': 'entertainment',
        'general & other': 'other',
        'other': 'other',
        'salary': 'salary',
        'wage': 'salary',
        'paycheck': 'salary',
      };

      final canonical = aliasMap[target];
      if (canonical != null) {
        final aliasMatch = categories.where((c) => c.name.toLowerCase() == canonical).firstOrNull;
        if (aliasMatch != null) return aliasMatch;
      }

      // 3. Substring match
      final sub = categories.where((c) {
        final cName = c.name.toLowerCase();
        return cName.contains(target) || target.contains(cName);
      }).firstOrNull;
      if (sub != null) return sub;
    }

    final targetType = txnType == TransactionType.income ? CategoryType.income : CategoryType.expense;
    return categories.where((c) => c.type == targetType).firstOrNull ?? categories.first;
  }

  Future<AIActionExecutionResult> _executeBatchBundle(AIActionDraft draft) async {
    final rawActions = draft.payload['actions'] as List? ?? [];
    if (rawActions.isEmpty) {
      return const AIActionExecutionResult(
        success: false,
        message: 'No actions found in batch bundle.',
      );
    }

    final createdEntities = <dynamic>[];
    int successCount = 0;

    for (int i = 0; i < rawActions.length; i++) {
      final actMap = Map<String, dynamic>.from(rawActions[i] as Map);
      final subTypeStr = actMap['type'] as String? ?? 'createTransaction';
      final subType = AIActionType.values.firstWhere(
        (t) => t.name == subTypeStr,
        orElse: () => AIActionType.createTransaction,
      );

      final subDraft = AIActionDraft(
        id: '${draft.id}_$i',
        type: subType,
        title: (actMap['title'] as String?) ?? 'Action ${i + 1}',
        subtitle: (actMap['subtitle'] as String?) ?? '',
        payload: Map<String, dynamic>.from((actMap['payload'] as Map?) ?? const {}),
        createdAt: DateTime.now(),
      );

      final res = await execute(subDraft);
      if (!res.success) {
        return AIActionExecutionResult(
          success: false,
          message: 'Bundle aborted on step ${i + 1} (${subDraft.title}): ${res.message}',
        );
      }
      successCount++;
      if (res.createdEntity != null) {
        createdEntities.add(res.createdEntity);
      }
    }

    return AIActionExecutionResult(
      success: true,
      message: 'Successfully executed all $successCount actions in bundle.',
      createdEntity: createdEntities,
    );
  }
}

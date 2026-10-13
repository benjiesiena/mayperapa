import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/domain/entities/account.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/budget.dart';
import 'package:mayperapa/shared/domain/entities/financial_goal.dart';
import 'package:mayperapa/shared/domain/entities/recurring_transaction.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/repositories/transaction_repository.dart';
import 'package:mayperapa/shared/domain/repositories/account_repository.dart';
import 'package:mayperapa/shared/domain/repositories/category_repository.dart';
import 'package:mayperapa/shared/domain/repositories/budget_repository.dart';
import 'package:mayperapa/shared/domain/repositories/goal_repository.dart';
import 'package:mayperapa/shared/domain/repositories/recurring_transaction_repository.dart';
import 'package:mayperapa/infrastructure/ai/tools/financial_tools_registry.dart';
import 'package:mayperapa/infrastructure/ai/tools/ai_tool.dart';

/// Minimal in-memory fakes. Kept in this test file (not shared/test-utils)
/// since they're intentionally the simplest possible implementation of each
/// interface — exactly what a tool-level unit test needs and nothing more.

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> data;
  FakeTransactionRepository(this.data);

  @override
  Future<Transaction> create(Transaction t) async => t;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<Transaction>> getAllForUser(int userId) async => data;
  @override
  Future<Transaction?> getById(int id) async => null;
  @override
  Future<List<Transaction>> search(int userId, String query) async =>
      data.where((t) => (t.description ?? '').contains(query)).toList();
  @override
  Future<Transaction> update(Transaction t) async => t;
}

class FakeAccountRepository implements AccountRepository {
  @override
  Future<Account> create(Account a) async => a;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<Account>> getAllForUser(int userId, {bool activeOnly = true}) async => [];
  @override
  Future<Account?> getById(int id) async => null;
  @override
  Future<Account> update(Account a) async => a;
  @override
  Future<void> seedDefaults(int userId, {String currencyCode = 'PHP'}) async {}
}

class FakeBudgetRepository implements BudgetRepository {
  Budget? active;
  List<BudgetItem> items = [];
  FakeBudgetRepository({this.active});

  @override
  Future<Budget> create(Budget b, List<BudgetItem> i) async => b;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<Budget?> getActiveForDate(int userId, DateTime date) async => active;
  @override
  Future<List<Budget>> getAllForUser(int userId) async => active != null ? [active!] : [];
  @override
  Future<List<BudgetItem>> getItemsForBudget(int budgetId) async => items;
  @override
  Future<Budget> update(Budget b) async => b;
  @override
  Future<BudgetItem> upsertItem(BudgetItem item) async => item;
}

class FakeGoalRepository implements GoalRepository {
  final List<FinancialGoal> data;
  FakeGoalRepository(this.data);

  @override
  Future<FinancialGoal> create(FinancialGoal g) async => g;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<FinancialGoal>> getAllForUser(int userId, {bool activeOnly = true}) async => data;
  @override
  Future<FinancialGoal?> getById(int id) async {
    final matches = data.where((g) => g.id == id);
    return matches.isEmpty ? null : matches.first;
  }
  @override
  Future<FinancialGoal> update(FinancialGoal g) async => g;
}

class FakeRecurringRepository implements RecurringTransactionRepository {
  final List<RecurringTransaction> data;
  FakeRecurringRepository(this.data);

  @override
  Future<RecurringTransaction> create(RecurringTransaction r) async => r;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<RecurringTransaction>> getAllForUser(int userId, {bool activeOnly = true}) async => data;
  @override
  Future<RecurringTransaction> update(RecurringTransaction r) async => r;
}

class FakeCategoryRepository implements CategoryRepository {
  final List<Category> data;
  FakeCategoryRepository(this.data);

  @override
  Future<Category> create(Category c) async => c;
  @override
  Future<void> delete(int id) async {}
  @override
  Future<List<Category>> getAllForUser(int userId, {bool activeOnly = true}) async => data;
  @override
  Future<Category?> getById(int id) async =>
      data.where((c) => c.id == id).firstOrNull;
  @override
  Future<void> seedDefaults(int userId) async {}
  @override
  Future<Category> update(Category c) async => c;
}

AITool _find(List<AITool> tools, String name) => tools.firstWhere((t) => t.name == name);

void main() {
  group('get_current_balance', () {
    test('fails gracefully instead of fabricating a number when there is no data', () async {
      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository([]),
        accountRepository: FakeAccountRepository(),
        budgetRepository: FakeBudgetRepository(),
        goalRepository: FakeGoalRepository([]),
        recurringRepository: FakeRecurringRepository([]),
      );

      final result = await _find(registry.buildTools(), 'get_current_balance').execute({});
      expect(result.success, isFalse);
      expect(result.error, contains('No transactions'));
    });

    test('returns the exact sum the calculator would produce', () async {
      final txns = [
        Transaction(
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.income,
          amount: 45000,
          date: DateTime(2026, 8, 1),
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 1),
        ),
        Transaction(
          userId: 1,
          accountId: 1,
          categoryId: 2,
          type: TransactionType.expense,
          amount: 20420,
          date: DateTime(2026, 8, 10),
          createdAt: DateTime(2026, 8, 10),
          updatedAt: DateTime(2026, 8, 10),
        ),
      ];
      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository(txns),
        accountRepository: FakeAccountRepository(),
        budgetRepository: FakeBudgetRepository(),
        goalRepository: FakeGoalRepository([]),
        recurringRepository: FakeRecurringRepository([]),
      );

      final result = await _find(registry.buildTools(), 'get_current_balance').execute({});
      expect(result.success, isTrue);
      expect(result.data['balance'], 24580);
    });
  });

  group('calculate_affordable_spending', () {
    test('requires proposedAmount/startDate/endDate rather than guessing them', () async {
      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository([]),
        accountRepository: FakeAccountRepository(),
        budgetRepository: FakeBudgetRepository(),
        goalRepository: FakeGoalRepository([]),
        recurringRepository: FakeRecurringRepository([]),
      );

      final result = await _find(registry.buildTools(), 'calculate_affordable_spending').execute({});
      expect(result.success, isFalse);
    });
  });

  group('get_budget_status', () {
    test('reports over-budget correctly rather than clamping to 100%', () async {
      final budget = Budget(
        id: 1,
        userId: 1,
        name: 'August',
        type: BudgetType.monthly,
        periodStart: DateTime(2026, 8, 1),
        periodEnd: DateTime(2026, 8, 31),
        totalBudget: 1000,
        strategy: BudgetStrategy.zeroBased,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      );
      final txns = [
        Transaction(
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 1500,
          date: DateTime(2026, 8, 10),
          createdAt: DateTime(2026, 8, 10),
          updatedAt: DateTime(2026, 8, 10),
        ),
      ];
      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository(txns),
        accountRepository: FakeAccountRepository(),
        budgetRepository: FakeBudgetRepository(active: budget),
        goalRepository: FakeGoalRepository([]),
        recurringRepository: FakeRecurringRepository([]),
      );

      final result = await _find(registry.buildTools(), 'get_budget_status').execute({'month': '2026-08-15'});
      expect(result.data['percentUsed'], greaterThan(1.0));
      expect(result.data['remaining'], -500);
    });
  });

  group('simulate_financial_scenario', () {
    test('simulates proposed purchase and expense cut against goal', () async {
      final goal = FinancialGoal(
        id: 1,
        userId: 1,
        name: 'House Downpayment',
        targetAmount: 100000,
        currentAmount: 40000,
        targetDate: DateTime(2028, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final txns = [
        Transaction(
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.income,
          amount: 50000,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Transaction(
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 30000,
          date: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository(txns),
        accountRepository: FakeAccountRepository(),
        budgetRepository: FakeBudgetRepository(),
        goalRepository: FakeGoalRepository([goal]),
        recurringRepository: FakeRecurringRepository([]),
      );

      final result = await _find(registry.buildTools(), 'simulate_financial_scenario').execute({
        'expenseCut': 5000,
        'proposedPurchase': 10000,
        'targetGoalName': 'House',
      });

      expect(result.success, isTrue);
      expect(result.data['proposedPurchaseAmount'], equals(10000.0));
      expect(result.data['monthlyExpenseCut'], equals(5000.0));
      expect(result.data['canAffordPurchase'], isTrue);
      expect(result.data['goalName'], equals('House Downpayment'));
      expect(result.data['monthsSaved'], greaterThan(0));
    });

    test('rebalance_budget_allocations detects deficit and proposes transfer from discretionary category', () async {
      final now = DateTime.now();
      final budget = Budget(
        id: 1,
        userId: 1,
        name: 'October 2026',
        type: BudgetType.monthly,
        periodStart: DateTime(now.year, now.month, 1),
        periodEnd: DateTime(now.year, now.month + 1, 0),
        totalBudget: 15000,
        strategy: BudgetStrategy.zeroBased,
        createdAt: now,
        updatedAt: now,
      );

      final items = [
        BudgetItem(id: 1, budgetId: 1, categoryId: 1, amount: 8000, createdAt: now, updatedAt: now), // Groceries
        BudgetItem(id: 2, budgetId: 1, categoryId: 2, amount: 7000, createdAt: now, updatedAt: now), // Dining Out
      ];

      final categories = [
        Category(id: 1, userId: 1, name: 'Groceries', type: CategoryType.expense, icon: 'groceries', color: '#00FF00', isDefault: true, createdAt: now, updatedAt: now),
        Category(id: 2, userId: 1, name: 'Dining Out', type: CategoryType.expense, icon: 'dining', color: '#FF0000', isDefault: true, createdAt: now, updatedAt: now),
      ];

      final txns = [
        // ₱9,500 in Groceries -> ₱1,500 deficit
        Transaction(userId: 1, accountId: 1, categoryId: 1, type: TransactionType.expense, amount: 9500, date: now, createdAt: now, updatedAt: now),
        // ₱2,000 in Dining Out -> ₱5,000 surplus
        Transaction(userId: 1, accountId: 1, categoryId: 2, type: TransactionType.expense, amount: 2000, date: now, createdAt: now, updatedAt: now),
      ];

      final budgetRepo = FakeBudgetRepository(active: budget)..items = items;
      final registry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: FakeTransactionRepository(txns),
        accountRepository: FakeAccountRepository(),
        budgetRepository: budgetRepo,
        goalRepository: FakeGoalRepository([]),
        recurringRepository: FakeRecurringRepository([]),
        categoryRepository: FakeCategoryRepository(categories),
      );

      final result = await _find(registry.buildTools(), 'rebalance_budget_allocations').execute({
        'month': now.toIso8601String(),
      });

      expect(result.success, isTrue);
      expect(result.data['isRebalanceNeeded'], isTrue);
      expect(result.data['totalDeficit'], equals(1500.0));
      final transfers = result.data['transfers'] as List;
      expect(transfers, isNotEmpty);
      expect(transfers.first['from'], equals('Dining Out'));
      expect(transfers.first['to'], equals('Groceries'));
      expect(transfers.first['amount'], equals(1500.0));
    });
  });
}

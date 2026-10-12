import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/domain/entities/account.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/budget.dart';
import 'package:mayperapa/shared/domain/entities/financial_goal.dart';
import 'package:mayperapa/shared/domain/repositories/transaction_repository.dart';
import 'package:mayperapa/shared/domain/repositories/account_repository.dart';
import 'package:mayperapa/shared/domain/repositories/category_repository.dart';
import 'package:mayperapa/shared/domain/repositories/budget_repository.dart';
import 'package:mayperapa/shared/domain/repositories/goal_repository.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_draft.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_executor.dart';

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> created = [];

  @override
  Future<Transaction> create(Transaction transaction) async {
    final item = transaction.copyWith(id: created.length + 1);
    created.add(item);
    return item;
  }

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<Transaction>> getAllForUser(int userId) async => created;

  @override
  Future<Transaction?> getById(int id) async =>
      created.cast<Transaction?>().firstWhere((t) => t?.id == id, orElse: () => null);

  @override
  Future<List<Transaction>> search(int userId, String query) async => [];

  @override
  Future<Transaction> update(Transaction transaction) async => transaction;
}

class FakeCategoryRepository implements CategoryRepository {
  List<Category> categories = [
    Category(
      id: 1,
      userId: 1,
      name: 'Food',
      type: CategoryType.expense,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    Category(
      id: 2,
      userId: 1,
      name: 'Bills',
      type: CategoryType.expense,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    Category(
      id: 3,
      userId: 1,
      name: 'Salary',
      type: CategoryType.income,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<Category> create(Category category) async => category;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<Category>> getAllForUser(int userId, {bool activeOnly = true}) async => categories;

  @override
  Future<Category?> getById(int id) async => null;

  @override
  Future<void> seedDefaults(int userId) async {}

  @override
  Future<Category> update(Category category) async => category;
}

class FakeAccountRepository implements AccountRepository {
  List<Account> accounts = [
    Account(
      id: 10,
      userId: 1,
      name: 'Cash',
      type: AccountType.cash,
      currencyCode: 'PHP',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
    Account(
      id: 20,
      userId: 1,
      name: 'Bank',
      type: AccountType.bank,
      currencyCode: 'PHP',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  Future<Account> create(Account account) async => account;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<Account>> getAllForUser(int userId, {bool activeOnly = true}) async => accounts;

  @override
  Future<Account?> getById(int id) async => null;

  @override
  Future<void> seedDefaults(int userId, {String currencyCode = 'PHP'}) async {}

  @override
  Future<Account> update(Account account) async => account;
}

class FakeBudgetRepository implements BudgetRepository {
  final List<Budget> createdBudgets = [];
  final List<BudgetItem> createdItems = [];

  @override
  Future<Budget> create(Budget budget, List<BudgetItem> items) async {
    final b = budget.copyWith(id: createdBudgets.length + 1);
    createdBudgets.add(b);
    createdItems.addAll(items);
    return b;
  }

  @override
  Future<void> delete(int id) async {}

  @override
  Future<Budget?> getActiveForDate(int userId, DateTime date) async => null;

  @override
  Future<List<Budget>> getAllForUser(int userId) async => createdBudgets;

  @override
  Future<List<BudgetItem>> getItemsForBudget(int budgetId) async => createdItems;

  @override
  Future<Budget> update(Budget budget) async => budget;

  @override
  Future<BudgetItem> upsertItem(BudgetItem item) async => item;
}

class FakeGoalRepository implements GoalRepository {
  final List<FinancialGoal> createdGoals = [];

  @override
  Future<FinancialGoal> create(FinancialGoal goal) async {
    final g = goal.copyWith(id: createdGoals.length + 1);
    createdGoals.add(g);
    return g;
  }

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<FinancialGoal>> getAllForUser(int userId, {bool activeOnly = true}) async => createdGoals;

  @override
  Future<FinancialGoal?> getById(int id) async => null;

  @override
  Future<FinancialGoal> update(FinancialGoal goal) async => goal;
}

void main() {
  late FakeTransactionRepository txnRepo;
  late FakeCategoryRepository categoryRepo;
  late FakeAccountRepository accountRepo;
  late FakeBudgetRepository budgetRepo;
  late FakeGoalRepository goalRepo;
  late AIActionExecutor executor;

  setUp(() {
    txnRepo = FakeTransactionRepository();
    categoryRepo = FakeCategoryRepository();
    accountRepo = FakeAccountRepository();
    budgetRepo = FakeBudgetRepository();
    goalRepo = FakeGoalRepository();

    executor = AIActionExecutor(
      userId: 1,
      transactionRepository: txnRepo,
      categoryRepository: categoryRepo,
      accountRepository: accountRepo,
      budgetRepository: budgetRepo,
      goalRepository: goalRepo,
    );
  });

  group('AIActionExecutor', () {
    test('executes createTransaction with resolved category and account', () async {
      final draft = AIActionDraft(
        id: 'draft-1',
        type: AIActionType.createTransaction,
        title: 'Add Expense: ₱150.00',
        subtitle: 'Food · Cash · coffee',
        payload: const {
          'amount': 150.0,
          'type': 'expense',
          'categoryName': 'Food',
          'accountName': 'Cash',
          'description': 'coffee',
          'date': '2026-10-05T12:00:00.000',
        },
        createdAt: DateTime.now(),
      );

      final result = await executor.execute(draft);

      expect(result.success, isTrue);
      expect(result.message, contains('150.00'));
      expect(txnRepo.created.length, 1);
      final created = txnRepo.created.first;
      expect(created.amount, 150.0);
      expect(created.type, TransactionType.expense);
      expect(created.categoryId, 1); // Food
      expect(created.accountId, 10); // Cash
      expect(created.description, 'coffee');
    });

    test('executes createBudget with items', () async {
      final draft = AIActionDraft(
        id: 'draft-2',
        type: AIActionType.createBudget,
        title: 'Set Budget: ₱15,000.00',
        subtitle: 'Monthly Budget for October 2026',
        payload: const {
          'name': 'October 2026 Budget',
          'totalBudget': 15000.0,
          'periodStart': '2026-10-01T00:00:00.000',
          'periodEnd': '2026-10-31T23:59:59.000',
          'categoryAllocations': {
            'Food': 5000.0,
            'Bills': 10000.0,
          },
        },
        createdAt: DateTime.now(),
      );

      final result = await executor.execute(draft);

      expect(result.success, isTrue);
      expect(result.message, contains('15,000.00'));
      expect(budgetRepo.createdBudgets.length, 1);
      expect(budgetRepo.createdBudgets.first.totalBudget, 15000.0);
      expect(budgetRepo.createdItems.length, 2);
    });

    test('executes createGoal', () async {
      final draft = AIActionDraft(
        id: 'draft-3',
        type: AIActionType.createGoal,
        title: 'New Savings Goal: ₱50,000.00',
        subtitle: 'Emergency Fund',
        payload: const {
          'name': 'Emergency Fund',
          'targetAmount': 50000.0,
          'targetDate': '2027-01-01T00:00:00.000',
        },
        createdAt: DateTime.now(),
      );

      final result = await executor.execute(draft);

      expect(result.success, isTrue);
      expect(result.message, contains('50,000.00'));
      expect(goalRepo.createdGoals.length, 1);
      expect(goalRepo.createdGoals.first.name, 'Emergency Fund');
      expect(goalRepo.createdGoals.first.targetAmount, 50000.0);
    });

    test('executes applyFinancialPlan (creates budget and savings goal)', () async {
      final draft = AIActionDraft(
        id: 'draft-4',
        type: AIActionType.applyFinancialPlan,
        title: 'Apply 50/30/20 Plan for ₱30,000.00',
        subtitle: 'Needs: ₱15,000 | Wants: ₱9,000 | Savings: ₱6,000',
        payload: const {
          'salary': 30000.0,
          'needsBudget': 15000.0,
          'wantsBudget': 9000.0,
          'savingsGoal': 6000.0,
          'periodStart': '2026-10-01T00:00:00.000',
          'periodEnd': '2026-10-31T23:59:59.000',
        },
        createdAt: DateTime.now(),
      );

      final result = await executor.execute(draft);

      expect(result.success, isTrue);
      expect(budgetRepo.createdBudgets.length, 1);
      expect(budgetRepo.createdBudgets.first.totalBudget, 24000.0); // 15000 + 9000
      expect(goalRepo.createdGoals.length, 1);
      expect(goalRepo.createdGoals.first.targetAmount, 6000.0);
    });
  });
}

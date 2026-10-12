import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/features/ai_assistant/domain/ai_action_draft.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_executor.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_scenario_sandbox.dart';
import 'package:mayperapa/infrastructure/ai/runtime/rule_based_ai_engine.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/domain/entities/budget.dart';
import 'package:mayperapa/shared/domain/entities/financial_goal.dart';
import 'package:mayperapa/shared/domain/entities/account.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/repositories/transaction_repository.dart';
import 'package:mayperapa/shared/domain/repositories/category_repository.dart';
import 'package:mayperapa/shared/domain/repositories/account_repository.dart';
import 'package:mayperapa/shared/domain/repositories/budget_repository.dart';
import 'package:mayperapa/shared/domain/repositories/goal_repository.dart';

class InMemoryTxnRepo implements TransactionRepository {
  final List<Transaction> items = [];
  @override
  Future<Transaction> create(Transaction t) async {
    final created = t.copyWith(id: items.length + 1);
    items.add(created);
    return created;
  }
  @override
  Future<List<Transaction>> getAllForUser(int userId) async => items;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InMemoryBudgetRepo implements BudgetRepository {
  final List<Budget> budgets = [];
  final List<BudgetItem> items = [];
  @override
  Future<Budget> create(Budget b, List<BudgetItem> i) async {
    final created = b.copyWith(id: budgets.length + 1);
    budgets.add(created);
    items.addAll(i);
    return created;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InMemoryGoalRepo implements GoalRepository {
  final List<FinancialGoal> goals = [];
  @override
  Future<FinancialGoal> create(FinancialGoal g) async {
    final created = g.copyWith(id: goals.length + 1);
    goals.add(created);
    return created;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InMemoryCatRepo implements CategoryRepository {
  final List<Category> cats = [
    Category(id: 1, userId: 1, name: 'Food & Dining', icon: 'fastfood', color: '#FF5722', type: CategoryType.expense, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Category(id: 2, userId: 1, name: 'Bills & Utilities', icon: 'receipt', color: '#3F51B5', type: CategoryType.expense, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Category(id: 3, userId: 1, name: 'Shopping', icon: 'shopping_bag', color: '#E91E63', type: CategoryType.expense, createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];
  @override
  Future<List<Category>> getAllForUser(int userId, {bool activeOnly = true}) async => cats;
  @override
  Future<void> seedDefaults(int userId) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class InMemoryAccRepo implements AccountRepository {
  final List<Account> accounts = [
    Account(id: 1, userId: 1, name: 'Main Wallet', type: AccountType.cash, currencyCode: 'PHP', balance: 10000, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Account(id: 2, userId: 1, name: 'Savings Vault', type: AccountType.bank, currencyCode: 'PHP', balance: 25000, createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];
  @override
  Future<List<Account>> getAllForUser(int userId, {bool activeOnly = true}) async => accounts;
  @override
  Future<void> seedDefaults(int userId, {String currencyCode = 'PHP'}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 4: Generative UI & Multi-Action Bundles Tests', () {
    test('AIScenarioSandbox recalculates dynamic impact when slider moves', () {
      const sandbox = AIScenarioSandbox(
        id: 'sandbox_1',
        categoryName: 'Dining Out',
        currentMonthlySpending: 5000,
        baselineCutAmount: 1000,
        minCutAmount: 200,
        maxCutAmount: 3000,
        goalTargetAmount: 50000,
        goalCurrentAmount: 20000,
        goalName: 'Emergency Fund',
      );

      // Baseline cut = ₱1,000/mo -> ₱12,000/yr saved
      final baselineCalc = sandbox.calculateImpact(1000);
      expect(baselineCalc.monthlySavings, 1000.0);
      expect(baselineCalc.annualSavings, 12000.0);
      // Remaining goal: ₱30,000. At ₱1,000/mo saved, takes 30 months
      expect(baselineCalc.monthsToGoal, 30.0);

      // User drags slider to ₱2,500/mo -> ₱30,000/yr saved
      final higherCut = sandbox.calculateImpact(2500);
      expect(higherCut.monthlySavings, 2500.0);
      expect(higherCut.annualSavings, 30000.0);
      // Remaining goal: ₱30,000. At ₱2,500/mo saved, takes 12 months (18 months faster!)
      expect(higherCut.monthsToGoal, 12.0);
      expect(higherCut.monthsSavedFaster, 18.0);
    });

    test('AIActionExecutor executes batchBundle atomically across multiple repositories', () async {
      final txnRepo = InMemoryTxnRepo();
      final catRepo = InMemoryCatRepo();
      final accRepo = InMemoryAccRepo();
      final budgetRepo = InMemoryBudgetRepo();
      final goalRepo = InMemoryGoalRepo();

      final executor = AIActionExecutor(
        userId: 1,
        transactionRepository: txnRepo,
        categoryRepository: catRepo,
        accountRepository: accRepo,
        budgetRepository: budgetRepo,
        goalRepository: goalRepo,
      );

      final bundleDraft = AIActionDraft(
        id: 'bundle_1',
        type: AIActionType.batchBundle,
        title: '50/30/20 Complete Salary Setup',
        subtitle: 'Executes 4 financial actions atomically',
        payload: const {
          'actions': [
            {
              'type': 'createBudget',
              'title': 'Needs Budget (50%)',
              'subtitle': 'Bills & Food allocation',
              'payload': {
                'name': 'Needs Budget',
                'amount': 15000.0,
              },
            },
            {
              'type': 'createBudget',
              'title': 'Wants Budget (30%)',
              'subtitle': 'Discretionary allocation',
              'payload': {
                'name': 'Wants Budget',
                'amount': 9000.0,
              },
            },
            {
              'type': 'createGoal',
              'title': 'Emergency Fund (20%)',
              'subtitle': 'Savings allocation target',
              'payload': {
                'name': 'Emergency Fund',
                'targetAmount': 6000.0,
              },
            },
            {
              'type': 'createTransaction',
              'title': 'Savings Deposit',
              'subtitle': 'Initial salary transfer to savings',
              'payload': {
                'amount': 6000.0,
                'type': 'income',
                'categoryName': 'Bills & Utilities',
                'accountName': 'Savings Vault',
                'description': '50/30/20 20% savings deposit',
              },
            },
          ],
        },
        createdAt: DateTime.now(),
      );

      final result = await executor.execute(bundleDraft);

      expect(result.success, isTrue);
      expect(result.message, contains('4'));
      expect(budgetRepo.budgets.length, 2);
      expect(goalRepo.goals.length, 1);
      expect(txnRepo.items.length, 1);
    });

    test('RuleBasedAIEngine extracts scenario sandbox for what-if queries', () async {
      final engine = RuleBasedAIEngine();
      final sandbox = engine.extractScenarioSandbox(
        userMessage: 'What if I cut dining out by ₱1,500 every month?',
        toolResults: const {},
      );

      expect(sandbox, isNotNull);
      expect(sandbox!.categoryName.toLowerCase(), contains('dining'));
      expect(sandbox.baselineCutAmount, 1500.0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/features/accounts/presentation/accounts_provider.dart';
import 'package:mayperapa/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:mayperapa/shared/domain/entities/account.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/domain/repositories/account_repository.dart';
import 'package:mayperapa/shared/domain/repositories/category_repository.dart';
import 'package:mayperapa/shared/domain/repositories/transaction_repository.dart';
import 'package:mayperapa/shared/domain/services/financial_calculator.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';

class FakeAccountRepository implements AccountRepository {
  final List<Account> _accounts = [];
  int _nextId = 1;

  FakeAccountRepository([List<Account>? initial]) {
    if (initial != null) _accounts.addAll(initial);
  }

  @override
  Future<Account> create(Account account) async {
    final created = account.copyWith(id: _nextId++);
    _accounts.add(created);
    return created;
  }

  @override
  Future<Account> update(Account account) async {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) _accounts[idx] = account;
    return account;
  }

  @override
  Future<void> delete(int id) async {
    final idx = _accounts.indexWhere((a) => a.id == id);
    if (idx != -1) _accounts[idx] = _accounts[idx].copyWith(isActive: false);
  }

  @override
  Future<Account?> getById(int id) async {
    return _accounts.where((a) => a.id == id && a.isActive).firstOrNull;
  }

  @override
  Future<List<Account>> getAllForUser(int userId, {bool activeOnly = true}) async {
    return _accounts.where((a) => a.userId == userId && (!activeOnly || a.isActive)).toList();
  }

  @override
  Future<void> seedDefaults(int userId, {String currencyCode = "PHP"}) async {
    for (final d in Account.defaults(currencyCode: currencyCode)) {
      await create(Account(
        userId: userId,
        name: d['name'] as String,
        type: AccountTypeX.fromDb(d['type'] as String),
        balance: (d['balance'] as num).toDouble(),
        currencyCode: d['currency_code'] as String,
        icon: d['icon'] as String?,
        color: d['color'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }
}

class FakeTransactionRepository implements TransactionRepository {
  final List<Transaction> _transactions = [];
  int _nextId = 1;

  @override
  Future<Transaction> create(Transaction transaction) async {
    final created = transaction.copyWith(id: _nextId++);
    _transactions.add(created);
    return created;
  }

  @override
  Future<Transaction> update(Transaction transaction) async {
    final idx = _transactions.indexWhere((t) => t.id == transaction.id);
    if (idx != -1) _transactions[idx] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(int id) async {
    _transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<Transaction?> getById(int id) async {
    return _transactions.where((t) => t.id == id).firstOrNull;
  }

  @override
  Future<List<Transaction>> getAllForUser(int userId) async {
    return List.from(_transactions);
  }

  @override
  Future<List<Transaction>> search(int userId, String query) async {
    return _transactions.where((t) => (t.description ?? '').contains(query)).toList();
  }
}

class FakeCategoryRepository implements CategoryRepository {
  final List<Category> _categories;

  FakeCategoryRepository([List<Category>? initialCategories])
      : _categories = initialCategories ?? [
          Category(
            id: 1,
            userId: 1,
            name: 'Account Transfer',
            type: CategoryType.transfer,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Category(
            id: 2,
            userId: 1,
            name: 'Salary',
            type: CategoryType.income,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

  @override
  Future<Category> create(Category category) async {
    final item = category.copyWith(id: category.id ?? (_categories.length + 1));
    _categories.add(item);
    return item;
  }

  @override
  Future<Category> update(Category category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx != -1) _categories[idx] = category;
    return category;
  }

  @override
  Future<void> delete(int id) async {
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<Category?> getById(int id) async => _categories.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<Category>> getAllForUser(int userId, {bool activeOnly = true}) async => List.from(_categories);

  @override
  Future<void> seedDefaults(int userId) async {}
}

void main() {
  group('Accounts & Wallet Management Tests', () {
    late FakeAccountRepository accountRepo;
    late FakeTransactionRepository txnRepo;
    late FakeCategoryRepository categoryRepo;
    late ProviderContainer container;

    setUp(() {
      accountRepo = FakeAccountRepository();
      txnRepo = FakeTransactionRepository();
      categoryRepo = FakeCategoryRepository();

      container = ProviderContainer(
        overrides: [
          accountRepositoryProvider.overrideWithValue(accountRepo),
          transactionRepositoryProvider.overrideWithValue(txnRepo),
          categoryRepositoryProvider.overrideWithValue(categoryRepo),
          currentUserIdProvider.overrideWithValue(1),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('initializes and seeds default Cash account if none exist', () async {
      final accounts = await container.read(accountsProvider.future);
      expect(accounts, isNotEmpty);
      expect(accounts.first.name, equals('Cash'));
      expect(accounts.first.type, equals(AccountType.cash));
    });

    test('creates new account with initial starting balance', () async {
      final notifier = container.read(accountsProvider.notifier);
      final account = await notifier.createAccount(
        name: 'GCash',
        type: AccountType.digitalWallet,
        initialBalance: 5000.0,
        institutionName: 'GCash',
        accountNumberMasked: '*8892',
        colorHex: '#007DFE',
      );

      expect(account.id, isNotNull);
      expect(account.name, equals('GCash'));
      expect(account.institutionName, equals('GCash'));
      expect(account.accountNumberMasked, equals('*8892'));

      final accounts = await container.read(accountsProvider.future);
      expect(accounts.any((a) => a.name == 'GCash'), isTrue);

      // Verify opening transaction was logged
      final txns = await container.read(transactionsProvider.future);
      expect(txns.any((t) => t.accountId == account.id && t.amount == 5000.0), isTrue);
    });

    test('updates existing account details', () async {
      final notifier = container.read(accountsProvider.notifier);
      final account = await notifier.createAccount(
        name: 'My Bank',
        type: AccountType.bank,
        initialBalance: 1000.0,
      );

      await notifier.updateAccount(account.copyWith(name: 'BDO Unibank', color: '#003366'));

      final accounts = await container.read(accountsProvider.future);
      final updated = accounts.firstWhere((a) => a.id == account.id);
      expect(updated.name, equals('BDO Unibank'));
      expect(updated.color, equals('#003366'));
    });

    test('soft deletes account', () async {
      final notifier = container.read(accountsProvider.notifier);
      final account = await notifier.createAccount(
        name: 'Old Wallet',
        type: AccountType.digitalWallet,
      );

      await notifier.deleteAccount(account.id!);

      final accounts = await container.read(accountsProvider.future);
      expect(accounts.any((a) => a.id == account.id), isFalse);
    });

    test('executes atomic transfer between accounts without altering net worth', () async {
      final notifier = container.read(accountsProvider.notifier);

      final bank = await notifier.createAccount(
        name: 'BPI Checking',
        type: AccountType.bank,
        initialBalance: 10000.0,
      );

      final gcash = await notifier.createAccount(
        name: 'GCash Wallet',
        type: AccountType.digitalWallet,
        initialBalance: 2000.0,
      );

      // Transfer 3,000 from BPI to GCash
      await notifier.transferFunds(
        sourceAccountId: bank.id!,
        destinationAccountId: gcash.id!,
        amount: 3000.0,
        note: 'Load GCash for bills',
      );

      final txns = await container.read(transactionsProvider.future);

      // Should have 2 initial transactions + 2 transfer transactions = 4
      final transfers = txns.where((t) => t.type == TransactionType.transfer).toList();
      expect(transfers.length, equals(2));

      final outflow = transfers.firstWhere((t) => !t.isTransferInflow);
      final inflow = transfers.firstWhere((t) => t.isTransferInflow);

      expect(outflow.accountId, equals(bank.id));
      expect(outflow.transferAccountId, equals(gcash.id));
      expect(outflow.signedAmount, equals(-3000.0));

      expect(inflow.accountId, equals(gcash.id));
      expect(inflow.transferAccountId, equals(bank.id));
      expect(inflow.signedAmount, equals(3000.0));

      // Test FinancialCalculator with these transactions
      const calculator = FinancialCalculator();
      final totalBalance = calculator.calculateCurrentBalance(txns);
      // Net worth before: 10,000 + 2,000 = 12,000.
      // Net worth after: 12,000 (transfers net to 0)
      expect(totalBalance, equals(12000.0));

      final bankBalance = calculator.calculateCurrentBalance(txns, accountId: bank.id);
      expect(bankBalance, equals(7000.0)); // 10,000 - 3,000

      final gcashBalance = calculator.calculateCurrentBalance(txns, accountId: gcash.id);
      expect(gcashBalance, equals(5000.0)); // 2,000 + 3,000
    });

    test('rejects transfer with invalid parameters', () async {
      final notifier = container.read(accountsProvider.notifier);
      final bank = await notifier.createAccount(name: 'Bank', type: AccountType.bank);

      // Same source and destination
      expect(
        () => notifier.transferFunds(
          sourceAccountId: bank.id!,
          destinationAccountId: bank.id!,
          amount: 500.0,
        ),
        throwsArgumentError,
      );

      // Negative or zero amount
      expect(
        () => notifier.transferFunds(
          sourceAccountId: bank.id!,
          destinationAccountId: 999,
          amount: 0.0,
        ),
        throwsArgumentError,
      );
    });
  });
}

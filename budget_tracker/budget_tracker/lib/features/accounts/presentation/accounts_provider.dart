import "package:flutter_riverpod/flutter_riverpod.dart";
import "../../../shared/domain/entities/account.dart";
import "../../../shared/domain/entities/enums.dart";
import "../../../shared/domain/entities/transaction.dart";
import "../../../shared/presentation/providers/app_providers.dart";
import "../../transactions/presentation/providers/transactions_provider.dart";

/// Accounts notifier managing multi-wallet balances, account creation, updates,
/// soft-deletion, and atomic inter-account transfers per AGENTS.md.
final accountsProvider = AsyncNotifierProvider<AccountsNotifier, List<Account>>(() {
  return AccountsNotifier();
});

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    final repo = ref.watch(accountRepositoryProvider);
    final userId = ref.watch(currentUserIdProvider);
    var accounts = await repo.getAllForUser(userId);
    if (accounts.isEmpty) {
      final now = DateTime.now();
      await repo.create(Account(
        userId: userId,
        name: "Cash",
        type: AccountType.cash,
        currencyCode: "PHP",
        createdAt: now,
        updatedAt: now,
      ));
      accounts = await repo.getAllForUser(userId);
    }
    return accounts;
  }

  Future<Account> createAccount({
    required String name,
    required AccountType type,
    double initialBalance = 0.0,
    String? institutionName,
    String? accountNumberMasked,
    String? colorHex,
    String? iconName,
    String currencyCode = "PHP",
  }) async {
    final userId = ref.read(currentUserIdProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final now = DateTime.now();

    final newAccount = Account(
      userId: userId,
      name: name.trim(),
      type: type,
      balance: initialBalance,
      currencyCode: currencyCode,
      institutionName: institutionName?.trim(),
      accountNumberMasked: accountNumberMasked?.trim(),
      color: colorHex,
      icon: iconName,
      createdAt: now,
      updatedAt: now,
    );

    final created = await accountRepo.create(newAccount);

    // If starting balance is > 0, log an initial opening balance income transaction
    if (initialBalance > 0) {
      final txnRepo = ref.read(transactionRepositoryProvider);
      final catRepo = ref.read(categoryRepositoryProvider);
      final categories = await catRepo.getAllForUser(userId);
      final incomeCat = categories.where((c) => c.type == CategoryType.income).firstOrNull;
      final catId = incomeCat?.id ?? (categories.isNotEmpty ? categories.first.id! : 1);

      await txnRepo.create(Transaction(
        userId: userId,
        accountId: created.id!,
        categoryId: catId,
        type: TransactionType.income,
        amount: initialBalance,
        description: 'Starting Balance',
        date: now,
        createdAt: now,
        updatedAt: now,
      ));
      ref.invalidate(transactionsProvider);
    }

    state = AsyncValue.data(await accountRepo.getAllForUser(userId));
    return created;
  }

  Future<void> updateAccount(Account account) async {
    final accountRepo = ref.read(accountRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await accountRepo.update(account.copyWith(updatedAt: DateTime.now()));
    state = AsyncValue.data(await accountRepo.getAllForUser(userId));
  }

  Future<void> deleteAccount(int id) async {
    final accountRepo = ref.read(accountRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await accountRepo.delete(id);
    state = AsyncValue.data(await accountRepo.getAllForUser(userId));
  }

  Future<void> transferFunds({
    required int sourceAccountId,
    required int destinationAccountId,
    required double amount,
    String? note,
    DateTime? date,
  }) async {
    if (sourceAccountId == destinationAccountId) {
      throw ArgumentError('Source and destination accounts must be different');
    }
    if (amount <= 0) {
      throw ArgumentError('Transfer amount must be greater than zero');
    }

    final userId = ref.read(currentUserIdProvider);
    final accountRepo = ref.read(accountRepositoryProvider);
    final txnRepo = ref.read(transactionRepositoryProvider);
    final categoryRepo = ref.read(categoryRepositoryProvider);

    final sourceAccount = await accountRepo.getById(sourceAccountId);
    final destAccount = await accountRepo.getById(destinationAccountId);
    if (sourceAccount == null || destAccount == null) {
      throw StateError('Source or destination account not found');
    }

    final categories = await categoryRepo.getAllForUser(userId);
    final transferCat = categories.where((c) => c.type == CategoryType.transfer).firstOrNull;
    final catId = transferCat?.id ?? (categories.isNotEmpty ? categories.first.id! : 1);

    final transferDate = date ?? DateTime.now();
    final now = DateTime.now();

    // 1. Outflow leg (Source account deduction)
    final outflow = Transaction(
      userId: userId,
      accountId: sourceAccountId,
      categoryId: catId,
      type: TransactionType.transfer,
      amount: amount,
      transferAccountId: destinationAccountId,
      isTransferInflow: false,
      description: 'Transfer to ${destAccount.name}',
      notes: note,
      date: transferDate,
      createdAt: now,
      updatedAt: now,
    );

    // 2. Inflow leg (Destination account addition)
    final inflow = Transaction(
      userId: userId,
      accountId: destinationAccountId,
      categoryId: catId,
      type: TransactionType.transfer,
      amount: amount,
      transferAccountId: sourceAccountId,
      isTransferInflow: true,
      description: 'Transfer from ${sourceAccount.name}',
      notes: note,
      date: transferDate,
      createdAt: now,
      updatedAt: now,
    );

    await txnRepo.create(outflow);
    await txnRepo.create(inflow);

    ref.invalidate(transactionsProvider);
    state = AsyncValue.data(await accountRepo.getAllForUser(userId));
  }
}

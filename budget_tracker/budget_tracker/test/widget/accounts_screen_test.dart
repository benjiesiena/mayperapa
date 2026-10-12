import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/accounts/presentation/screens/accounts_screen.dart';
import 'package:mayperapa/shared/domain/entities/account.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';

import '../unit/accounts_management_test.dart';

void main() {
  group('AccountsScreen & Wallets Widget Tests', () {
    late FakeAccountRepository fakeAccountRepo;
    late FakeTransactionRepository fakeTxnRepo;
    late FakeCategoryRepository fakeCategoryRepo;

    final initialAccounts = [
      Account(
        id: 1,
        userId: 1,
        name: 'GCash',
        type: AccountType.digitalWallet,
        balance: 5000,
        currencyCode: 'PHP',
        institutionName: 'GCash',
        accountNumberMasked: '*8892',
        color: '#007DFE',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 2,
        userId: 1,
        name: 'BDO Savings',
        type: AccountType.bank,
        balance: 15000,
        currencyCode: 'PHP',
        institutionName: 'BDO',
        accountNumberMasked: '*1234',
        color: '#003366',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Account(
        id: 3,
        userId: 1,
        name: 'Cash in Hand',
        type: AccountType.cash,
        balance: 1200,
        currencyCode: 'PHP',
        color: '#10B981',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    setUp(() {
      fakeAccountRepo = FakeAccountRepository(initialAccounts);
      fakeTxnRepo = FakeTransactionRepository();
      fakeCategoryRepo = FakeCategoryRepository();

      // Seed initial transactions matching account balances
      fakeTxnRepo.create(Transaction(
        userId: 1,
        accountId: 1,
        categoryId: 2,
        type: TransactionType.income,
        amount: 5000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      fakeTxnRepo.create(Transaction(
        userId: 1,
        accountId: 2,
        categoryId: 2,
        type: TransactionType.income,
        amount: 15000,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      fakeTxnRepo.create(Transaction(
        userId: 1,
        accountId: 3,
        categoryId: 2,
        type: TransactionType.income,
        amount: 1200,
        date: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(fakeAccountRepo),
          transactionRepositoryProvider.overrideWithValue(fakeTxnRepo),
          categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
          currentUserIdProvider.overrideWithValue(1),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const AccountsScreen(),
        ),
      );
    }

    testWidgets('renders Net Worth summary and all account categories', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Net Worth check: 5,000 + 15,000 + 1,200 = 21,200
      expect(find.text('TOTAL NET WORTH'), findsOneWidget);
      expect(find.textContaining('21,200'), findsWidgets);

      // Section headers
      expect(find.text('E-WALLETS & DIGITAL'), findsOneWidget);
      expect(find.text('BANK ACCOUNTS'), findsOneWidget);
      expect(find.text('PHYSICAL CASH & ENVELOPES'), findsOneWidget);

      // Account cards
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('*8892'), findsOneWidget);
      expect(find.text('BDO Savings'), findsOneWidget);
      expect(find.text('Cash in Hand'), findsOneWidget);
    });

    testWidgets('tapping Add Account button opens AddEditAccountSheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final addBtn = find.byIcon(Icons.add).first;
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Add New Account'), findsOneWidget);
      expect(find.text('ACCOUNT NAME'), findsOneWidget);
      expect(find.text('STARTING BALANCE'), findsOneWidget);
    });

    testWidgets('tapping Transfer Funds button opens TransferFundsSheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final transferBtn = find.text('Transfer Funds').first;
      await tester.tap(transferBtn);
      await tester.pumpAndSettle();

      expect(find.text('FROM ACCOUNT'), findsOneWidget);
      expect(find.text('TO ACCOUNT'), findsOneWidget);
      expect(find.text('TRANSFER AMOUNT'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:mayperapa/features/analytics/presentation/widgets/cashflow_bar_chart.dart';
import 'package:mayperapa/features/analytics/presentation/widgets/category_donut_chart.dart';
import 'package:mayperapa/features/analytics/presentation/widgets/net_worth_line_chart.dart';
import 'package:mayperapa/features/analytics/presentation/widgets/period_selector_chip_group.dart';
import 'package:mayperapa/features/analytics/presentation/widgets/savings_gauge_card.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';

import '../unit/accounts_management_test.dart';

void main() {
  group('AnalyticsScreen & Trend Visualizations Widget Tests', () {
    late FakeTransactionRepository fakeTxnRepo;
    late FakeCategoryRepository fakeCategoryRepo;

    final now = DateTime.now();

    final testCategories = [
      Category(
        id: 1,
        userId: 1,
        name: 'Dining & Food',
        type: CategoryType.expense,
        color: '#F97316',
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 2,
        userId: 1,
        name: 'Utilities',
        type: CategoryType.expense,
        color: '#3B82F6',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    setUp(() {
      fakeTxnRepo = FakeTransactionRepository();
      fakeCategoryRepo = FakeCategoryRepository(testCategories);

      // Seed 2 months of transactions
      fakeTxnRepo.create(Transaction(
        userId: 1,
        accountId: 1,
        categoryId: 1,
        type: TransactionType.income,
        amount: 45000,
        date: now.subtract(const Duration(days: 10)),
        createdAt: now,
        updatedAt: now,
      ));
      fakeTxnRepo.create(Transaction(
        userId: 1,
        accountId: 1,
        categoryId: 1,
        type: TransactionType.expense,
        amount: 5000,
        date: now.subtract(const Duration(days: 8)),
        createdAt: now,
        updatedAt: now,
      ));
      fakeTxnRepo.create(Transaction(
        userId: 1,
        accountId: 1,
        categoryId: 2,
        type: TransactionType.expense,
        amount: 3500,
        date: now.subtract(const Duration(days: 4)),
        createdAt: now,
        updatedAt: now,
      ));
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(fakeTxnRepo),
          categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
          currentUserIdProvider.overrideWithValue(1),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const AnalyticsScreen(),
        ),
      );
    }

    testWidgets('renders all analytics cards, charts, and period chips', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // App Bar
      expect(find.text('Financial Analytics'), findsOneWidget);

      // Period selector chips
      expect(find.byType(PeriodSelectorChipGroup), findsOneWidget);
      expect(find.text('30 Days'), findsOneWidget);
      expect(find.text('3 Months'), findsOneWidget);
      expect(find.text('6 Months'), findsOneWidget);
      expect(find.text('YTD'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);

      // Gauge card
      expect(find.byType(SavingsGaugeCard), findsOneWidget);
      expect(find.text('PERIOD PERFORMANCE'), findsOneWidget);
      expect(find.text('Savings Rate'), findsOneWidget);
      expect(find.text('Total Inflow'), findsOneWidget);
      expect(find.text('Total Outflow'), findsOneWidget);

      // Cash flow bar chart
      expect(find.byType(CashflowBarChart), findsOneWidget);
      expect(find.text('CASH FLOW (6 MONTHS)'), findsOneWidget);
      expect(find.text('Inflow'), findsOneWidget);
      expect(find.text('Outflow'), findsOneWidget);

      // Category Donut chart
      expect(find.byType(CategoryDonutChart), findsOneWidget);
      expect(find.text('SPENDING BY CATEGORY'), findsOneWidget);
      expect(find.text('Dining & Food'), findsOneWidget);
      expect(find.text('Utilities'), findsOneWidget);

      // Net Worth curve
      expect(find.byType(NetWorthLineChart), findsOneWidget);
      expect(find.text('NET WORTH TRAJECTORY'), findsOneWidget);
    });

    testWidgets('tapping period chip updates active selection', (tester) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap "30 Days"
      await tester.tap(find.text('30 Days'));
      await tester.pumpAndSettle();

      // Gauge still renders properly
      expect(find.text('PERIOD PERFORMANCE'), findsOneWidget);
    });
  });
}

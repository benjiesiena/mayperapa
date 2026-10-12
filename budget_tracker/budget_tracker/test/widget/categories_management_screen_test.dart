import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/categories/presentation/screens/categories_management_screen.dart';
import 'package:mayperapa/features/categories/presentation/widgets/add_edit_category_sheet.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';

import '../unit/accounts_management_test.dart';

void main() {
  group('CategoriesManagementScreen Widget Tests', () {
    late FakeCategoryRepository fakeCategoryRepo;
    late FakeTransactionRepository fakeTxnRepo;

    final now = DateTime.now();
    final initialCategories = [
      Category(
        id: 1,
        userId: 1,
        name: 'Dining & Food',
        type: CategoryType.expense,
        color: '#F97316',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 2,
        userId: 1,
        name: 'Subscriptions & Streaming',
        type: CategoryType.expense,
        color: '#8B5CF6',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 3,
        userId: 1,
        name: 'Tech Consulting',
        type: CategoryType.income,
        color: '#10B981',
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    setUp(() {
      fakeCategoryRepo = FakeCategoryRepository(List.from(initialCategories));
      fakeTxnRepo = FakeTransactionRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
          transactionRepositoryProvider.overrideWithValue(fakeTxnRepo),
          currentUserIdProvider.overrideWithValue(1),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const CategoriesManagementScreen(),
        ),
      );
    }

    testWidgets('renders categories list, default badge, and tab bars', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);

      // Default category
      expect(find.text('Dining & Food'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);

      // Custom category
      expect(find.text('Subscriptions & Streaming'), findsOneWidget);

      // Custom categories show edit and delete buttons
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('tapping Add Category opens AddEditCategorySheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.byType(AddEditCategorySheet), findsOneWidget);
      expect(find.text('New Category'), findsOneWidget);
      expect(find.text('COLOR ACCENT'), findsOneWidget);
    });
  });
}

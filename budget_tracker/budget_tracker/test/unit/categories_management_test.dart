import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/features/categories/presentation/categories_provider.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';

import 'accounts_management_test.dart';

void main() {
  group('Categories Management Tests', () {
    late FakeCategoryRepository fakeCategoryRepo;
    late FakeTransactionRepository fakeTxnRepo;
    late ProviderContainer container;

    final now = DateTime.now();
    final defaultCategories = [
      Category(
        id: 1,
        userId: 1,
        name: 'Groceries',
        type: CategoryType.expense,
        color: '#10B981',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 2,
        userId: 1,
        name: 'General & Other',
        type: CategoryType.expense,
        color: '#64748B',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
      Category(
        id: 3,
        userId: 1,
        name: 'Salary',
        type: CategoryType.income,
        color: '#3B82F6',
        isDefault: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    setUp(() {
      fakeCategoryRepo = FakeCategoryRepository(List.from(defaultCategories));
      fakeTxnRepo = FakeTransactionRepository();

      container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
          transactionRepositoryProvider.overrideWithValue(fakeTxnRepo),
          currentUserIdProvider.overrideWithValue(1),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('creates custom category with designated color and icon', () async {
      final initialList = await container.read(categoriesProvider.future);
      expect(initialList.length, 3);

      final created = await container.read(categoriesProvider.notifier).createCategory(
            name: 'Coffee & Cafes',
            type: CategoryType.expense,
            colorHex: '#F59E0B',
            iconName: 'coffee',
          );

      expect(created.name, 'Coffee & Cafes');
      expect(created.isDefault, false);
      expect(created.type, CategoryType.expense);

      final updatedList = await container.read(categoriesProvider.future);
      expect(updatedList.any((c) => c.name == 'Coffee & Cafes'), true);
    });

    test('updates category name and color', () async {
      final created = await container.read(categoriesProvider.notifier).createCategory(
            name: 'Pets & Supplies',
            type: CategoryType.expense,
            colorHex: '#8B5CF6',
            iconName: 'pets',
          );

      final updated = await container.read(categoriesProvider.notifier).updateCategory(
            created.copyWith(name: 'Pet Care & Food', color: '#EC4899'),
          );

      expect(updated.name, 'Pet Care & Food');
      expect(updated.color, '#EC4899');
    });

    test('deletes category and safely reassigns linked transactions', () async {
      // 1. Create custom category
      final customCat = await container.read(categoriesProvider.notifier).createCategory(
            name: 'Gym & Fitness',
            type: CategoryType.expense,
            colorHex: '#EF4444',
            iconName: 'fitness_center',
          );

      // 2. Link a transaction to it
      final txn = await fakeTxnRepo.create(Transaction(
        userId: 1,
        accountId: 1,
        categoryId: customCat.id ?? 10,
        type: TransactionType.expense,
        amount: 2500,
        date: now,
        createdAt: now,
        updatedAt: now,
      ));

      expect(txn.categoryId, customCat.id ?? 10);

      // 3. Delete category with reassignment to "General & Other" (id: 2)
      await container.read(categoriesProvider.notifier).deleteCategory(
            categoryId: customCat.id ?? 10,
            reassignToCategoryId: 2,
          );

      // Verify transaction was reassigned to 2
      final allTxns = await fakeTxnRepo.getAllForUser(1);
      final updatedTxn = allTxns.firstWhere((t) => t.id == txn.id);
      expect(updatedTxn.categoryId, 2);
    });
  });
}

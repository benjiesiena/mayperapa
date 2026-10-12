import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/domain/entities/category.dart';
import '../../../shared/domain/entities/enums.dart';
import '../../../shared/presentation/providers/app_providers.dart';
import '../../budgets/presentation/providers/budgets_provider.dart';
import '../../transactions/presentation/providers/transactions_provider.dart';

/// Categories notifier providing state and mutations (create, update, delete with reassignment)
/// while maintaining backward compatibility with `ref.watch(categoriesProvider)`.
final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(CategoriesNotifier.new);

class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final repo = ref.watch(categoryRepositoryProvider);
    final userId = ref.watch(currentUserIdProvider);

    var categories = await repo.getAllForUser(userId);
    if (categories.isEmpty) {
      await repo.seedDefaults(userId);
      categories = await repo.getAllForUser(userId);
    }
    return categories;
  }

  /// Creates a new custom category.
  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    required String colorHex,
    required String iconName,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    final now = DateTime.now();

    final newCat = Category(
      userId: userId,
      name: name.trim(),
      type: type,
      color: colorHex,
      icon: iconName,
      isDefault: false,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    final created = await repo.create(newCat);
    ref.invalidateSelf();
    await future;
    return created;
  }

  /// Updates an existing category.
  Future<Category> updateCategory(Category category) async {
    final repo = ref.read(categoryRepositoryProvider);
    final updated = category.copyWith(updatedAt: DateTime.now());
    await repo.update(updated);
    ref.invalidateSelf();
    await future;
    return updated;
  }

  /// Deletes a category. If [reassignToCategoryId] is provided, all transactions
  /// currently assigned to [categoryId] are reassigned before deletion.
  Future<void> deleteCategory({
    required int categoryId,
    int? reassignToCategoryId,
  }) async {
    final repo = ref.read(categoryRepositoryProvider);
    final txnRepo = ref.read(transactionRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);

    // If reassignment is requested, update existing transactions
    if (reassignToCategoryId != null) {
      final txns = await txnRepo.getAllForUser(userId);
      for (final txn in txns) {
        if (txn.categoryId == categoryId) {
          final reassigned = txn.copyWith(
            categoryId: reassignToCategoryId,
            updatedAt: DateTime.now(),
          );
          await txnRepo.update(reassigned);
        }
      }
    }

    await repo.delete(categoryId);

    ref.invalidateSelf();
    ref.invalidate(transactionsProvider);
    ref.invalidate(activeBudgetProvider);
    await future;
  }
}

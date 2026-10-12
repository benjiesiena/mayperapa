import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/domain/entities/category.dart';
import '../../../../shared/domain/entities/enums.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../categories_provider.dart';
import '../widgets/add_edit_category_sheet.dart';

class CategoriesManagementScreen extends ConsumerStatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  ConsumerState<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends ConsumerState<CategoriesManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null) return fallback;
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  IconData _iconFromName(String? name) => switch (name) {
        'restaurant' => Icons.restaurant,
        'directions_car' => Icons.directions_car,
        'home' => Icons.home,
        'shopping_bag' => Icons.shopping_bag,
        'movie' => Icons.movie,
        'medical_services' => Icons.medical_services,
        'fitness_center' => Icons.fitness_center,
        'school' => Icons.school,
        'flight' => Icons.flight,
        'pets' => Icons.pets,
        'work' => Icons.work,
        'receipt' => Icons.receipt,
        'card_giftcard' => Icons.card_giftcard,
        'build' => Icons.build,
        'savings' => Icons.savings,
        'payments' => Icons.payments,
        'coffee' => Icons.coffee,
        'local_gas_station' => Icons.local_gas_station,
        'phone_android' => Icons.phone_android,
        'wifi' => Icons.wifi,
        'electric_bolt' => Icons.electric_bolt,
        'child_care' => Icons.child_care,
        'sports_esports' => Icons.sports_esports,
        'inventory_2' => Icons.inventory_2,
        _ => Icons.category,
      };

  void _promptSafeDelete(BuildContext context, Category category, List<Category> allCategories) {
    final txns = ref.read(transactionsProvider).valueOrNull ?? [];
    final linkedTxns = txns.where((t) => t.categoryId == category.id).toList();

    if (linkedTxns.isNotEmpty) {
      // Find fallback "Other" or default category
      final fallbackCategory = allCategories.firstWhere(
        (c) => c.id != category.id && (c.name.toLowerCase().contains('other') || c.isDefault),
        orElse: () => allCategories.firstWhere((c) => c.id != category.id),
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Category In Use'),
          content: Text(
            '"${category.name}" is linked to ${linkedTxns.length} past transaction(s). '
            'Would you like to reassign them to "${fallbackCategory.name}" before deleting?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                HapticFeedback.mediumImpact();
                await ref.read(categoriesProvider.notifier).deleteCategory(
                      categoryId: category.id!,
                      reassignToCategoryId: fallbackCategory.id,
                    );
              },
              child: Text('Reassign to ${fallbackCategory.name}'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Category?'),
          content: Text('Are you sure you want to remove "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () async {
                Navigator.of(ctx).pop();
                HapticFeedback.mediumImpact();
                await ref.read(categoriesProvider.notifier).deleteCategory(categoryId: category.id!);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: palette.primary,
          unselectedLabelColor: palette.textSecondary,
          indicatorColor: palette.primary,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
            onPressed: () {
              final activeType = _tabController.index == 0 ? CategoryType.expense : CategoryType.income;
              AddEditCategorySheet.show(context, defaultType: activeType);
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (categories) {
          final expenseCategories = categories.where((c) => c.type == CategoryType.expense).toList();
          final incomeCategories = categories.where((c) => c.type == CategoryType.income).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(context, expenseCategories, categories),
              _buildCategoryList(context, incomeCategories, categories),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final activeType = _tabController.index == 0 ? CategoryType.expense : CategoryType.income;
          AddEditCategorySheet.show(context, defaultType: activeType);
        },
        backgroundColor: palette.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<Category> categoryList,
    List<Category> allCategories,
  ) {
    final palette = context.appColors;

    if (categoryList.isEmpty) {
      return Center(
        child: Text(
          'No categories found',
          style: TextStyle(color: palette.textTertiary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: categoryList.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final cat = categoryList[index];
        final color = _parseHex(cat.color, palette.primary);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: palette.border, width: 1),
          ),
          child: Row(
            children: [
              // Category Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFromName(cat.icon), color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),

              // Name & Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    if (cat.isDefault) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: palette.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              if (!cat.isDefault) ...[
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: palette.textSecondary),
                  tooltip: 'Edit Category',
                  onPressed: () => AddEditCategorySheet.show(context, category: cat),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                  tooltip: 'Delete Category',
                  onPressed: () => _promptSafeDelete(context, cat, allCategories),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

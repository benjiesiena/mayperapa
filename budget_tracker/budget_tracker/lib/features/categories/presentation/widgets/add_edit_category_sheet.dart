import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/domain/entities/category.dart';
import '../../../../shared/domain/entities/enums.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import '../categories_provider.dart';

class AddEditCategorySheet extends ConsumerStatefulWidget {
  final Category? initialCategory;
  final CategoryType defaultType;

  const AddEditCategorySheet({
    super.key,
    this.initialCategory,
    this.defaultType = CategoryType.expense,
  });

  static Future<void> show(
    BuildContext context, {
    Category? category,
    CategoryType defaultType = CategoryType.expense,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditCategorySheet(
        initialCategory: category,
        defaultType: defaultType,
      ),
    );
  }

  @override
  ConsumerState<AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<AddEditCategorySheet> {
  late final TextEditingController _nameController;
  late CategoryType _selectedType;
  late String _selectedColorHex;
  late String _selectedIcon;
  bool _saving = false;
  String? _error;

  static const _availableIcons = [
    'restaurant',
    'directions_car',
    'home',
    'shopping_bag',
    'movie',
    'medical_services',
    'fitness_center',
    'school',
    'flight',
    'pets',
    'work',
    'receipt',
    'card_giftcard',
    'build',
    'savings',
    'payments',
    'coffee',
    'local_gas_station',
    'phone_android',
    'wifi',
    'electric_bolt',
    'child_care',
    'sports_esports',
    'inventory_2',
  ];

  static const _curatedColors = [
    '#10B981', // Emerald
    '#3B82F6', // Sapphire
    '#F59E0B', // Amber
    '#EF4444', // Ruby
    '#8B5CF6', // Violet
    '#EC4899', // Rose
    '#06B6D4', // Cyan
    '#14B8A6', // Teal
    '#6366F1', // Indigo
    '#F97316', // Orange
    '#64748B', // Slate
    '#84CC16', // Lime
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.initialCategory;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _selectedType = cat?.type ?? widget.defaultType;
    _selectedColorHex = cat?.color ?? _curatedColors.first;
    _selectedIcon = cat?.icon ?? _availableIcons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseHex(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  IconData _iconFromName(String name) => switch (name) {
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a category name');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final notifier = ref.read(categoriesProvider.notifier);
      if (widget.initialCategory != null) {
        await notifier.updateCategory(
          widget.initialCategory!.copyWith(
            name: name,
            type: _selectedType,
            color: _selectedColorHex,
            icon: _selectedIcon,
          ),
        );
      } else {
        await notifier.createCategory(
          name: name,
          type: _selectedType,
          colorHex: _selectedColorHex,
          iconName: _selectedIcon,
        );
      }
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Failed to save: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final isEditing = widget.initialCategory != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          border: Border.all(color: palette.border, width: 1),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Category' : 'New Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Category Type Selector
              Row(
                children: [
                  Expanded(
                    child: TactileBounce(
                      onTap: () => setState(() => _selectedType = CategoryType.expense),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedType == CategoryType.expense ? palette.primary : palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _selectedType == CategoryType.expense ? palette.primary : palette.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Expense',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _selectedType == CategoryType.expense ? Colors.white : palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TactileBounce(
                      onTap: () => setState(() => _selectedType = CategoryType.income),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedType == CategoryType.income ? palette.primary : palette.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: _selectedType == CategoryType.income ? palette.primary : palette.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _selectedType == CategoryType.income ? Colors.white : palette.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Category Name Input
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  errorText: _error,
                  filled: true,
                  fillColor: palette.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: palette.border),
                  ),
                  prefixIcon: Icon(
                    _iconFromName(_selectedIcon),
                    color: _parseHex(_selectedColorHex),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Color Palette Picker
              Text(
                'COLOR ACCENT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: palette.textTertiary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _curatedColors.map((hex) {
                  final isSelected = hex == _selectedColorHex;
                  final color = _parseHex(hex);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColorHex = hex);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Icon Grid Picker
              Text(
                'ICON',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: palette.textTertiary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableIcons.map((iconName) {
                  final isSelected = iconName == _selectedIcon;
                  final selectedColor = _parseHex(_selectedColorHex);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedIcon = iconName);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? selectedColor.withValues(alpha: 0.15) : palette.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: isSelected ? selectedColor : palette.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Icon(
                        _iconFromName(iconName),
                        size: 20,
                        color: isSelected ? selectedColor : palette.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: TactileBounce(
                  onTap: _saving ? null : _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: palette.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    alignment: Alignment.center,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEditing ? 'Save Changes' : 'Create Category',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

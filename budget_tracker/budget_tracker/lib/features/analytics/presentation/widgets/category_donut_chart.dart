import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/financial_time_series.dart';

class CategoryDonutChart extends StatefulWidget {
  final List<CategorySpendingSlice> slices;

  const CategoryDonutChart({super.key, required this.slices});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> {
  int _touchedIndex = -1;

  Color _parseColor(String hex, Color fallback) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    final totalAmount = widget.slices.fold(0.0, (sum, s) => sum + s.amount);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPENDING BY CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: palette.textTertiary,
                ),
              ),
              Text(
                '${widget.slices.length} Categories',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.slices.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text(
                'No expenses logged for this period',
                style: TextStyle(color: palette.textTertiary, fontSize: 13),
              ),
            )
          else ...[
            SizedBox(
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 46,
                      sections: widget.slices.asMap().entries.map((entry) {
                        final i = entry.key;
                        final slice = entry.value;
                        final isTouched = i == _touchedIndex;
                        final color = _parseColor(slice.colorHex, palette.primary);

                        return PieChartSectionData(
                          color: color,
                          value: slice.amount,
                          title: '',
                          radius: isTouched ? 28 : 22,
                        );
                      }).toList(),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Spent',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: palette.textTertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(totalAmount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: palette.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(color: palette.border, height: 1),
            const SizedBox(height: AppSpacing.sm),
            ...widget.slices.asMap().entries.map((entry) {
              final i = entry.key;
              final slice = entry.value;
              final isTouched = i == _touchedIndex;
              final color = _parseColor(slice.colorHex, palette.primary);

              return InkWell(
                onTap: () {
                  setState(() {
                    _touchedIndex = _touchedIndex == i ? -1 : i;
                  });
                },
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isTouched ? palette.surfaceVariant : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          slice.categoryName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isTouched ? FontWeight.w700 : FontWeight.w500,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          '${slice.percentage.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        CurrencyFormatter.format(slice.amount),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

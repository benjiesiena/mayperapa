import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/financial_time_series.dart';

class CashflowBarChart extends StatefulWidget {
  final List<MonthlyCashFlowPoint> points;

  const CashflowBarChart({super.key, required this.points});

  @override
  State<CashflowBarChart> createState() => _CashflowBarChartState();
}

class _CashflowBarChartState extends State<CashflowBarChart> {
  int? _touchedGroupIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    final hasData = widget.points.any((p) => p.inflow > 0 || p.outflow > 0);

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
                'CASH FLOW (6 MONTHS)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: palette.textTertiary,
                ),
              ),
              Row(
                children: [
                  _legendDot(palette.positive, 'Inflow', palette.textSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  _legendDot(palette.negative, 'Outflow', palette.textSecondary),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasData)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text(
                'No cash flow history yet for this period',
                style: TextStyle(color: palette.textTertiary, fontSize: 13),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _calculateMaxY(),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => palette.surfaceVariant,
                      tooltipRoundedRadius: 8,
                      tooltipBorder: BorderSide(color: palette.border, width: 1),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final point = widget.points[groupIndex];
                        final isIncome = rodIndex == 0;
                        final amount = isIncome ? point.inflow : point.outflow;
                        return BarTooltipItem(
                          '${point.monthLabel}\n',
                          TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${isIncome ? "In" : "Out"}: ${CurrencyFormatter.format(amount)}',
                              style: TextStyle(
                                color: isIncome ? palette.positive : palette.negative,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (response == null || response.spot == null) {
                          _touchedGroupIndex = null;
                        } else {
                          _touchedGroupIndex = response.spot!.touchedBarGroupIndex;
                        }
                      });
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= widget.points.length) {
                            return const SizedBox.shrink();
                          }
                          final p = widget.points[index];
                          final isSelected = _touchedGroupIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              p.monthLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? palette.textPrimary : palette.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: widget.points.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: p.inflow,
                          color: palette.positive,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: p.outflow,
                          color: palette.negative,
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateMaxY() {
    double maxVal = 1000;
    for (final p in widget.points) {
      maxVal = max(maxVal, max(p.inflow, p.outflow));
    }
    return maxVal * 1.15;
  }

  Widget _legendDot(Color color, String label, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
        ),
      ],
    );
  }
}

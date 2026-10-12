import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/financial_time_series.dart';

class NetWorthLineChart extends StatefulWidget {
  final List<NetWorthPoint> points;

  const NetWorthLineChart({super.key, required this.points});

  @override
  State<NetWorthLineChart> createState() => _NetWorthLineChartState();
}

class _NetWorthLineChartState extends State<NetWorthLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    final hasPoints = widget.points.length >= 2;
    final latestBalance = widget.points.isNotEmpty ? widget.points.last.netWorth : 0.0;

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
                'NET WORTH TRAJECTORY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: palette.textTertiary,
                ),
              ),
              Text(
                CurrencyFormatter.format(latestBalance),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!hasPoints)
            Container(
              height: 160,
              alignment: Alignment.center,
              child: Text(
                'Log transactions over multiple days to reveal balance trajectory',
                style: TextStyle(color: palette.textTertiary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: _calculateMinY(),
                  maxY: _calculateMaxY(),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: max(1, (widget.points.length / 4).floor()).toDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= widget.points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              widget.points[index].label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: palette.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => palette.surfaceVariant,
                      tooltipRoundedRadius: 8,
                      tooltipBorder: BorderSide(color: palette.border, width: 1),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final point = widget.points[spot.spotIndex];
                          return LineTooltipItem(
                            '${point.label}\n',
                            TextStyle(
                              color: palette.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                            children: [
                              TextSpan(
                                text: CurrencyFormatter.format(point.netWorth),
                                style: TextStyle(
                                  color: palette.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (event, response) {
                      setState(() {
                        if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
                          _touchedIndex = null;
                        } else {
                          _touchedIndex = response.lineBarSpots!.first.spotIndex;
                        }
                      });
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: widget.points
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(entry.key.toDouble(), entry.value.netWorth))
                          .toList(),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: palette.primary,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final isTouched = _touchedIndex == index;
                          return FlDotCirclePainter(
                            radius: isTouched ? 5 : 2,
                            color: isTouched ? palette.primary : Colors.transparent,
                            strokeWidth: isTouched ? 2 : 0,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            palette.primary.withValues(alpha: 0.22),
                            palette.primary.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _calculateMinY() {
    double minVal = 0;
    for (final p in widget.points) {
      minVal = min(minVal, p.netWorth);
    }
    return minVal < 0 ? minVal * 1.15 : 0;
  }

  double _calculateMaxY() {
    double maxVal = 1000;
    for (final p in widget.points) {
      maxVal = max(maxVal, p.netWorth);
    }
    return maxVal * 1.15;
  }
}

import 'package:equatable/equatable.dart';

enum AnalyticsPeriod {
  days30('30 Days'),
  months3('3 Months'),
  months6('6 Months'),
  yearToDate('YTD'),
  allTime('All Time');

  final String label;
  const AnalyticsPeriod(this.label);
}

class MonthlyCashFlowPoint extends Equatable {
  final int year;
  final int month;
  final String monthLabel;
  final double inflow;
  final double outflow;
  final double net;

  const MonthlyCashFlowPoint({
    required this.year,
    required this.month,
    required this.monthLabel,
    required this.inflow,
    required this.outflow,
    required this.net,
  });

  @override
  List<Object?> get props => [year, month, monthLabel, inflow, outflow, net];
}

class CategorySpendingSlice extends Equatable {
  final int categoryId;
  final String categoryName;
  final double amount;
  final double percentage; // 0.0 - 100.0
  final String colorHex;
  final String? icon;

  const CategorySpendingSlice({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.colorHex,
    this.icon,
  });

  @override
  List<Object?> get props => [categoryId, categoryName, amount, percentage, colorHex, icon];
}

class NetWorthPoint extends Equatable {
  final DateTime date;
  final double netWorth;
  final String label;

  const NetWorthPoint({
    required this.date,
    required this.netWorth,
    required this.label,
  });

  @override
  List<Object?> get props => [date, netWorth, label];
}

class AnalyticsFinancialSummary extends Equatable {
  final double totalIncome;
  final double totalExpense;
  final double netSavings;
  final double savingsRate; // 0.0 - 1.0
  final AnalyticsPeriod period;
  final int transactionCount;

  const AnalyticsFinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netSavings,
    required this.savingsRate,
    required this.period,
    required this.transactionCount,
  });

  @override
  List<Object?> get props => [
        totalIncome,
        totalExpense,
        netSavings,
        savingsRate,
        period,
        transactionCount,
      ];
}

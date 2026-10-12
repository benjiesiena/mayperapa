import 'package:equatable/equatable.dart';

/// Represents calculation results when user drags the scenario sandbox slider.
class ScenarioImpactCalculation extends Equatable {
  final double cutAmount;
  final double monthlySavings;
  final double annualSavings;
  final double monthsToGoal;
  final double monthsSavedFaster;

  const ScenarioImpactCalculation({
    required this.cutAmount,
    required this.monthlySavings,
    required this.annualSavings,
    required this.monthsToGoal,
    required this.monthsSavedFaster,
  });

  @override
  List<Object?> get props => [
        cutAmount,
        monthlySavings,
        annualSavings,
        monthsToGoal,
        monthsSavedFaster,
      ];
}

/// Generative interactive what-if sandbox artifact.
///
/// Enables users to dynamically explore expense reductions (e.g. cutting dining out)
/// and witness real-time goal timeline acceleration via tactile sliders.
class AIScenarioSandbox extends Equatable {
  final String id;
  final String categoryName;
  final double currentMonthlySpending;
  final double baselineCutAmount;
  final double minCutAmount;
  final double maxCutAmount;
  final double goalTargetAmount;
  final double goalCurrentAmount;
  final String goalName;

  const AIScenarioSandbox({
    required this.id,
    required this.categoryName,
    required this.currentMonthlySpending,
    required this.baselineCutAmount,
    this.minCutAmount = 200,
    this.maxCutAmount = 4000,
    this.goalTargetAmount = 50000,
    this.goalCurrentAmount = 15000,
    this.goalName = 'Emergency Fund',
  });

  /// Dynamically computes financial acceleration for any slider value.
  ScenarioImpactCalculation calculateImpact(double cutAmount) {
    final effectiveCut = cutAmount <= 0 ? 0.0 : cutAmount;
    final monthly = effectiveCut;
    final annual = effectiveCut * 12;

    final remainingGoal = (goalTargetAmount - goalCurrentAmount) < 0
        ? 0.0
        : (goalTargetAmount - goalCurrentAmount);

    final monthsToGoal = effectiveCut > 0 ? (remainingGoal / effectiveCut) : 0.0;
    final baselineMonths = baselineCutAmount > 0 ? (remainingGoal / baselineCutAmount) : 0.0;
    final faster = (baselineMonths - monthsToGoal) < 0 ? 0.0 : (baselineMonths - monthsToGoal);

    return ScenarioImpactCalculation(
      cutAmount: effectiveCut,
      monthlySavings: monthly,
      annualSavings: annual,
      monthsToGoal: monthsToGoal,
      monthsSavedFaster: faster,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryName': categoryName,
        'currentMonthlySpending': currentMonthlySpending,
        'baselineCutAmount': baselineCutAmount,
        'minCutAmount': minCutAmount,
        'maxCutAmount': maxCutAmount,
        'goalTargetAmount': goalTargetAmount,
        'goalCurrentAmount': goalCurrentAmount,
        'goalName': goalName,
      };

  factory AIScenarioSandbox.fromJson(Map<String, dynamic> json) {
    return AIScenarioSandbox(
      id: json['id'] as String,
      categoryName: json['categoryName'] as String,
      currentMonthlySpending: (json['currentMonthlySpending'] as num).toDouble(),
      baselineCutAmount: (json['baselineCutAmount'] as num).toDouble(),
      minCutAmount: (json['minCutAmount'] as num?)?.toDouble() ?? 200,
      maxCutAmount: (json['maxCutAmount'] as num?)?.toDouble() ?? 4000,
      goalTargetAmount: (json['goalTargetAmount'] as num?)?.toDouble() ?? 50000,
      goalCurrentAmount: (json['goalCurrentAmount'] as num?)?.toDouble() ?? 15000,
      goalName: (json['goalName'] as String?) ?? 'Emergency Fund',
    );
  }

  @override
  List<Object?> get props => [
        id,
        categoryName,
        currentMonthlySpending,
        baselineCutAmount,
        minCutAmount,
        maxCutAmount,
        goalTargetAmount,
        goalCurrentAmount,
        goalName,
      ];
}

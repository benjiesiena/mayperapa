import 'package:flutter/foundation.dart';
import 'ai_action_draft.dart';

/// Represents a distinct financial scenario projection (e.g. Current Pace, Balanced Rebalance, Aggressive Saver).
@immutable
class FinancialScenarioOption {
  final String id;
  final String title;
  final String badge;
  final double discretionarySpend;
  final double monthlySavings;
  final double emergencyRunwayMonths;
  final int goalTargetMonths;
  final bool isRecommended;
  final AIActionDraft? actionDraft;

  const FinancialScenarioOption({
    required this.id,
    required this.title,
    required this.badge,
    required this.discretionarySpend,
    required this.monthlySavings,
    required this.emergencyRunwayMonths,
    required this.goalTargetMonths,
    this.isRecommended = false,
    this.actionDraft,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'badge': badge,
        'discretionarySpend': discretionarySpend,
        'monthlySavings': monthlySavings,
        'emergencyRunwayMonths': emergencyRunwayMonths,
        'goalTargetMonths': goalTargetMonths,
        'isRecommended': isRecommended,
        if (actionDraft != null) 'actionDraft': actionDraft!.toJson(),
      };

  factory FinancialScenarioOption.fromJson(Map<String, dynamic> json) {
    return FinancialScenarioOption(
      id: json['id'] as String,
      title: json['title'] as String,
      badge: json['badge'] as String? ?? '',
      discretionarySpend: (json['discretionarySpend'] as num).toDouble(),
      monthlySavings: (json['monthlySavings'] as num).toDouble(),
      emergencyRunwayMonths: (json['emergencyRunwayMonths'] as num).toDouble(),
      goalTargetMonths: (json['goalTargetMonths'] as num).toInt(),
      isRecommended: json['isRecommended'] as bool? ?? false,
      actionDraft: json['actionDraft'] != null
          ? AIActionDraft.fromJson(Map<String, dynamic>.from(json['actionDraft'] as Map))
          : null,
    );
  }
}

/// A structured multi-scenario projection matrix comparing alternative financial trajectories side-by-side.
@immutable
class ScenarioComparisonMatrix {
  final String title;
  final String aiVerdictSummary;
  final List<FinancialScenarioOption> scenarios;

  const ScenarioComparisonMatrix({
    required this.title,
    required this.aiVerdictSummary,
    required this.scenarios,
  });

  FinancialScenarioOption get recommendedScenario =>
      scenarios.firstWhere((s) => s.isRecommended, orElse: () => scenarios.first);

  Map<String, dynamic> toJson() => {
        'title': title,
        'aiVerdictSummary': aiVerdictSummary,
        'scenarios': [for (final s in scenarios) s.toJson()],
      };

  factory ScenarioComparisonMatrix.fromJson(Map<String, dynamic> json) {
    final rawScenarios = json['scenarios'] as List? ?? [];
    return ScenarioComparisonMatrix(
      title: json['title'] as String? ?? 'Financial Scenario Comparison',
      aiVerdictSummary: json['aiVerdictSummary'] as String? ?? '',
      scenarios: [
        for (final s in rawScenarios)
          FinancialScenarioOption.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
    );
  }
}

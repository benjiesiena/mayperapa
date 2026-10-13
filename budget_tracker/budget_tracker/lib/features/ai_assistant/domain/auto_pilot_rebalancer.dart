import 'package:flutter/foundation.dart';
import 'ai_action_draft.dart';
import 'ai_deliberation_engine.dart';

/// Represents the budget vs spending status of an individual category.
@immutable
class CategoryBudgetStatus {
  final String categoryName;
  final int? categoryId;
  final double budgetAmount;
  final double spentAmount;

  const CategoryBudgetStatus({
    required this.categoryName,
    this.categoryId,
    required this.budgetAmount,
    required this.spentAmount,
  });

  double get remaining => budgetAmount - spentAmount;
  double get deficit => spentAmount > budgetAmount ? spentAmount - budgetAmount : 0.0;
  double get surplus => budgetAmount > spentAmount ? budgetAmount - spentAmount : 0.0;
  double get burnRate => budgetAmount > 0 ? (spentAmount / budgetAmount) : (spentAmount > 0 ? 1.0 : 0.0);
}

/// A specific reallocation transfer from an underspent category to an overspent category.
@immutable
class RebalanceTransfer {
  final String fromCategory;
  final String toCategory;
  final double amount;
  final String rationale;

  const RebalanceTransfer({
    required this.fromCategory,
    required this.toCategory,
    required this.amount,
    required this.rationale,
  });
}

/// A generated rebalancing plan outlining deficit absorption, transfers, and updated allocations.
@immutable
class RebalancePlan {
  final bool isRebalanceNeeded;
  final double totalDeficit;
  final double totalSurplus;
  final List<CategoryBudgetStatus> deficitCategories;
  final List<CategoryBudgetStatus> surplusCategories;
  final List<RebalanceTransfer> transfers;
  final Map<String, double> updatedAllocations;

  const RebalancePlan({
    required this.isRebalanceNeeded,
    required this.totalDeficit,
    required this.totalSurplus,
    required this.deficitCategories,
    required this.surplusCategories,
    required this.transfers,
    required this.updatedAllocations,
  });

  /// Constructs an executable [AIActionDraft] that the user can confirm in 1 tap.
  AIActionDraft toActionDraft({
    required int userId,
    String? budgetName,
  }) {
    final title = budgetName ?? 'Auto-Pilot Budget Rebalance';
    final subtitle = 'Reallocate ₱${totalDeficit.toStringAsFixed(0)} to eliminate deficits across ${deficitCategories.length} categories';

    final totalBudget = updatedAllocations.values.fold<double>(0.0, (sum, val) => sum + val);

    return AIActionDraft(
      id: 'rebalance_${DateTime.now().millisecondsSinceEpoch}',
      type: AIActionType.createBudget,
      title: title,
      subtitle: subtitle,
      payload: {
        'name': title,
        'totalBudget': totalBudget,
        'categoryAllocations': Map<String, dynamic>.from(updatedAllocations),
        'transfers': [
          for (final t in transfers)
            {
              'from': t.fromCategory,
              'to': t.toCategory,
              'amount': t.amount,
              'rationale': t.rationale,
            }
        ],
      },
      createdAt: DateTime.now(),
    );
  }
}

/// Domain engine responsible for detecting category burn rate pacing,
/// identifying safe surpluses, and constructing zero-deficit rebalancing plans.
class AutoPilotRebalancer {
  final AIDeliberationEngine deliberationEngine;

  const AutoPilotRebalancer({
    this.deliberationEngine = const AIDeliberationEngine(),
  });

  /// Analyzes category budget statuses and calculates transfer proposals.
  RebalancePlan calculateRebalance({
    required List<CategoryBudgetStatus> categoryStatuses,
    double dayOfMonthProgress = 0.5,
  }) {
    final deficitCategories = <CategoryBudgetStatus>[];
    final surplusCategories = <CategoryBudgetStatus>[];
    double totalDeficit = 0.0;
    double totalSurplus = 0.0;

    for (final cat in categoryStatuses) {
      if (cat.spentAmount > cat.budgetAmount) {
        deficitCategories.add(cat);
        totalDeficit += cat.deficit;
      } else if (cat.budgetAmount > cat.spentAmount) {
        surplusCategories.add(cat);
        totalSurplus += cat.surplus;
      }
    }

    if (deficitCategories.isEmpty) {
      final initialAllocations = {
        for (final c in categoryStatuses) c.categoryName: c.budgetAmount,
      };
      return RebalancePlan(
        isRebalanceNeeded: false,
        totalDeficit: 0.0,
        totalSurplus: totalSurplus,
        deficitCategories: const [],
        surplusCategories: surplusCategories,
        transfers: const [],
        updatedAllocations: initialAllocations,
      );
    }

    // Rank surplus categories: Discretionary wants first, essential needs last
    final surplusNames = surplusCategories.map((c) => c.categoryName).toList();
    final rankedNames = deliberationEngine.rankSacrificeCandidates(surplusNames);

    // Map remaining available pool per surplus category
    final availableSurplus = <String, double>{
      for (final c in surplusCategories) c.categoryName: c.surplus,
    };

    final transfers = <RebalanceTransfer>[];
    final updatedAllocations = <String, double>{
      for (final c in categoryStatuses) c.categoryName: c.budgetAmount,
    };

    for (final def in deficitCategories) {
      double needed = def.deficit;

      for (final srcName in rankedNames) {
        if (needed <= 0.0001) break;

        final avail = availableSurplus[srcName] ?? 0.0;
        if (avail <= 0.0001) continue;

        final transferAmount = avail >= needed ? needed : avail;
        availableSurplus[srcName] = avail - transferAmount;
        needed -= transferAmount;

        transfers.add(
          RebalanceTransfer(
            fromCategory: srcName,
            toCategory: def.categoryName,
            amount: transferAmount,
            rationale:
                'Reallocate ₱${transferAmount.toStringAsFixed(0)} from discretionary $srcName to absorb ₱${def.deficit.toStringAsFixed(0)} deficit in ${def.categoryName}.',
          ),
        );

        updatedAllocations[srcName] = (updatedAllocations[srcName] ?? 0.0) - transferAmount;
        updatedAllocations[def.categoryName] = (updatedAllocations[def.categoryName] ?? 0.0) + transferAmount;
      }
    }

    return RebalancePlan(
      isRebalanceNeeded: true,
      totalDeficit: totalDeficit,
      totalSurplus: totalSurplus,
      deficitCategories: deficitCategories,
      surplusCategories: surplusCategories,
      transfers: transfers,
      updatedAllocations: updatedAllocations,
    );
  }
}

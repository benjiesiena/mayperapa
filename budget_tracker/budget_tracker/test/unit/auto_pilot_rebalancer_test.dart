import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_draft.dart';
import 'package:mayperapa/features/ai_assistant/domain/auto_pilot_rebalancer.dart';

void main() {
  group('AutoPilotRebalancer Domain Tests (TDD)', () {
    const rebalancer = AutoPilotRebalancer();

    test('returns isRebalanceNeeded=false when all categories have healthy buffer', () {
      final categories = [
        const CategoryBudgetStatus(
          categoryName: 'Groceries',
          budgetAmount: 10000,
          spentAmount: 4000,
        ),
        const CategoryBudgetStatus(
          categoryName: 'Dining Out',
          budgetAmount: 5000,
          spentAmount: 2000,
        ),
      ];

      final plan = rebalancer.calculateRebalance(
        categoryStatuses: categories,
        dayOfMonthProgress: 0.5,
      );

      expect(plan.isRebalanceNeeded, isFalse);
      expect(plan.totalDeficit, 0.0);
      expect(plan.transfers, isEmpty);
    });

    test('detects category deficit and reallocates surplus from discretionary pool first', () {
      final categories = [
        const CategoryBudgetStatus(
          categoryName: 'Groceries',
          budgetAmount: 8000,
          spentAmount: 9500, // ₱1,500 deficit
        ),
        const CategoryBudgetStatus(
          categoryName: 'Dining Out',
          budgetAmount: 6000,
          spentAmount: 2000, // ₱4,000 remaining surplus (Discretionary)
        ),
        const CategoryBudgetStatus(
          categoryName: 'Electricity & Bills',
          budgetAmount: 5000,
          spentAmount: 3000, // ₱2,000 remaining surplus (Essential)
        ),
      ];

      final plan = rebalancer.calculateRebalance(
        categoryStatuses: categories,
        dayOfMonthProgress: 0.7,
      );

      expect(plan.isRebalanceNeeded, isTrue);
      expect(plan.totalDeficit, 1500.0);
      expect(plan.transfers, isNotEmpty);

      // Axiom 3 enforcement: Transfer MUST come from 'Dining Out' (discretionary)
      // rather than 'Electricity & Bills' (essential)
      final primaryTransfer = plan.transfers.first;
      expect(primaryTransfer.fromCategory, 'Dining Out');
      expect(primaryTransfer.toCategory, 'Groceries');
      expect(primaryTransfer.amount, greaterThanOrEqualTo(1500.0));
      expect(primaryTransfer.rationale, contains('discretionary'));
    });

    test('generates executable AIActionDraft with rebalanced category allocations', () {
      final categories = [
        const CategoryBudgetStatus(
          categoryName: 'Transportation',
          budgetAmount: 3000,
          spentAmount: 4000, // ₱1,000 deficit
        ),
        const CategoryBudgetStatus(
          categoryName: 'Shopping',
          budgetAmount: 5000,
          spentAmount: 1000, // ₱4,000 surplus
        ),
      ];

      final plan = rebalancer.calculateRebalance(
        categoryStatuses: categories,
        dayOfMonthProgress: 0.5,
      );

      final draft = plan.toActionDraft(userId: 1, budgetName: 'Mid-Month Auto-Pilot Rebalance');

      expect(draft.type, AIActionType.createBudget);
      expect(draft.title, contains('Rebalance'));
      final allocations = draft.payload['categoryAllocations'] as Map<String, dynamic>;
      expect(allocations['Transportation'], 4000.0); // Absorbed deficit
      expect(allocations['Shopping'], 4000.0); // Reduced by 1,000
    });
  });
}

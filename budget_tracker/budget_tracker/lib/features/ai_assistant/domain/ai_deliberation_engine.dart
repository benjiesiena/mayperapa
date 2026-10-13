import 'package:flutter/foundation.dart';

/// Recommendations rendered by the financial deliberation engine.
enum DeliberationRecommendation {
  payOffDebtFirst,
  buildEmergencyFundFirst,
  splitBalanced,
  aggressiveCostCut,
}

/// Represents an evaluation of debt payoff versus maintaining savings liquidity.
@immutable
class DebtVsSavingsEvaluation {
  final DeliberationRecommendation recommendation;
  final String primaryRationale;
  final bool isEmergencyBufferSafeAfterPayoff;
  final String suggestedStrategy;

  const DebtVsSavingsEvaluation({
    required this.recommendation,
    required this.primaryRationale,
    required this.isEmergencyBufferSafeAfterPayoff,
    required this.suggestedStrategy,
  });
}

/// Curated deliberation exemplar showcasing high-conviction cognitive reasoning.
@immutable
class DeliberationExemplar {
  final String title;
  final String userPrompt;
  final List<String> deliberationSteps;
  final String mayaVerdict;
  final Map<String, dynamic>? suggestedActions;

  const DeliberationExemplar({
    required this.title,
    required this.userPrompt,
    required this.deliberationSteps,
    required this.mayaVerdict,
    this.suggestedActions,
  });
}

/// Core domain engine for opinionated, mathematically grounded financial cognition.
///
/// Implements the 4 Foundational Financial Deliberation Axioms:
/// 1. LIQUIDITY DEFENSE FIRST
/// 2. GUARANTEED RETURN PRIORITY
/// 3. SACRIFICE HIERARCHY
/// 4. TAKE AN OPINIONATED STANCE
class AIDeliberationEngine {
  const AIDeliberationEngine();

  /// Returns system directives and rules for deliberation protocols.
  String getDeliberationDirectives() {
    return '''
### FOUNDATIONAL FINANCIAL DELIBERATION PROTOCOL (MAYA COGNITIVE AXIOMS)
You are an autonomous, senior financial partner. You do NOT give passive, non-committal answers ("it depends", "you can choose either").
You evaluate the user's dilemma against 4 non-negotiable axioms and formulate an opinionated, conviction-backed verdict:

1. LIQUIDITY DEFENSE FIRST:
   - Always verify and protect at least 1 month of essential expenses (food, rent, critical utilities) before approving aggressive investments or luxury purchases.
   - If liquidity falls below the defense threshold, flag an urgent warning immediately.

2. GUARANTEED RETURN PRIORITY:
   - High-interest debt (>12% APR) is a guaranteed negative compounding drain. Paying it off yields an instant, risk-free return equal to the APR.
   - Prioritize high-interest debt elimination over low-yield cash accounts once a minimum liquidity buffer exists.

3. SACRIFICE HIERARCHY:
   - When facing unexpected deficits or funding a high-priority goal, always sacrifice discretionary wants (Entertainment, Dining Out, Shopping, Subscriptions) first.
   - Never compromise non-discretionary necessities (Groceries, Utilities, Healthcare, Debt Minimums).

4. TAKE AN OPINIONATED STANCE:
   - Formulate a clear recommendation: "My recommendation is [Action] because mathematically [Reasoning]. If [Trade-off], adopt [Alternative Strategy]."
   - Never leave the user hanging without a concrete execution step or actionable next move.
''';
  }

  /// Returns curated Golden Exemplars demonstrating multi-step cognitive deliberation.
  List<DeliberationExemplar> getGoldenExemplars() {
    return const [
      DeliberationExemplar(
        title: 'Fixed Cost Shock (Rent / Utility Increase)',
        userPrompt: 'My landlord just raised my rent by ₱3,000 this month. How should I adjust my budget?',
        deliberationSteps: [
          'Audit current discretionary buffer: Dining Out (₱4,500), Entertainment (₱2,000), Shopping (₱2,500). Total: ₱9,000.',
          'Identify sacrifice candidates using Axiom 3 (Sacrifice Hierarchy).',
          'Calculate rebalance delta: absorb ₱3,000 rent shock without touching emergency savings.',
          'Formulate action bundle: trim Dining Out by ₱2,000 and Shopping by ₱1,000 to maintain zero-deficit balance.',
        ],
        mayaVerdict:
            'My clear recommendation is to reallocate ₱3,000 from your discretionary pool rather than dipping into your emergency fund. Trimming ₱2,000 from Dining Out and ₱1,000 from Shopping fully absorbs the rent increase while keeping your long-term wealth building intact.',
        suggestedActions: {
          'action': 'rebalance_budget',
          'adjustments': [
            {'category': 'Dining Out', 'delta': -2000.0},
            {'category': 'Shopping', 'delta': -1000.0},
            {'category': 'Rent', 'delta': 3000.0},
          ],
        },
      ),
      DeliberationExemplar(
        title: 'Debt vs Savings (High-Interest Credit Card vs Emergency Fund)',
        userPrompt: 'I have ₱15,000 in credit card debt at 36% APR and ₱25,000 in savings. Should I pay it off or keep saving?',
        deliberationSteps: [
          'Verify essential monthly expenses: ₱12,000/mo.',
          'Assess liquidity buffer under Axiom 1: ₱25,000 - ₱15,000 = ₱10,000 remaining buffer (< ₱12,000 safe threshold).',
          'Assess interest drain under Axiom 2: 36.0% APR costs ₱450/month in pure dead interest.',
          'Balance risk vs guaranteed return: staged payoff preserves minimum liquidity while stopping maximum bleed.',
        ],
        mayaVerdict:
            'Guaranteed return: paying 36.0% APR debt gives an instant 36% risk-free return, beating any savings account. However, paying the full ₱15,000 leaves you with ₱10,000 (slightly below 1 month of essential expenses). My recommendation is a staged payoff: pay ₱10,000 immediately today, stop all new card charges, and allocate ₱2,500 over the next 2 months to clear the remaining balance safely.',
        suggestedActions: {
          'action': 'staged_debt_payoff',
          'initialPayment': 10000.0,
          'monthlyTarget': 2500.0,
        },
      ),
      DeliberationExemplar(
        title: 'Discretionary Splurge vs Goal Runway (Gadget / Trip Purchase)',
        userPrompt: 'I want to buy a new tablet for ₱22,000. Can I afford it right now?',
        deliberationSteps: [
          'Check current liquid cash: ₱38,000.',
          'Check monthly essential burn: ₱18,000 (1-month buffer requirement: ₱18,000).',
          'Calculate post-purchase liquidity: ₱38,000 - ₱22,000 = ₱16,000 (drops below 1-month defense runway).',
          'Apply Axiom 1 (Liquidity Defense First).',
        ],
        mayaVerdict:
            'My recommendation is to pause this purchase for 60 days. Spending ₱22,000 today drops your available cushion to ₱16,000, leaving you under 1 month of essential safety runway. If an unexpected emergency occurs, you would be forced into debt. Instead, save ₱7,500/month for 3 months to buy it completely debt-free without endangering your safety net.',
        suggestedActions: {
          'action': 'create_savings_goal',
          'goalName': 'Tablet Purchase',
          'targetAmount': 22000.0,
          'monthlyContribution': 7500.0,
        },
      ),
    ];
  }

  /// Evaluates whether debt repayment or cash savings preservation should take priority.
  DebtVsSavingsEvaluation evaluateDebtVsSavingsPriority({
    required double debtAmount,
    required double debtAprPercent,
    required double savingsBalance,
    required double savingsYieldPercent,
    required double monthlyEssentialExpenses,
  }) {
    final remainingSavings = savingsBalance - debtAmount;
    final isBufferSafe = remainingSavings >= monthlyEssentialExpenses;

    if (debtAprPercent > savingsYieldPercent) {
      final rationale =
          'At ${debtAprPercent.toStringAsFixed(1)}% APR, debt interest significantly outpaces ${savingsYieldPercent.toStringAsFixed(1)}% savings yield. Eliminating debt delivers an immediate risk-free return.';

      final strategy = isBufferSafe
          ? 'Immediate lump-sum payoff leaving safe emergency buffer intact.'
          : 'Adopt staged payoff: pay down a major portion while preserving minimum 1-month essential liquidity buffer.';

      return DebtVsSavingsEvaluation(
        recommendation: DeliberationRecommendation.payOffDebtFirst,
        primaryRationale: rationale,
        isEmergencyBufferSafeAfterPayoff: isBufferSafe,
        suggestedStrategy: strategy,
      );
    } else {
      return DebtVsSavingsEvaluation(
        recommendation: DeliberationRecommendation.buildEmergencyFundFirst,
        primaryRationale:
            'Debt rate of ${debtAprPercent.toStringAsFixed(1)}% is lower than or comparable to yield. Preserving liquidity takes precedence.',
        isEmergencyBufferSafeAfterPayoff: isBufferSafe,
        suggestedStrategy: 'Continue minimum payments while strengthening liquid reserves.',
      );
    }
  }

  /// Orders categories so that discretionary wants are prioritized for sacrifice
  /// before non-negotiable essential living expenses.
  List<String> rankSacrificeCandidates(List<String> categories) {
    const discretionaryKeywords = [
      'dining',
      'restaurant',
      'shopping',
      'entertainment',
      'leisure',
      'subscription',
      'hobbies',
      'travel',
      'fun',
      'luxury',
      'gadget',
    ];

    const essentialKeywords = [
      'bill',
      'utilit',
      'grocer',
      'food',
      'rent',
      'mortgage',
      'hous',
      'health',
      'medic',
      'insurance',
      'debt',
      'loan',
      'transport',
      'fuel',
      'gas',
    ];

    int getScore(String category) {
      final lower = category.toLowerCase();
      for (final kw in discretionaryKeywords) {
        if (lower.contains(kw)) return 0; // Top sacrifice candidate
      }
      for (final kw in essentialKeywords) {
        if (lower.contains(kw)) return 2; // Essential: protect
      }
      return 1; // Neutral
    }

    final sorted = List<String>.from(categories);
    sorted.sort((a, b) {
      final scoreA = getScore(a);
      final scoreB = getScore(b);
      if (scoreA != scoreB) {
        return scoreA.compareTo(scoreB);
      }
      return a.compareTo(b);
    });

    return sorted;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/infrastructure/ai/tools/ai_response_validator.dart';

void main() {
  const validator = AIResponseValidator();

  group('percentage handling', () {
    test('does not flag an over-100% budget percentage as fabricated', () {
      // percentUsed is stored as a fraction (1.2 == 120%) in tool results,
      // but response text prints the whole-number percentage ("120%").
      // This was silently discarding correct over-budget answers.
      final result = validator.validate(
        response: "You've used 120% of your August budget (₱1,200 of ₱1,000). "
            'You are ₱200 over budget.',
        toolResults: {
          'get_budget_status': {
            'success': true,
            'data': {
              'budgetName': 'August',
              'totalBudget': 1000,
              'spent': 1200,
              'remaining': -200,
              'percentUsed': 1.2,
            },
          },
        },
        questionNeedsData: true,
      );
      expect(result.isValid, isTrue);
    });

    test('does not flag a fully-complete goal (100%) as fabricated', () {
      final result = validator.validate(
        response: 'Emergency Fund is at 100% — fully funded!',
        toolResults: {
          'get_all_goals': {
            'success': true,
            'data': {
              'goals': [
                {'name': 'Emergency Fund', 'progressPercentage': 1.0},
              ],
            },
          },
        },
        questionNeedsData: true,
      );
      expect(result.isValid, isTrue);
    });

    test('still flags a genuinely fabricated large figure', () {
      final result = validator.validate(
        response: 'Your balance is ₱999999.',
        toolResults: {
          'get_current_balance': {
            'success': true,
            'data': {'balance': 500},
          },
        },
        questionNeedsData: true,
      );
      expect(result.isValid, isFalse);
    });

    test('does not flag calendar years or time periods as fabricated figures', () {
      final result = validator.validate(
        response: 'In October 2026, you spent ₱1,200 over the last 180 days.',
        toolResults: {
          'get_monthly_expenses': {
            'success': true,
            'data': {'expenses': 1200},
          },
        },
        questionNeedsData: true,
      );
      expect(result.isValid, isTrue);
    });

    test('does not flag illustrative quoted commands or suggestion blocks as fabricated figures', () {
      final result = validator.validate(
        response: 'Your current balance is ₱500.\n\n'
            '**Proactive Suggestion:** Would you like to set a target? Say *"Set food budget to ₱5,000"* or *"Create goal ₱10,000"*.',
        toolResults: {
          'get_current_balance': {
            'success': true,
            'data': {'balance': 500},
          },
        },
        questionNeedsData: true,
      );
      expect(result.isValid, isTrue);
    });

    test('does not flag spending response suggestion', () {
      const text = "You've spent **₱850.00** this month so far.\n\n"
          "Top spending categories:\n"
          "• **Category #1:** ₱850.00\n\n"
          "**Proactive Suggestion:** Would you like to set a target limit on your top category? Just tell me: *\"Set food budget to ₱5,000\"* or ask *\"Can I afford ₱1,500?\"*";
      final result = validator.validate(
        response: text,
        toolResults: {
          'get_monthly_expenses': {'expenses': 850},
          'get_top_spending_categories': {
            'topCategories': [
              {'categoryName': 'Category #1', 'amount': 850}
            ]
          }
        },
        questionNeedsData: true,
      );
      expect(result.isValid, isTrue, reason: result.error);
    });
  });

  test('flags a data question answered with no tool results at all', () {
    final result = validator.validate(
      response: 'You spent ₱2000 this month.',
      toolResults: const {},
      questionNeedsData: true,
    );
    expect(result.isValid, isFalse);
  });

  test('flags fabricated currency figures (e.g. ₱18,500 on flights) when not backed by tool data', () {
    final result = validator.validate(
      response: 'Based on your transaction history, you spent ₱18,500 on flights to Tokyo.',
      toolResults: const {},
      questionNeedsData: false, // Even if questionNeedsData was false!
    );
    expect(result.isValid, isFalse);
    expect(result.error, contains('18500'));
  });

  test('allows truthful missing-data responses with zero fabricated numbers', () {
    final result = validator.validate(
      response: 'I checked your MayPeraPa records, and there are no recorded transactions or data for flights to Tokyo.',
      toolResults: const {},
      questionNeedsData: true,
    );
    expect(result.isValid, isTrue);
  });
}

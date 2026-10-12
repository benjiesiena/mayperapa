import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/infrastructure/ai/runtime/rule_based_ai_engine.dart';

void main() {
  group('RuleBasedAIEngine — Conversational Financial Coaching Tests', () {
    late RuleBasedAIEngine engine;

    setUp(() {
      engine = RuleBasedAIEngine();
    });

    test('routes 50/30/20 rule query and returns structured advice with zero tool calls', () async {
      final decision = await engine.planToolCalls(
        userMessage: 'What is the 50/30/20 rule?',
        availableTools: [],
        conversationHistory: [],
      );

      expect(decision.toolNamesToCall, isEmpty);

      final reply = await engine.generateResponse(
        userMessage: 'What is the 50/30/20 rule?',
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains('50/30/20'));
      expect(reply, contains('Needs'));
      expect(reply, contains('Wants'));
      expect(reply, contains('Savings'));
    });

    test('routes emergency fund advice query and returns practical steps', () async {
      final decision = await engine.planToolCalls(
        userMessage: 'How do I start an emergency fund?',
        availableTools: [],
        conversationHistory: [],
      );

      expect(decision.toolNamesToCall, isEmpty);

      final reply = await engine.generateResponse(
        userMessage: 'How do I start an emergency fund?',
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains('Emergency Fund'));
      expect(reply, contains('3 to 6 months'));
    });

    test('routes debt payoff strategy query (avalanche vs snowball)', () async {
      final reply = await engine.generateResponse(
        userMessage: 'Which debt should I pay off first, snowball or avalanche?',
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains('Debt Avalanche'));
      expect(reply, contains('Debt Snowball'));
    });

    test('routes impulse spending and shopping control query', () async {
      final reply = await engine.generateResponse(
        userMessage: 'How can I stop impulse spending?',
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains('24-Hour Rule'));
      expect(reply, contains('Hours of Life'));
    });

    test('routes paycheck and salary allocation routine', () async {
      final reply = await engine.generateResponse(
        userMessage: 'How should I budget my salary paycheck?',
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains('Pay Yourself First'));
      expect(reply, contains('Fixed Essentials'));
    });

    test('routes financial stress with calming, supportive coaching', () async {
      final reply = await engine.generateResponse(
        userMessage: "I'm stressed about money and feeling broke",
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains('Take a deep breath'));
      expect(reply, contains('You'));
    });

    test('routes gratitude warmly', () async {
      final reply = await engine.generateResponse(
        userMessage: 'Thank you for your help, awesome advice!',
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains("You're very welcome"));
    });

    test('greeting introduces Maya agent and proactive suggestions', () async {
      final reply = await engine.generateResponse(
        userMessage: 'Hello',
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains('Maya'));
      expect(reply, contains('MayPeraPa'));
      expect(reply, contains('AI Financial Agent'));
      expect(reply, contains('proactive'));
      expect(reply, contains('implement it'));
      expect(reply, contains('revoke it'));
    });

    test('saying Maya or asking name triggers Maya greeting', () async {
      final reply = await engine.generateResponse(
        userMessage: 'Maya, what is your name?',
        toolResults: {},
        conversationHistory: [],
      );

      expect(reply, contains('Maya'));
      expect(reply, contains('MayPeraPa'));
    });

    test('balance response includes proactive financial suggestions', () async {
      final reply = await engine.generateResponse(
        userMessage: 'What is my current balance?',
        toolResults: {
          'get_current_balance': {'balance': 15000.0}
        },
        conversationHistory: [],
      );

      expect(reply, contains('15,000'));
      expect(reply, contains('Proactive Suggestion'));
    });
  });
}

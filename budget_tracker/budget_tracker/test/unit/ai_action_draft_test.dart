import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/infrastructure/ai/runtime/rule_based_ai_engine.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_action_draft.dart';

void main() {
  group('AIActionDraft Intent & Extraction Tests (TDD)', () {
    late RuleBasedAIEngine engine;

    setUp(() {
      engine = RuleBasedAIEngine();
    });

    test('extracts expense transaction from "I spent ₱150 on coffee today with cash"', () async {
      final draft = await engine.extractActionDraft(
        userMessage: 'I spent ₱150 on coffee today with cash',
        toolResults: {},
        conversationHistory: [],
      );

      expect(draft, isNotNull);
      expect(draft!.type, equals(AIActionType.createTransaction));
      expect(draft.payload['isIncome'], isFalse);
      expect(draft.payload['amount'], equals(150.0));
      expect(draft.payload['categoryName'], equals('Food & Dining'));
      expect(draft.payload['accountName'], equals('Cash'));
    });

    test('extracts income transaction from "Received ₱35,000 salary from employer"', () async {
      final draft = await engine.extractActionDraft(
        userMessage: 'Received ₱35,000 salary from employer',
        toolResults: {},
        conversationHistory: [],
      );

      expect(draft, isNotNull);
      expect(draft!.type, equals(AIActionType.createTransaction));
      expect(draft.payload['isIncome'], isTrue);
      expect(draft.payload['amount'], equals(35000.0));
      expect(draft.payload['categoryName'], equals('Salary'));
    });

    test('extracts budget creation from "Set food budget to ₱6,000 for this month"', () async {
      final draft = await engine.extractActionDraft(
        userMessage: 'Set food budget to ₱6,000 for this month',
        toolResults: {},
        conversationHistory: [],
      );

      expect(draft, isNotNull);
      expect(draft!.type, equals(AIActionType.createBudget));
      expect(draft.payload['amount'], equals(6000.0));
      expect(draft.payload['categoryName'], equals('Food & Dining'));
    });

    test('extracts goal creation from "Create a goal for Emergency Fund target ₱50,000"', () async {
      final draft = await engine.extractActionDraft(
        userMessage: 'Create a goal for Emergency Fund target ₱50,000',
        toolResults: {},
        conversationHistory: [],
      );

      expect(draft, isNotNull);
      expect(draft!.type, equals(AIActionType.createGoal));
      expect(draft.payload['name'], equals('Emergency Fund'));
      expect(draft.payload['targetAmount'], equals(50000.0));
    });

    test('extracts 50/30/20 plan from "Give me a plan on how to spend and save my ₱30,000 salary"', () async {
      final draft = await engine.extractActionDraft(
        userMessage: 'Give me a plan on how to spend and save my ₱30,000 salary',
        toolResults: {},
        conversationHistory: [],
      );

      expect(draft, isNotNull);
      expect(draft!.type, equals(AIActionType.applyFinancialPlan));
      expect(draft.payload['monthlyIncome'], equals(30000.0));
      expect(draft.payload['needsAmount'], equals(15000.0));
      expect(draft.payload['wantsAmount'], equals(9000.0));
      expect(draft.payload['savingsAmount'], equals(6000.0));
    });

    test('returns null for non-action queries', () async {
      final draft = await engine.extractActionDraft(
        userMessage: 'What is my current balance?',
        toolResults: {},
        conversationHistory: [],
      );

      expect(draft, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/features/ai_assistant/domain/ai_action_draft.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_orchestrator.dart';
import 'package:mayperapa/features/ai_assistant/domain/ai_scenario_sandbox.dart';
import 'package:mayperapa/features/ai_assistant/domain/scenario_comparison_matrix.dart';
import 'package:mayperapa/features/ai_assistant/domain/user_financial_profile_repository.dart';
import 'package:mayperapa/infrastructure/ai/runtime/ai_engine.dart';
import 'package:mayperapa/infrastructure/ai/tools/ai_response_validator.dart';
import 'package:mayperapa/infrastructure/ai/tools/ai_tool.dart';
import 'package:mayperapa/infrastructure/ai/tools/financial_tools_registry.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/account.dart';
import 'package:mayperapa/shared/domain/entities/category.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';
import 'package:mayperapa/shared/domain/repositories/account_repository.dart';
import 'package:mayperapa/shared/domain/repositories/budget_repository.dart';
import 'package:mayperapa/shared/domain/repositories/category_repository.dart';
import 'package:mayperapa/shared/domain/repositories/goal_repository.dart';
import 'package:mayperapa/shared/domain/repositories/recurring_transaction_repository.dart';
import 'package:mayperapa/shared/domain/repositories/transaction_repository.dart';
import 'package:mayperapa/shared/domain/services/financial_calculator.dart';

class _FakeProfileRepository implements UserFinancialProfileRepository {
  UserFinancialProfile profile;
  _FakeProfileRepository(this.profile);

  @override
  Future<UserFinancialProfile> getProfile(int userId) async => profile;
  @override
  Future<void> saveProfile(UserFinancialProfile p) async => profile = p;
  @override
  Future<void> updateTone(int userId, MayaTone t) async => profile = profile.copyWith(coachingTone: t);
  @override
  Future<void> updatePaydays(int userId, List<int> days) async => profile = profile.copyWith(paydayDays: days);
  @override
  Future<void> addHabitNote(int userId, String note) async => profile = profile.copyWith(habitNotes: [...profile.habitNotes, note]);
  @override
  Future<void> removeHabitNote(int userId, String note) async => profile = profile.copyWith(habitNotes: profile.habitNotes.where((n) => n != note).toList());
  @override
  Future<void> clearMemory(int userId) async => profile = UserFinancialProfile.defaultProfile(userId);
}

class _RecordingEngine implements AIEngine {
  Map<String, Map<String, dynamic>> lastToolResults = const {};

  @override
  Future<bool> get isReady async => true;

  @override
  Future<AIEngineDecision> planToolCalls({
    required String userMessage,
    required List<AITool> availableTools,
    required List<AIEngineMessage> conversationHistory,
    Map<String, Map<String, dynamic>> accumulatedToolResults = const {},
  }) async {
    return const AIEngineDecision(toolNamesToCall: [], isTerminal: true);
  }

  @override
  Future<String> generateResponse({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
    required List<AIEngineMessage> conversationHistory,
  }) async {
    lastToolResults = toolResults;
    return 'Analysis complete based on profile.';
  }

  @override
  Future<AIActionDraft?> extractActionDraft({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
    required List<AIEngineMessage> conversationHistory,
  }) async => null;

  @override
  AIScenarioSandbox? extractScenarioSandbox({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
  }) => null;

  @override
  ScenarioComparisonMatrix? extractScenarioComparisonMatrix({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
  }) => null;
}

class _DummyTxnRepo implements TransactionRepository {
  @override
  Future<List<Transaction>> getAllForUser(int userId) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyAccRepo implements AccountRepository {
  @override
  Future<List<Account>> getAllForUser(int userId, {bool activeOnly = true}) async => [
        Account(id: 1, userId: userId, name: 'Main', type: AccountType.cash, currencyCode: 'PHP', balance: 10000, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyCatRepo implements CategoryRepository {
  @override
  Future<List<Category>> getAllForUser(int userId, {bool activeOnly = true}) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyBudgetRepo implements BudgetRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyGoalRepo implements GoalRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyRecurringRepo implements RecurringTransactionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Phase 5: Memory Injection & Persona Tuning Protocol Tests', () {
    late FinancialToolsRegistry toolsRegistry;

    setUp(() {
      toolsRegistry = FinancialToolsRegistry(
        userId: 1,
        transactionRepository: _DummyTxnRepo(),
        accountRepository: _DummyAccRepo(),
        categoryRepository: _DummyCatRepo(),
        budgetRepository: _DummyBudgetRepo(),
        goalRepository: _DummyGoalRepo(),
        recurringRepository: _DummyRecurringRepo(),
        calculator: const FinancialCalculator(),
      );
    });

    test('AIOrchestrator injects financial profile and creates reasoning step when memory is enabled', () async {
      final profile = UserFinancialProfile(
        userId: 1,
        monthlyIncome: 40000,
        paydayDays: const [15, 30],
        coachingTone: MayaTone.socraticChallenger,
        savingsAggressiveness: 'aggressive',
        habitNotes: const ['Prefers meal prepping', 'Saving for laptop'],
        aiMemoryEnabled: true,
        updatedAt: DateTime.now(),
      );

      final repo = _FakeProfileRepository(profile);
      final recordingEngine = _RecordingEngine();

      final orchestrator = AIOrchestrator(
        engine: recordingEngine,
        toolsRegistry: toolsRegistry,
        profileRepository: repo,
        validator: const AIResponseValidator(),
      );

      final reply = await orchestrator.sendMessage(
        userMessage: 'What is my financial status?',
        conversationId: 1,
        history: const [],
      );

      // Verify profile was injected into toolResults for the engine
      expect(recordingEngine.lastToolResults.containsKey('user_financial_profile'), isTrue);
      final injected = recordingEngine.lastToolResults['user_financial_profile']!;
      expect(injected['coachingTone'], 'socraticChallenger');
      expect(injected['coachingToneLabel'], 'Socratic Challenger');
      expect(injected['paydaySummary'], '15th and 30th of the month');

      // Verify reasoning step reflects the loaded profile and tone
      final profileStep = reply.reasoningSteps.firstWhere(
        (s) => s.title.contains('persona & memory'),
      );
      expect(profileStep, isNotNull);
      expect(profileStep.detail, contains('Socratic Challenger'));
      expect(profileStep.detail, contains('15th and 30th'));
    });

    test('AIOrchestrator skips memory injection when aiMemoryEnabled is false', () async {
      final profile = UserFinancialProfile(
        userId: 1,
        monthlyIncome: 40000,
        paydayDays: const [15, 30],
        coachingTone: MayaTone.directAnalyst,
        aiMemoryEnabled: false,
        updatedAt: DateTime.now(),
      );

      final repo = _FakeProfileRepository(profile);
      final recordingEngine = _RecordingEngine();

      final orchestrator = AIOrchestrator(
        engine: recordingEngine,
        toolsRegistry: toolsRegistry,
        profileRepository: repo,
        validator: const AIResponseValidator(),
      );

      final reply = await orchestrator.sendMessage(
        userMessage: 'What is my balance?',
        conversationId: 1,
        history: const [],
      );

      // Verify toolResults does not have user_financial_profile
      expect(recordingEngine.lastToolResults.containsKey('user_financial_profile'), isFalse);

      // Verify no memory reasoning step was added
      final hasMemoryStep = reply.reasoningSteps.any((s) => s.title.contains('persona & memory'));
      expect(hasMemoryStep, isFalse);
    });
  });
}

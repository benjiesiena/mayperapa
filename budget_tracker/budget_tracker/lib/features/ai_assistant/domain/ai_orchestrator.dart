import 'package:flutter/foundation.dart';

import '../../../infrastructure/ai/runtime/ai_engine.dart';
import '../../../infrastructure/ai/runtime/rule_based_ai_engine.dart';
import '../../../infrastructure/ai/tools/ai_response_validator.dart';
import '../../../infrastructure/ai/tools/financial_tools_registry.dart';
import 'ai_message.dart';
import 'ai_reasoning_step.dart';
import 'user_financial_profile_repository.dart';

/// The AI Orchestrator from PRD 4.2 / 6.1 ("Conversation Manager, Intent
/// Detection, Tool Router" + "Response Validator"). This is the single
/// entry point the chat UI calls — it never talks to the engine or the
/// tools directly, so swapping the rule-based engine for a real on-device
/// model only requires a different [AIEngine] implementation.
class AIOrchestrator {
  AIOrchestrator({
    required this.engine,
    required this.toolsRegistry,
    this.profileRepository,
    this.validator = const AIResponseValidator(),
  });

  final AIEngine engine;
  final FinancialToolsRegistry toolsRegistry;
  final UserFinancialProfileRepository? profileRepository;
  final AIResponseValidator validator;

  /// Sends one user turn through the full pipeline: plan tool calls -> run
  /// tools -> generate response -> validate. Returns the assistant's
  /// message with its complete Chain-of-Thought reasoning steps and timing.
  Future<AIMessage> sendMessage({
    required String userMessage,
    required int conversationId,
    required List<AIEngineMessage> history,
  }) async {
    final stopwatch = Stopwatch()..start();
    final reasoningSteps = <AIReasoningStep>[];

    debugPrint('AIOrchestrator: Processing message: "$userMessage"');
    debugPrint('AIOrchestrator: Engine type: ${engine.runtimeType}');
    debugPrint('AIOrchestrator: Conversation ID: $conversationId');

    final tools = toolsRegistry.buildTools();
    final toolsByName = {for (final t in tools) t.name: t};

    debugPrint('AIOrchestrator: Available tools: ${tools.length}');

    final toolResults = <String, Map<String, dynamic>>{};
    final allToolsCalled = <String>{};

    // Task 5.2: Memory Injection Protocol
    if (profileRepository != null) {
      final memoryWatch = Stopwatch()..start();
      try {
        final profile = await profileRepository!.getProfile(toolsRegistry.userId);
        memoryWatch.stop();
        if (profile.aiMemoryEnabled) {
          toolResults['user_financial_profile'] = profile.toJson();
          reasoningSteps.add(AIReasoningStep(
            title: 'Applying personalized coaching persona & memory',
            detail: 'Loaded profile: ${profile.coachingTone.label} tone with payday cadence (${profile.paydaySummary}).',
            type: AIReasoningStepType.inspect,
            timestamp: DateTime.now(),
            durationMs: memoryWatch.elapsedMilliseconds,
          ));
        }
      } catch (e) {
        debugPrint('AIOrchestrator: Memory injection skipped: $e');
      }
    }

    // Autonomous ReAct Cognitive Loop: (Reason -> Act -> Observe -> Reflect)
    const maxIterations = 3;
    int iteration = 0;

    while (iteration < maxIterations) {
      iteration++;
      final planWatch = Stopwatch()..start();
      final decision = await engine.planToolCalls(
        userMessage: userMessage,
        availableTools: tools,
        conversationHistory: history,
        accumulatedToolResults: toolResults,
      );
      planWatch.stop();

      if (decision.toolNamesToCall.isEmpty || decision.isTerminal) {
        if (iteration == 1 && decision.toolNamesToCall.isEmpty) {
          reasoningSteps.add(AIReasoningStep(
            title: 'Analyzing financial inquiry & framework principles',
            detail: 'Formulating strategic advisory based on financial rules and coaching models.',
            type: AIReasoningStepType.plan,
            timestamp: DateTime.now(),
            durationMs: planWatch.elapsedMilliseconds,
          ));
        }
        break;
      }

      final newTools = decision.toolNamesToCall.where((t) => !toolResults.containsKey(t)).toList();
      if (newTools.isEmpty) {
        break;
      }

      final planTitle = iteration == 1
          ? 'Evaluating query and planning data retrieval'
          : 'Reflecting on observations & planning follow-up verification (Phase $iteration)';
      final planDetail = iteration == 1
          ? 'Identified verification required via ${newTools.length} financial tool(s).'
          : 'Chaining follow-up verification via ${newTools.join(', ')} based on prior findings.';

      reasoningSteps.add(AIReasoningStep(
        title: planTitle,
        detail: planDetail,
        type: AIReasoningStepType.plan,
        timestamp: DateTime.now(),
        durationMs: planWatch.elapsedMilliseconds,
      ));

      for (final toolName in newTools) {
        final tool = toolsByName[toolName];
        if (tool == null) continue;
        allToolsCalled.add(toolName);
        final args = decision.toolArgs[toolName] ?? const {};
        debugPrint('AIOrchestrator: [Iteration $iteration] Executing tool: $toolName with args: $args');

        final toolWatch = Stopwatch()..start();
        final result = await tool.execute(args);
        toolWatch.stop();

        debugPrint('AIOrchestrator: Tool $toolName result: success=${result.success}');
        toolResults[toolName] = result.success ? result.data : {'error': result.error ?? 'Tool call failed.'};

        reasoningSteps.add(_buildToolReasoningStep(
          toolName: toolName,
          result: result.success ? result.data : null,
          durationMs: toolWatch.elapsedMilliseconds,
        ));
      }

      if (decision.isTerminal) {
        break;
      }
    }

    debugPrint('AIOrchestrator: Tool results gathered: ${toolResults.keys}');

    final synthesisWatch = Stopwatch()..start();
    final responseText = await engine.generateResponse(
      userMessage: userMessage,
      toolResults: toolResults,
      conversationHistory: history,
    );

    debugPrint('AIOrchestrator: Response generated $responseText');

    final actionDraft = await engine.extractActionDraft(
      userMessage: userMessage,
      toolResults: toolResults,
      conversationHistory: history,
    );

    final scenarioSandbox = engine.extractScenarioSandbox(
      userMessage: userMessage,
      toolResults: toolResults,
    );

    final scenarioComparisonMatrix = engine.extractScenarioComparisonMatrix(
      userMessage: userMessage,
      toolResults: toolResults,
    );

    final isDataSeeking = allToolsCalled.isNotEmpty || _isDataSeekingQuery(userMessage);
    final validation = validator.validate(
      response: responseText,
      toolResults: toolResults,
      questionNeedsData: isDataSeeking,
    );

    String finalText = responseText;
    if (!validation.isValid) {
      debugPrint('AI response failed validation: ${validation.error}. Falling back to verified deterministic engine.');
      final fallbackEngine = RuleBasedAIEngine();
      final fallbackText = await fallbackEngine.generateResponse(
        userMessage: userMessage,
        toolResults: toolResults,
        conversationHistory: history,
      );
      final fallbackValidation = validator.validate(
        response: fallbackText,
        toolResults: toolResults,
        questionNeedsData: isDataSeeking,
      );
      finalText = fallbackValidation.isValid
          ? fallbackText
          : "I searched your MayPeraPa records, but could not verify that financial figure. Could you clarify or rephrase?";
    }
    synthesisWatch.stop();

    reasoningSteps.add(AIReasoningStep(
      title: 'Synthesizing recommendations & trade-off analysis',
      detail: 'Verified figures against strict anti-hallucination guardrails.',
      type: AIReasoningStepType.synthesize,
      timestamp: DateTime.now(),
      durationMs: synthesisWatch.elapsedMilliseconds,
    ));

    stopwatch.stop();

    return AIMessage(
      conversationId: conversationId,
      role: AIMessageRole.assistant,
      content: finalText,
      toolCallNames: allToolsCalled.toList(),
      actionDraft: actionDraft,
      scenarioSandbox: scenarioSandbox,
      scenarioComparisonMatrix: scenarioComparisonMatrix,
      reasoningSteps: reasoningSteps,
      thinkingDuration: stopwatch.elapsed,
      createdAt: DateTime.now(),
    );
  }

  bool _isDataSeekingQuery(String query) {
    final q = query.toLowerCase();
    return q.contains('how much') ||
        q.contains('how many') ||
        q.contains('what is my') ||
        q.contains('what are my') ||
        q.contains('show my') ||
        q.contains('did i') ||
        q.contains('balance') ||
        q.contains('spend') ||
        q.contains('spent') ||
        q.contains('expense') ||
        q.contains('budget') ||
        q.contains('goal') ||
        q.contains('transaction') ||
        q.contains('bought') ||
        q.contains('cost') ||
        q.contains('wallet') ||
        q.contains('account') ||
        q.contains('funds') ||
        q.contains('bill') ||
        q.contains('flight') ||
        q.contains('travel') ||
        q.contains('tokyo');
  }

  AIReasoningStep _buildToolReasoningStep({
    required String toolName,
    required Map<String, dynamic>? result,
    required int durationMs,
  }) {
    switch (toolName) {
      case 'get_current_balance':
        final bal = result?['balance'];
        return AIReasoningStep(
          title: 'Auditing available liquidity',
          detail: bal != null ? 'Retrieved live total available balance.' : 'Checking account balances...',
          type: AIReasoningStepType.inspect,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'get_account_balances':
        final accounts = result?['accounts'] as List?;
        final count = accounts?.length ?? 0;
        return AIReasoningStep(
          title: 'Auditing individual account breakdowns',
          detail: 'Inspected $count active wallet and bank account(s).',
          type: AIReasoningStepType.inspect,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'calculate_affordable_spending':
        final canAfford = result?['canAfford'] as bool?;
        return AIReasoningStep(
          title: 'Evaluating purchase affordability & cashflow impact',
          detail: canAfford == true
              ? 'Purchase fits within safe liquidity buffer.'
              : 'Purchase introduces budget friction or exceeds safe limits.',
          type: AIReasoningStepType.calculate,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'get_monthly_expenses':
      case 'get_expenses_by_category':
      case 'get_top_spending_categories':
        return AIReasoningStep(
          title: 'Analyzing monthly expense pacing & category distribution',
          detail: 'Aggregated outflows and evaluated top spending drivers.',
          type: AIReasoningStepType.calculate,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'get_budget_status':
      case 'get_remaining_budget':
        return AIReasoningStep(
          title: 'Verifying active budget caps & remaining headroom',
          detail: 'Audited category spending limits against target allocations.',
          type: AIReasoningStepType.calculate,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'rebalance_budget_allocations':
        return AIReasoningStep(
          title: 'Simulating zero-deficit category rebalance',
          detail: 'Analyzed category burn rates and planned surplus-to-deficit transfers.',
          type: AIReasoningStepType.calculate,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'get_all_goals':
      case 'get_goal_progress':
        return AIReasoningStep(
          title: 'Checking savings goals momentum & target deadlines',
          detail: 'Evaluated milestones and progress percentages.',
          type: AIReasoningStepType.inspect,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'calculate_savings_rate':
        return AIReasoningStep(
          title: 'Calculating net savings rate',
          detail: 'Compared net income vs total monthly burn rate.',
          type: AIReasoningStepType.calculate,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'get_recent_transactions':
      case 'search_transactions':
        return AIReasoningStep(
          title: 'Retrieving recent transaction ledger records',
          detail: 'Inspected recent purchases, deposits, and cash transfers.',
          type: AIReasoningStepType.inspect,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'simulate_financial_scenario':
        return AIReasoningStep(
          title: 'Simulating what-if financial scenario',
          detail: 'Modeled proposed expense adjustments and projected savings timeline.',
          type: AIReasoningStepType.simulate,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      case 'get_recurring_expenses':
      case 'calculate_recurring_monthly_total':
        return AIReasoningStep(
          title: 'Factoring in upcoming recurring bills & subscriptions',
          detail: 'Audited fixed commitments to ensure liquidity baseline.',
          type: AIReasoningStepType.calculate,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
      default:
        return AIReasoningStep(
          title: 'Executing financial verification: $toolName',
          detail: 'Data retrieved successfully.',
          type: AIReasoningStepType.inspect,
          timestamp: DateTime.now(),
          durationMs: durationMs,
        );
    }
  }

  /// A handful of pre-filled prompts for the quick-action chips in the UI
  /// (PRD screen 9.9). Kept here, not hardcoded in the widget, so they stay
  /// aligned with what the intent detector can actually route.
  static const List<String> quickActions = [
    'I spent ₱150 on coffee today with cash',
    'Plan how to spend and save my ₱30,000 salary',
    'Set food budget to ₱6,000 for this month',
    'Create a goal for Emergency Fund target ₱50,000',
    'Can I afford to spend ₱2,000 this weekend?',
    'What is the 50/30/20 rule?',
    'Where did I spend the most this month?',
    'What is my current balance?',
  ];
}

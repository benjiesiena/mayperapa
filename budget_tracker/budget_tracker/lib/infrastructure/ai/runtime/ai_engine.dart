import '../../../features/ai_assistant/domain/ai_action_draft.dart';
import '../../../features/ai_assistant/domain/ai_scenario_sandbox.dart';
import '../tools/ai_tool.dart';

/// A single exchange the engine needs to reason about tool selection.
class AIEngineMessage {
  final String role; // 'user' | 'assistant' | 'system'
  final String content;
  const AIEngineMessage({required this.role, required this.content});
}

/// What the engine decided to do with a user turn: call zero or more tools,
/// then produce a natural-language reply once tool results are available.
class AIEngineDecision {
  final List<String> toolNamesToCall;
  final Map<String, Map<String, dynamic>> toolArgs;
  final bool isTerminal;

  const AIEngineDecision({
    required this.toolNamesToCall,
    this.toolArgs = const {},
    this.isTerminal = false,
  });
}

/// Abstraction over "whatever runs the model". The production implementation
/// would bundle a quantized transformer SLM via an on-device inference
/// runtime (e.g. tflite_flutter or ML Kit — deliberately left out of this
/// scaffold; see pubspec.yaml for why) and load it through a ModelManager.
/// That binary can't be built or shipped from this scaffold, so
/// [RuleBasedAIEngine] stands in as a fully offline, deterministic
/// implementation of the *same* interface. Swapping the real model in later
/// means implementing this interface — nothing above it (orchestrator, UI,
/// tools) needs to change.
abstract class AIEngine {
  /// True once the engine is ready to answer (model loaded, or — for the
  /// rule-based engine — always true).
  Future<bool> get isReady;

  /// Decides which tool(s), if any, are needed to answer [userMessage].
  /// In an autonomous ReAct loop, [accumulatedToolResults] provides observations
  /// from earlier steps so the engine can evaluate whether follow-up tools are required.
  Future<AIEngineDecision> planToolCalls({
    required String userMessage,
    required List<AITool> availableTools,
    required List<AIEngineMessage> conversationHistory,
    Map<String, Map<String, dynamic>> accumulatedToolResults = const {},
  });

  /// Produces the final natural-language reply given the tool results that
  /// were gathered for [userMessage]. Implementations must only reference
  /// numbers present in [toolResults] — see ResponseValidator, which checks
  /// this after the fact as a second line of defense.
  Future<String> generateResponse({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
    required List<AIEngineMessage> conversationHistory,
  });

  /// Extracts an action draft (transaction, budget, goal, or financial plan)
  /// if the user's message is an action command. Defaults to null.
  Future<AIActionDraft?> extractActionDraft({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
    required List<AIEngineMessage> conversationHistory,
  }) async => null;

  /// Extracts an interactive scenario sandbox if the user's message is a what-if query.
  /// Defaults to null.
  AIScenarioSandbox? extractScenarioSandbox({
    required String userMessage,
    required Map<String, Map<String, dynamic>> toolResults,
  }) => null;
}


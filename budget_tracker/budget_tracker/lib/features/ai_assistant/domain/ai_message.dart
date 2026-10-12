import "package:equatable/equatable.dart";
import "ai_action_draft.dart";
import "ai_reasoning_step.dart";
import "ai_scenario_sandbox.dart";

enum AIMessageRole { user, assistant, system }

class AIMessage extends Equatable {
  final int? id;
  final int conversationId;
  final AIMessageRole role;
  final String content;
  final List<String> toolCallNames;
  final AIActionDraft? actionDraft;
  final AIScenarioSandbox? scenarioSandbox;
  final List<AIReasoningStep> reasoningSteps;
  final Duration? thinkingDuration;
  final DateTime createdAt;

  const AIMessage({
    this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.toolCallNames = const [],
    this.actionDraft,
    this.scenarioSandbox,
    this.reasoningSteps = const [],
    this.thinkingDuration,
    required this.createdAt,
  });

  AIMessage copyWith({
    int? id,
    int? conversationId,
    AIMessageRole? role,
    String? content,
    List<String>? toolCallNames,
    AIActionDraft? actionDraft,
    AIScenarioSandbox? scenarioSandbox,
    List<AIReasoningStep>? reasoningSteps,
    Duration? thinkingDuration,
    DateTime? createdAt,
  }) {
    return AIMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      toolCallNames: toolCallNames ?? this.toolCallNames,
      actionDraft: actionDraft ?? this.actionDraft,
      scenarioSandbox: scenarioSandbox ?? this.scenarioSandbox,
      reasoningSteps: reasoningSteps ?? this.reasoningSteps,
      thinkingDuration: thinkingDuration ?? this.thinkingDuration,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        role,
        content,
        toolCallNames,
        actionDraft,
        scenarioSandbox,
        reasoningSteps,
        thinkingDuration,
        createdAt,
      ];
}

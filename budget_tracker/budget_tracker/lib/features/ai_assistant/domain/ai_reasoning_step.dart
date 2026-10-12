import 'package:equatable/equatable.dart';

enum AIReasoningStepType {
  plan,
  inspect,
  calculate,
  simulate,
  synthesize,
}

/// A structured thinking checkpoint produced by Maya during her cognitive reasoning loop.
///
/// Rendered in the UI via [ThinkingProcessCard] so the user can audit
/// the financial calculations, assumptions, and constraints evaluated before answering.
class AIReasoningStep extends Equatable {
  final String title;
  final String? detail;
  final AIReasoningStepType type;
  final DateTime timestamp;
  final int? durationMs;
  final bool isCompleted;

  const AIReasoningStep({
    required this.title,
    this.detail,
    this.type = AIReasoningStepType.inspect,
    required this.timestamp,
    this.durationMs,
    this.isCompleted = true,
  });

  AIReasoningStep copyWith({
    String? title,
    String? detail,
    AIReasoningStepType? type,
    DateTime? timestamp,
    int? durationMs,
    bool? isCompleted,
  }) {
    return AIReasoningStep(
      title: title ?? this.title,
      detail: detail ?? this.detail,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      durationMs: durationMs ?? this.durationMs,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [title, detail, type, timestamp, durationMs, isCompleted];
}

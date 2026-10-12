import 'package:equatable/equatable.dart';

enum AIActionType {
  createTransaction,
  createBudget,
  createGoal,
  applyFinancialPlan,
  batchBundle,
}

enum AIActionStatus {
  pending,
  confirmed,
  executed,
  cancelled,
  failed,
}

/// A structured financial action drafted by the AI assistant that requires
/// explicit user confirmation via an interactive Confirmation Card before
/// mutating the local database.
class AIActionDraft extends Equatable {
  final String id;
  final AIActionType type;
  final String title;
  final String subtitle;
  final Map<String, dynamic> payload;
  final AIActionStatus status;
  final String? executionResult;
  final DateTime createdAt;

  const AIActionDraft({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.payload,
    this.status = AIActionStatus.pending,
    this.executionResult,
    required this.createdAt,
  });

  AIActionDraft copyWith({
    String? id,
    AIActionType? type,
    String? title,
    String? subtitle,
    Map<String, dynamic>? payload,
    AIActionStatus? status,
    String? executionResult,
    DateTime? createdAt,
  }) {
    return AIActionDraft(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      executionResult: executionResult ?? this.executionResult,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'subtitle': subtitle,
        'payload': payload,
        'status': status.name,
        'executionResult': executionResult,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AIActionDraft.fromJson(Map<String, dynamic> json) {
    return AIActionDraft(
      id: json['id'] as String,
      type: AIActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AIActionType.createTransaction,
      ),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      status: AIActionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AIActionStatus.pending,
      ),
      executionResult: json['executionResult'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        subtitle,
        payload,
        status,
        executionResult,
        createdAt,
      ];
}

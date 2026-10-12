import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/ai/runtime/ai_engine.dart';
import '../../../../shared/presentation/providers/app_providers.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../domain/ai_action_draft.dart';
import '../../domain/ai_message.dart';

class AIChatState {
  final List<AIMessage> messages;
  final bool isResponding;

  const AIChatState({this.messages = const [], this.isResponding = false});

  AIChatState copyWith({List<AIMessage>? messages, bool? isResponding}) {
    return AIChatState(
      messages: messages ?? this.messages,
      isResponding: isResponding ?? this.isResponding,
    );
  }
}

/// In-memory chat state for the current session. Supports conversational coaching,
/// structured intent routing, and interactive Confirmation Card actions for mutations.
class AIChatNotifier extends Notifier<AIChatState> {
  static const _conversationId = 1;

  @override
  AIChatState build() => const AIChatState();

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || state.isResponding) return;

    final trimmed = text.trim();
    final lower = trimmed.toLowerCase();

    // Check if there is an active pending action draft
    final pendingIndex = state.messages.lastIndexWhere(
      (m) => m.actionDraft != null && m.actionDraft!.status == AIActionStatus.pending,
    );

    if (pendingIndex != -1) {
      final pendingDraft = state.messages[pendingIndex].actionDraft!;

      // 1. Acceptance Intent
      if (_isAcceptancePhrase(lower)) {
        final userMessage = AIMessage(
          conversationId: _conversationId,
          role: AIMessageRole.user,
          content: trimmed,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(messages: [...state.messages, userMessage]);
        await confirmAction(pendingDraft);
        return;
      }

      // 2. Rejection Intent
      if (_isRejectionPhrase(lower)) {
        final userMessage = AIMessage(
          conversationId: _conversationId,
          role: AIMessageRole.user,
          content: trimmed,
          createdAt: DateTime.now(),
        );
        state = state.copyWith(messages: [...state.messages, userMessage]);
        cancelAction(pendingDraft);
        return;
      }
    }

    final userMessage = AIMessage(
      conversationId: _conversationId,
      role: AIMessageRole.user,
      content: trimmed,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(messages: [...state.messages, userMessage], isResponding: true);

    final orchestrator = ref.read(aiOrchestratorProvider);
    final history =
        state.messages.map((m) => AIEngineMessage(role: m.role.name, content: m.content)).toList();

    try {
      final reply = await orchestrator.sendMessage(
        userMessage: trimmed,
        conversationId: _conversationId,
        history: history,
      );
      state = state.copyWith(messages: [...state.messages, reply], isResponding: false);
    } catch (_) {
      final fallback = AIMessage(
        conversationId: _conversationId,
        role: AIMessageRole.assistant,
        content: 'Something went wrong answering that — please try again.',
        createdAt: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, fallback], isResponding: false);
    }
  }

  bool _isAcceptancePhrase(String text) {
    final t = text.trim().toLowerCase();
    const exactMatches = {
      'yes', 'y', 'yep', 'yeah', 'sure', 'ok', 'okay', 'accept', 'confirm',
      'implement', 'implement it', 'do it', 'go ahead', 'proceed', 'sounds good',
      'looks good', 'save it', 'save', 'approve', 'let\'s do it', 'lets do it',
      'yes please', 'yes do it', 'confirm and save', 'yes implement it', 'accept suggestion',
      'accept the suggestion', 'apply it',
    };
    if (exactMatches.contains(t)) return true;
    return t.startsWith('yes') ||
        t.startsWith('accept') ||
        t.startsWith('confirm') ||
        t.startsWith('implement') ||
        t.startsWith('go ahead') ||
        t.startsWith('proceed') ||
        t.startsWith('do it') ||
        t.startsWith('save it') ||
        t.contains('implement it') ||
        t.contains('accept the suggestion') ||
        t.contains('apply this plan');
  }

  bool _isRejectionPhrase(String text) {
    final t = text.trim().toLowerCase();
    const exactMatches = {
      'no', 'n', 'nope', 'nah', 'cancel', 'reject', 'revoke', 'revoke it',
      'don\'t do it', 'dont do it', 'discard', 'never mind', 'nevermind',
      'stop', 'forget it', 'no thanks', 'reject it', 'cancel action',
      'reject the suggestion', 'revoke suggestion', 'revoke the suggestion',
    };
    if (exactMatches.contains(t)) return true;
    return t.startsWith('no') ||
        t.startsWith('cancel') ||
        t.startsWith('reject') ||
        t.startsWith('revoke') ||
        t.startsWith('don\'t') ||
        t.startsWith('dont') ||
        t.contains('revoke the suggestion') ||
        t.contains('reject the suggestion') ||
        t.contains('never mind');
  }

  Future<void> confirmAction(AIActionDraft draft) async {
    // 1. Mark draft as confirmed/executing in messages
    final updatedMessages = state.messages.map((m) {
      if (m.actionDraft?.id == draft.id) {
        return m.copyWith(
          actionDraft: m.actionDraft!.copyWith(status: AIActionStatus.confirmed),
        );
      }
      return m;
    }).toList();
    state = state.copyWith(messages: updatedMessages);

    // 2. Execute via AIActionExecutor
    final executor = ref.read(aiActionExecutorProvider);
    final result = await executor.execute(draft);

    // 3. Invalidate Riverpod providers to immediately refresh UI across tabs
    ref.invalidate(transactionsProvider);
    ref.invalidate(activeBudgetProvider);
    ref.invalidate(goalsProvider);

    // 4. Update draft with executed/failed status and result message
    final newStatus = result.success ? AIActionStatus.executed : AIActionStatus.failed;
    final finalMessages = state.messages.map((m) {
      if (m.actionDraft?.id == draft.id) {
        return m.copyWith(
          actionDraft: m.actionDraft!.copyWith(
            status: newStatus,
            executionResult: result.message,
          ),
        );
      }
      return m;
    }).toList();

    // 5. Append assistant confirmation message
    final confirmationMessage = AIMessage(
      conversationId: _conversationId,
      role: AIMessageRole.assistant,
      content: result.success ? '✓ ${result.message}' : '❌ ${result.message}',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(messages: [...finalMessages, confirmationMessage]);
  }

  void cancelAction(AIActionDraft draft) {
    final updatedMessages = state.messages.map((m) {
      if (m.actionDraft?.id == draft.id) {
        return m.copyWith(
          actionDraft: m.actionDraft!.copyWith(
            status: AIActionStatus.cancelled,
            executionResult: 'Cancelled by user',
          ),
        );
      }
      return m;
    }).toList();

    final cancelMessage = AIMessage(
      conversationId: _conversationId,
      role: AIMessageRole.assistant,
      content: 'Understood! I\'ve revoked that suggestion and nothing was saved. What would you like to explore or adjust instead?',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(messages: [...updatedMessages, cancelMessage]);
  }

  /// Clears in-memory messages for current session.
  void clearChat() {
    state = const AIChatState();
  }
}

final aiChatProvider = NotifierProvider<AIChatNotifier, AIChatState>(AIChatNotifier.new);

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/ai_message.dart';
import '../providers/ai_chat_provider.dart';
import 'ai_action_card.dart';
import 'scenario_sandbox_card.dart';
import 'thinking_process_card.dart';

/// Chat bubble per PRD 8.6 AIMessage spec: user right-aligned/primary bg,
/// assistant left-aligned/surface-variant bg, 16px radius.
/// When an [AIActionDraft] is attached, renders an interactive [AIActionCard]
/// enabling human-in-the-loop confirmation before database mutation.
/// When an [AIScenarioSandbox] is attached, renders an interactive [ScenarioSandboxCard].
class AIMessageBubble extends ConsumerWidget {
  final AIMessage message;

  const AIMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.appColors;
    final isUser = message.role == AIMessageRole.user;
    final screenWidth = MediaQuery.of(context).size.width;
    final hasExpandedArtifact = message.actionDraft != null || message.scenarioSandbox != null;
    final maxWidth = isUser || !hasExpandedArtifact
        ? screenWidth * 0.82
        : screenWidth * 0.94;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: isUser ? palette.primary : palette.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isUser && message.reasoningSteps.isNotEmpty)
                ThinkingProcessCard(
                  steps: message.reasoningSteps,
                  duration: message.thinkingDuration,
                  toolCallNames: message.toolCallNames,
                ),
              _buildContent(
                message.content,
                AppTypography.body.copyWith(
                  color: isUser ? Colors.white : palette.textPrimary,
                  height: 1.45,
                ),
              ),
              if (message.scenarioSandbox != null)
                ScenarioSandboxCard(
                  sandbox: message.scenarioSandbox!,
                  onApplyCut: (amount) {
                    ref.read(aiChatProvider.notifier).sendMessage(
                          'Apply this scenario: reduce my ${message.scenarioSandbox!.categoryName} budget by ₱${amount.toStringAsFixed(0)} per month',
                        );
                  },
                ),
              if (message.actionDraft != null)
                AIActionCard(
                  draft: message.actionDraft!,
                  onConfirm: () =>
                      ref.read(aiChatProvider.notifier).confirmAction(message.actionDraft!),
                  onCancel: () =>
                      ref.read(aiChatProvider.notifier).cancelAction(message.actionDraft!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String text, TextStyle baseStyle) {

    // If message contains markdown bold or italic syntax, render rich formatting
    if (text.contains('*')) {
      return Text.rich(
        TextSpan(
          children: _parseMarkdownSpans(text, baseStyle),
        ),
      );
    }

    return Text(
      text,
      style: baseStyle,
    );
  }

  static List<InlineSpan> _parseMarkdownSpans(String text, TextStyle baseStyle) {
    if (text.isEmpty) return const [];

    final spans = <InlineSpan>[];
    // Matches **bold** or *italic*
    final pattern = RegExp(r'(\*\*(.+?)\*\*)|(\*([^\*]+?)\*)', dotAll: true);
    int lastMatchEnd = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final boldText = match.group(2);
      final italicText = match.group(4);

      if (boldText != null) {
        spans.add(TextSpan(
          text: boldText,
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ));
      } else if (italicText != null) {
        spans.add(TextSpan(
          text: italicText,
          style: baseStyle.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans.isEmpty ? [TextSpan(text: text, style: baseStyle)] : spans;
  }
}

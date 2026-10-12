import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/presentation/providers/app_providers.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import '../../domain/ai_orchestrator.dart';
import '../providers/ai_chat_provider.dart';
import '../widgets/ai_message_bubble.dart';
import '../widgets/ai_quick_action.dart';
import '../../../../infrastructure/ai/runtime/model_download_service.dart';

/// AI Assistant chat screen with on-device LLM management, live financial tool
/// dispatch, and conversational financial reasoning.
class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isModelDownloaded = false;

  @override
  void initState() {
    super.initState();
    _refreshModelStatus();
  }

  Future<void> _refreshModelStatus() async {
    final downloadService = ref.read(modelDownloadServiceProvider);
    final downloaded = await downloadService.isModelDownloaded();
    if (mounted) {
      setState(() {
        _isModelDownloaded = downloaded;
      });
    }
  }

  void _openModelManagerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => const _ModelManagerSheet(),
    ).whenComplete(() {
      // Refresh parent state after the sheet closes so the banner
      // and engine reflect whatever the user changed.
      _refreshModelStatus();
      ref.invalidate(aiEngineProvider);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.standard,
          curve: AppCurves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _inputController.text).trim();
    if (message.isEmpty) return;
    _inputController.clear();
    await ref.read(aiChatProvider.notifier).sendMessage(message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aiChatProvider);
    final mode = ref.watch(aiEngineModeProvider);
    final palette = context.appColors;

    String modeTitle;
    IconData modeIcon;
    Color modeColor;

    switch (mode) {
      case AIEngineMode.cloudAdvisor:
        modeTitle = '🌐 Cloud Advisor (Gemini Flash)';
        modeIcon = Icons.cloud_outlined;
        modeColor = palette.positive;
        break;
      case AIEngineMode.localNeural:
        modeTitle = '🧠 Qwen 2.5 0.5B (On-Device Neural)';
        modeIcon = Icons.psychology;
        modeColor = palette.primary;
        break;
      case AIEngineMode.instantOffline:
        modeTitle = '⚡ Instant Offline (<0.05s)';
        modeIcon = Icons.bolt;
        modeColor = palette.primary;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maya — AI Assistant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            Text(
              modeTitle,
              style: TextStyle(
                fontSize: 11,
                color: modeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TactileBounce(
              onTap: _openModelManagerSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: modeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: modeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(modeIcon, color: modeColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Mode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: modeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Subtle Engine Banner
          _buildEngineBanner(context),

          // Chat Messages or Greeting
          Expanded(
            child: chatState.messages.isEmpty
                ? _EmptyChatGreeting(
                    onQuickAction: _send,
                    onOpenModelManager: _openModelManagerSheet,
                    isModelDownloaded: _isModelDownloaded,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    itemCount: chatState.messages.length + (chatState.isResponding ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= chatState.messages.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: palette.surfaceVariant,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: palette.primary),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Consulting financial tools...',
                                    style: AppTypography.caption.copyWith(color: palette.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      return AIMessageBubble(message: chatState.messages[index]);
                    },
                  ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.surface,
              border: Border(top: BorderSide(color: palette.border)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Ask e.g. "Can I afford ₱2,000 this weekend?"',
                        hintStyle: AppTypography.body.copyWith(color: palette.textTertiary, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs + 2),
                  TactileBounce(
                    onTap: chatState.isResponding ? null : () => _send(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: chatState.isResponding ? palette.textDisabled : palette.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineBanner(BuildContext context) {
    final palette = context.appColors;
    final mode = ref.watch(aiEngineModeProvider);

    String message;
    IconData icon;
    Color color;

    switch (mode) {
      case AIEngineMode.cloudAdvisor:
        message = '🌐 Cloud Advisor — natural advice & coaching';
        icon = Icons.cloud_outlined;
        color = palette.positive;
        break;
      case AIEngineMode.localNeural:
        message = '🧠 Qwen 2.5 0.5B — on-device neural model';
        icon = Icons.psychology;
        color = palette.primary;
        break;
      case AIEngineMode.instantOffline:
        message = '⚡ Instant Offline — sub-50ms verified coaching';
        icon = Icons.bolt;
        color = palette.primary;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      color: palette.surfaceVariant,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: palette.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TactileBounce(
            onTap: _openModelManagerSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Change Mode',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChatGreeting extends StatelessWidget {
  final ValueChanged<String> onQuickAction;
  final VoidCallback onOpenModelManager;
  final bool isModelDownloaded;

  const _EmptyChatGreeting({
    required this.onQuickAction,
    required this.onOpenModelManager,
    required this.isModelDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.auto_awesome, color: palette.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Maya Financial Assistant', style: AppTypography.sectionHeading.copyWith(fontSize: 17)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'I\'m Maya, your proactive financial assistant for MayPeraPa. I can analyze your spending, check if you can afford upcoming expenses, review your budgets, and forecast cashflow — with zero data leaving your phone.',
                style: AppTypography.body.copyWith(color: palette.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'TRY ASKING',
          style: AppTypography.caption.copyWith(
            color: palette.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final prompt in AIOrchestrator.quickActions)
              AIQuickAction(label: prompt, onTap: () => onQuickAction(prompt)),
          ],
        ),
      ],
    );
  }
}

class _ModelManagerSheet extends ConsumerStatefulWidget {
  const _ModelManagerSheet();

  @override
  ConsumerState<_ModelManagerSheet> createState() => _ModelManagerSheetState();
}

class _ModelManagerSheetState extends ConsumerState<_ModelManagerSheet> {
  bool _isDownloading = false;
  bool _isModelDownloaded = false;
  double _progress = 0.0;
  String _message = '';
  bool _obscureApiKey = true;
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: ref.read(geminiApiKeyProvider));
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final service = ref.read(modelDownloadServiceProvider);
    final downloaded = await service.isModelDownloaded();
    if (mounted) {
      setState(() {
        _isModelDownloaded = downloaded;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _message = 'Connecting to Hugging Face...';
    });

    final service = ModelDownloadService(
      onProgress: (p, msg) {
        if (mounted) {
          setState(() {
            _progress = p;
            _message = msg;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _message = 'Failed: $err';
          });
        }
      },
      onComplete: (path) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _message = 'Download complete!';
          });
          ref.read(aiEngineModeProvider.notifier).state = AIEngineMode.localNeural;
          _refreshStatus();
          Navigator.of(context).pop();
        }
      },
    );

    service.downloadModel();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;
    final currentMode = ref.watch(aiEngineModeProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxSheetHeight),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Maya AI Engine', style: AppTypography.sectionHeading),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Select how you want Maya to respond. All calculations use your private on-device financial tools.',
                style: AppTypography.body.copyWith(color: palette.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),

              // Mode 1: Instant Offline Coach
              _buildModeCard(
                context: context,
                mode: AIEngineMode.instantOffline,
                isSelected: currentMode == AIEngineMode.instantOffline,
                title: '⚡ Instant Offline Coach',
                badge: 'Fastest (<0.05s)',
                description: '100% offline, zero internet. Live database calculations + expanded coaching rules (50/30/20, emergency funds, debt payoff).',
                onTap: () {
                  ref.read(aiEngineModeProvider.notifier).state = AIEngineMode.instantOffline;
                },
              ),
              const SizedBox(height: AppSpacing.sm),

              // Mode 2: Cloud Advisor (Gemini Flash)
              _buildModeCard(
                context: context,
                mode: AIEngineMode.cloudAdvisor,
                isSelected: currentMode == AIEngineMode.cloudAdvisor,
                title: '🌐 Cloud Advisor (Gemini Flash)',
                badge: 'Human-like (~0.6s)',
                description: 'Speaks like a real financial mentor with empathy, conversational understanding, and personalized advice.',
                onTap: () {
                  ref.read(aiEngineModeProvider.notifier).state = AIEngineMode.cloudAdvisor;
                },
              ),

              if (currentMode == AIEngineMode.cloudAdvisor) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Google Gemini API Key', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        'Get a 100% free key with no credit card from aistudio.google.com',
                        style: TextStyle(fontSize: 11, color: palette.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _apiKeyController,
                              obscureText: _obscureApiKey,
                              scrollPadding: const EdgeInsets.all(80),
                              decoration: InputDecoration(
                                hintText: 'Paste Gemini API Key...',
                                hintStyle: TextStyle(fontSize: 12, color: palette.textTertiary),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                isDense: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureApiKey ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: palette.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureApiKey = !_obscureApiKey;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          FilledButton(
                            onPressed: () {
                              final key = _apiKeyController.text.trim();
                              ref.read(geminiApiKeyProvider.notifier).state = key;
                              FocusScope.of(context).unfocus();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gemini API Key saved successfully!'), duration: Duration(seconds: 2)),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: palette.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            ),
                            child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),

              // Mode 3: Lightweight On-Device LLM (Qwen 2.5 0.5B)
              _buildModeCard(
                context: context,
                mode: AIEngineMode.localNeural,
                isSelected: currentMode == AIEngineMode.localNeural,
                title: '🧠 Lightweight On-Device LLM',
                badge: 'Offline Neural (~3-5s)',
                description: 'Qwen 2.5 0.5B Instruct (~390 MB). Runs locally on mobile CPU via llama.cpp without sending any data over the internet.',
                onTap: () {
                  ref.read(aiEngineModeProvider.notifier).state = AIEngineMode.localNeural;
                },
              ),

              if (currentMode == AIEngineMode.localNeural) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: palette.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Model: Qwen 2.5 0.5B Instruct (Q4_K_M)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('Download size: ~390 MB (optimized for phone CPU)', style: TextStyle(fontSize: 11, color: palette.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      if (_isDownloading) ...[
                        LinearProgressIndicator(value: _progress > 0 ? _progress : null),
                        const SizedBox(height: 4),
                        Text('${(_progress * 100).toStringAsFixed(1)}% — $_message', style: TextStyle(fontSize: 11, color: palette.textSecondary)),
                      ] else if (_isModelDownloaded) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: palette.positive, size: 16),
                                const SizedBox(width: 4),
                                Text('Model installed & ready', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.positive)),
                              ],
                            ),
                            TextButton(
                              onPressed: () async {
                                await ModelDownloadService().deleteModel();
                                ref.read(aiEngineModeProvider.notifier).state = AIEngineMode.instantOffline;
                                _refreshStatus();
                              },
                              child: Text('Delete (Free 390MB)', style: TextStyle(fontSize: 11, color: palette.negative)),
                            ),
                          ],
                        ),
                      ] else ...[
                        PrimaryButton(
                          label: 'Download Qwen 2.5 0.5B (~390 MB)',
                          onPressed: _startDownload,
                          icon: Icons.cloud_download_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required AIEngineMode mode,
    required bool isSelected,
    required String title,
    required String badge,
    required String description,
    required VoidCallback onTap,
  }) {
    final palette = context.appColors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? palette.primary.withValues(alpha: 0.08) : palette.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? palette.primary : palette.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected ? palette.primary : palette.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? palette.primary : palette.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : palette.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
          ],
        ),
      ),
    );
  }
}

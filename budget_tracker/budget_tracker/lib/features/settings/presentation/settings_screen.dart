import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/presentation/providers/app_providers.dart';
import '../../../shared/presentation/widgets/app_buttons.dart';
import '../../categories/presentation/screens/categories_management_screen.dart';
import '../../ai_assistant/domain/user_financial_profile.dart';
import '../../ai_assistant/presentation/providers/financial_profile_provider.dart';
import '../domain/entities/app_settings.dart';
import 'providers/settings_provider.dart';
import '../../security/presentation/providers/app_lock_provider.dart';

/// Settings screen implementing full business logic, offline persistence,
/// security key management, and data import/export workflows per AGENTS.md.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final profileAsync = ref.watch(financialProfileProvider);
    final palette = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Failed to load settings: $err', style: TextStyle(color: palette.negative)),
          ),
        ),
        data: (settings) {
          final profile = profileAsync.valueOrNull ?? UserFinancialProfile.defaultProfile(settings.userId);
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
            // 1. Preferences
            _sectionHeader(context, 'Preferences'),
            _cardContainer(context, [
              _pickerRow(
                context,
                icon: Icons.payments_outlined,
                label: 'Currency',
                value: '${settings.currencyCode} (${settings.currencySymbol})',
                onTap: () => _showCurrencyPicker(context, ref, settings.currencyCode),
              ),
              _divider(context),
              _pickerRow(
                context,
                icon: Icons.palette_outlined,
                label: 'Theme',
                value: settings.themeLabel,
                onTap: () => _showThemePicker(context, ref, settings.theme),
              ),
              _divider(context),
              _pickerRow(
                context,
                icon: Icons.language_outlined,
                label: 'Language',
                value: settings.languageLabel,
                onTap: () => _showLanguagePicker(context, ref, settings.language),
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.category_outlined,
                label: 'Categories',
                trailingText: 'Manage',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesManagementScreen()),
                ),
              ),
            ]),

            // 2. Security
            _sectionHeader(context, 'Security'),
            _cardContainer(context, [
              _switchRow(
                context,
                icon: Icons.lock_outline,
                label: 'App Lock',
                subtitle: 'Require PIN to unlock the application',
                value: settings.autoLockEnabled,
                onChanged: (val) => _handleAppLockToggle(context, ref, settings, val),
              ),
              _divider(context),
              _switchRow(
                context,
                icon: Icons.fingerprint,
                label: 'Biometrics',
                subtitle: 'Fingerprint or Face unlock',
                value: settings.biometricEnabled,
                onChanged: (val) => _handleBiometricsToggle(context, ref, val),
              ),
              _divider(context),
              _pickerRow(
                context,
                icon: Icons.timer_outlined,
                label: 'Auto-lock timeout',
                value: settings.autoLockTimeoutLabel,
                enabled: settings.autoLockEnabled,
                onTap: settings.autoLockEnabled
                    ? () => _showTimeoutPicker(context, ref, settings.autoLockTimeoutSeconds)
                    : null,
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.pin_outlined,
                label: settings.hasPinConfigured ? 'Change PIN' : 'Set Up PIN',
                trailingText: settings.hasPinConfigured ? 'Configured' : 'Not Set',
                onTap: () => _showPinManagementDialog(context, ref, settings.hasPinConfigured),
              ),
              if (settings.autoLockEnabled && settings.hasPinConfigured) ...[
                _divider(context),
                _actionRow(
                  context,
                  icon: Icons.lock_clock_outlined,
                  label: 'Lock App Now',
                  trailingText: 'Lock',
                  onTap: () {
                    ref.read(appLockProvider.notifier).lock();
                  },
                ),
              ],
            ]),

            // 3. AI Settings
            _sectionHeader(context, 'AI Settings'),
            _cardContainer(context, [
              _switchRow(
                context,
                icon: Icons.psychology_outlined,
                label: 'AI Memory',
                subtitle: 'Allow assistant to retain conversational context',
                value: settings.aiMemoryEnabled,
                onChanged: (val) {
                  ref.read(settingsNotifierProvider.notifier).toggleAiMemory(val);
                  ref.read(financialProfileProvider.notifier).toggleMemory(val);
                },
              ),
              _divider(context),
              _pickerRow(
                context,
                icon: Icons.record_voice_over_outlined,
                label: 'Coaching Tone',
                value: profile.coachingTone.label,
                onTap: () => _showCoachingToneSheet(context, ref, profile.coachingTone),
              ),
              _divider(context),
              _pickerRow(
                context,
                icon: Icons.calendar_month_outlined,
                label: 'Payday Schedule',
                value: profile.paydaySummary,
                onTap: () => _showPaydayPickerSheet(context, ref, profile.paydayDays),
              ),
              _divider(context),
              _pickerRow(
                context,
                icon: Icons.memory_outlined,
                label: 'Model Version',
                value: _getAiEngineLabel(ref),
                onTap: () => _showAiEngineSheet(context, ref),
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.cleaning_services_outlined,
                label: 'Clear AI Memory',
                onTap: () => _showClearAiMemoryDialog(context, ref),
              ),
            ]),

            // 4. Notifications
            _sectionHeader(context, 'Notifications'),
            _cardContainer(context, [
              _switchRow(
                context,
                icon: Icons.notifications_active_outlined,
                label: 'Budget Alerts',
                subtitle: 'Notify when spending exceeds 85% of budget',
                value: settings.budgetAlertsEnabled,
                onChanged: (val) => ref.read(settingsNotifierProvider.notifier).toggleBudgetAlerts(val),
              ),
              _divider(context),
              _switchRow(
                context,
                icon: Icons.flag_outlined,
                label: 'Goal Reminders',
                subtitle: 'Periodic reminders to stay on track',
                value: settings.goalRemindersEnabled,
                onChanged: (val) => ref.read(settingsNotifierProvider.notifier).toggleGoalReminders(val),
              ),
              _divider(context),
              _switchRow(
                context,
                icon: Icons.event_repeat_outlined,
                label: 'Upcoming Expenses',
                subtitle: 'Alerts before recurring bills and commitments',
                value: settings.upcomingExpensesEnabled,
                onChanged: (val) => ref.read(settingsNotifierProvider.notifier).toggleUpcomingExpenses(val),
              ),
            ]),

            // 5. Data Hygiene & Portability
            _sectionHeader(context, 'Data'),
            _cardContainer(context, [
              _actionRow(
                context,
                icon: Icons.backup_outlined,
                label: 'Backup & Restore',
                trailingText: settings.lastBackupDate != null
                    ? 'Last: ${settings.lastBackupDate!.month}/${settings.lastBackupDate!.day}'
                    : 'None',
                onTap: () => _showBackupRestoreSheet(context, ref),
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.file_upload_outlined,
                label: 'Export Data',
                onTap: () => _showExportSheet(context, ref),
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.file_download_outlined,
                label: 'Import Data',
                onTap: () => _showImportSheet(context, ref),
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.delete_forever_outlined,
                label: 'Clear All Data',
                isDestructive: true,
                onTap: () => _showClearAllDataDialog(context, ref),
              ),
            ]),

            // 6. About & Governance
            _sectionHeader(context, 'About'),
            _cardContainer(context, [
              _actionRow(
                context,
                icon: Icons.info_outline,
                label: 'Version',
                trailingText: '1.0.0+1',
                onTap: () => _showAboutAppDialog(context),
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () => _showPrivacyPolicySheet(context),
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () => _showTermsSheet(context),
              ),
              _divider(context),
              _actionRow(
                context,
                icon: Icons.feedback_outlined,
                label: 'Send Feedback',
                onTap: () => _showFeedbackSheet(context),
              ),
            ]),

            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    ),
  );
}

  // =========================================================================
  // PRESENTATION HELPERS & CRAFT CONTAINERS
  // =========================================================================

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.lg, AppSpacing.xs, AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: context.appColors.textSecondary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _cardContainer(BuildContext context, List<Widget> children) {
    final palette = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: palette.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.appColors.divider);
  }

  Widget _pickerRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final palette = context.appColors;
    return TactileBounce(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: enabled ? palette.textSecondary : palette.textDisabled),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: enabled ? palette.textPrimary : palette.textDisabled,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: AppTypography.supporting.copyWith(
                color: enabled ? palette.textSecondary : palette.textDisabled,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _switchRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final palette = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.body.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: palette.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: palette.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? trailingText,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final palette = context.appColors;
    final color = isDestructive ? palette.negative : palette.textPrimary;
    return TactileBounce(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDestructive ? palette.negative : palette.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: color,
                  fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: AppTypography.supporting.copyWith(color: palette.textSecondary),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right, size: 18, color: palette.textTertiary),
          ],
        ),
      ),
    );
  }

  String _getAiEngineLabel(WidgetRef ref) {
    final mode = ref.watch(aiEngineModeProvider);
    switch (mode) {
      case AIEngineMode.instantOffline:
        return 'Rule-Based (0ms)';
      case AIEngineMode.cloudAdvisor:
        return 'Cloud (Gemini)';
      case AIEngineMode.localNeural:
        return 'Local (Qwen 0.5B)';
    }
  }

  // =========================================================================
  // LOGIC & MODAL BOTTOM SHEETS
  // =========================================================================

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String current) {
    final currencies = [
      {'code': 'PHP', 'label': 'Philippine Peso', 'symbol': '₱'},
      {'code': 'USD', 'label': 'US Dollar', 'symbol': '\$'},
      {'code': 'EUR', 'label': 'Euro', 'symbol': '€'},
      {'code': 'GBP', 'label': 'British Pound', 'symbol': '£'},
      {'code': 'JPY', 'label': 'Japanese Yen', 'symbol': '¥'},
    ];

    _showSelectionSheet(
      context: context,
      title: 'Select Currency',
      items: currencies.map((c) {
        final code = c['code']!;
        final isSelected = code == current;
        return _SelectionOption(
          title: '$code (${c['symbol']})',
          subtitle: c['label'],
          isSelected: isSelected,
          onTap: () {
            ref.read(settingsNotifierProvider.notifier).setCurrency(code);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, String current) {
    final themes = [
      {'value': 'system', 'label': 'System Default', 'sub': 'Matches device brightness'},
      {'value': 'light', 'label': 'Light', 'sub': 'Crisp and bright appearance'},
      {'value': 'dark', 'label': 'Dark', 'sub': 'Gentle on battery and eyes'},
    ];

    _showSelectionSheet(
      context: context,
      title: 'Choose Theme',
      items: themes.map((t) {
        final value = t['value']!;
        return _SelectionOption(
          title: t['label']!,
          subtitle: t['sub'],
          isSelected: value.toLowerCase() == current.toLowerCase(),
          onTap: () {
            ref.read(settingsNotifierProvider.notifier).setTheme(value);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, String current) {
    final languages = [
      {'code': 'en', 'label': 'English', 'sub': 'Default locale'},
      {'code': 'fil', 'label': 'Filipino (Tagalog)', 'sub': 'Lokal na wika'},
      {'code': 'es', 'label': 'Español', 'sub': 'Idioma español'},
    ];

    _showSelectionSheet(
      context: context,
      title: 'Select Language',
      items: languages.map((l) {
        final code = l['code']!;
        return _SelectionOption(
          title: l['label']!,
          subtitle: l['sub'],
          isSelected: code == current,
          onTap: () {
            ref.read(settingsNotifierProvider.notifier).setLanguage(code);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showTimeoutPicker(BuildContext context, WidgetRef ref, int current) {
    final options = [
      {'seconds': 0, 'label': 'Immediately'},
      {'seconds': 60, 'label': '1 minute'},
      {'seconds': 300, 'label': '5 minutes'},
      {'seconds': 900, 'label': '15 minutes'},
      {'seconds': 1800, 'label': '30 minutes'},
    ];

    _showSelectionSheet(
      context: context,
      title: 'Auto-Lock Timeout',
      items: options.map((opt) {
        final secs = opt['seconds'] as int;
        return _SelectionOption(
          title: opt['label'] as String,
          isSelected: secs == current,
          onTap: () {
            ref.read(settingsNotifierProvider.notifier).setAutoLockTimeout(secs);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  Future<void> _handleAppLockToggle(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
    bool enable,
  ) async {
    if (enable) {
      if (!settings.hasPinConfigured) {
        _showPinManagementDialog(context, ref, false, onPinSet: () {
          ref.read(settingsNotifierProvider.notifier).toggleAppLock(true);
        });
      } else {
        ref.read(settingsNotifierProvider.notifier).toggleAppLock(true);
      }
    } else {
      ref.read(settingsNotifierProvider.notifier).toggleAppLock(false);
    }
  }

  Future<void> _handleBiometricsToggle(BuildContext context, WidgetRef ref, bool enable) async {
    final sec = ref.read(securityManagerProvider);
    if (enable) {
      final available = await sec.isBiometricAvailable();
      if (!available) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometrics are not supported or enrolled on this device.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final authenticated = await sec.authenticateWithBiometrics(reason: 'Enable Biometric Unlock');
      if (authenticated) {
        ref.read(settingsNotifierProvider.notifier).toggleBiometrics(true);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication cancelled or failed.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      ref.read(settingsNotifierProvider.notifier).toggleBiometrics(false);
    }
  }

  void _showPinManagementDialog(
    BuildContext context,
    WidgetRef ref,
    bool hasPin, {
    VoidCallback? onPinSet,
  }) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();
    final palette = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              hasPin ? 'Change App PIN' : 'Set Up App PIN',
              style: AppTypography.sectionHeading.copyWith(color: palette.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your PIN is securely stored.',
              style: AppTypography.supporting.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            if (hasPin) ...[
              TextField(
                controller: oldPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'New PIN (4-6 digits)',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: confirmPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Save PIN',
              onPressed: () async {
                final newPin = newPinController.text.trim();
                final confirmPin = confirmPinController.text.trim();

                if (newPin.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN must be at least 4 digits.')),
                  );
                  return;
                }
                if (newPin != confirmPin) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New PINs do not match.')),
                  );
                  return;
                }

                if (hasPin) {
                  final oldPin = oldPinController.text.trim();
                  final valid = await ref.read(settingsNotifierProvider.notifier).verifyPIN(oldPin);
                  if (!valid) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Incorrect current PIN.')),
                      );
                    }
                    return;
                  }
                }

                await ref.read(settingsNotifierProvider.notifier).setPIN(newPin);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN successfully updated.')),
                  );
                  onPinSet?.call();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAiEngineSheet(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(aiEngineModeProvider);
    final apiKey = ref.watch(geminiApiKeyProvider);
    final palette = context.appColors;

    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('AI Engine & Model Architecture', style: AppTypography.sectionHeading.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Select the intelligence runtime for financial assistance and simulations.', style: AppTypography.supporting.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.md),

            // Mode 1: Instant Offline
            _engineTile(
              title: 'Instant Offline (Rule-based)',
              subtitle: 'Sub-50ms latency • 100% private on-device calculation • Zero battery drain',
              isSelected: currentMode == AIEngineMode.instantOffline,
              onTap: () {
                ref.read(aiEngineModeProvider.notifier).state = AIEngineMode.instantOffline;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Mode 2: Cloud Advisor
            _engineTile(
              title: 'Cloud Advisor (Google Gemini Flash)',
              subtitle: 'Human-like financial coaching • Complex what-if simulations',
              isSelected: currentMode == AIEngineMode.cloudAdvisor,
              onTap: () {
                ref.read(aiEngineModeProvider.notifier).state = AIEngineMode.cloudAdvisor;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // Mode 3: Local Neural
            _engineTile(
              title: 'Local Neural Model (Qwen 2.5 0.5B)',
              subtitle: 'On-device neural inference via llama.cpp • Requires ~350MB model',
              isSelected: currentMode == AIEngineMode.localNeural,
              onTap: () {
                ref.read(aiEngineModeProvider.notifier).state = AIEngineMode.localNeural;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            if (currentMode == AIEngineMode.cloudAdvisor) ...[
              Text('Gemini API Key', style: AppTypography.caption.copyWith(color: palette.textSecondary)),
              const SizedBox(height: 4),
              TextField(
                controller: TextEditingController(text: apiKey),
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Enter API Key',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onSubmitted: (val) {
                  ref.read(geminiApiKeyProvider.notifier).state = val.trim();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gemini API Key saved.')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _engineTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return TactileBounce(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  void _showClearAiMemoryDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear AI Memory?'),
        content: const Text(
          'This will permanently delete all conversational chat logs and session memory while keeping all accounts, budgets, and transactions intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(settingsNotifierProvider.notifier).clearAiMemory();
              await ref.read(financialProfileProvider.notifier).clearMemory();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('AI conversation memory cleared.')),
                );
              }
            },
            child: const Text('Clear Memory'),
          ),
        ],
      ),
    );
  }

  void _showCoachingToneSheet(BuildContext context, WidgetRef ref, MayaTone currentTone) {
    _showSelectionSheet(
      context: context,
      title: 'Coaching Persona Tone',
      items: MayaTone.values.map((tone) {
        return _SelectionOption(
          title: tone.label,
          subtitle: tone.description,
          isSelected: tone == currentTone,
          onTap: () {
            ref.read(financialProfileProvider.notifier).updateTone(tone);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showPaydayPickerSheet(BuildContext context, WidgetRef ref, List<int> currentDays) {
    final options = [
      {'label': '15th and 30th of the month', 'days': [15, 30]},
      {'label': '10th and 25th of the month', 'days': [10, 25]},
      {'label': 'End of month (30th/31st)', 'days': [30]},
      {'label': '1st and 15th of the month', 'days': [1, 15]},
      {'label': 'Every 5th and 20th', 'days': [5, 20]},
    ];

    _showSelectionSheet(
      context: context,
      title: 'Payday Schedule',
      items: options.map((opt) {
        final days = opt['days'] as List<int>;
        final isSelected = currentDays.length == days.length &&
            currentDays.every((d) => days.contains(d));
        return _SelectionOption(
          title: opt['label'] as String,
          isSelected: isSelected,
          onTap: () {
            ref.read(financialProfileProvider.notifier).updatePaydays(days);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }

  void _showBackupRestoreSheet(BuildContext context, WidgetRef ref) {
    final palette = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Backup & Restore', style: AppTypography.sectionHeading.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text('Create offline snapshot backups or restore your database.', style: AppTypography.supporting.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Create Full Backup',
              icon: Icons.backup_outlined,
              onPressed: () async {
                final backupJson = await ref.read(settingsNotifierProvider.notifier).createBackup();
                await Clipboard.setData(ClipboardData(text: backupJson));
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup generated and copied to clipboard! Save it in a secure location.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Restore From Backup JSON',
              icon: Icons.restore_outlined,
              onPressed: () {
                Navigator.pop(ctx);
                _showRestoreDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste your backup JSON below to restore records:'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Paste backup JSON here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final counts = await ref.read(settingsNotifierProvider.notifier).restoreBackup(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Restored ${counts['transactions']} transactions, ${counts['budgets']} budgets, ${counts['goals']} goals.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore failed: $e')),
                  );
                }
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showExportSheet(BuildContext context, WidgetRef ref) {
    final palette = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Export Financial Data', style: AppTypography.sectionHeading.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Text('All exports are sanitized against spreadsheet formula injection (DDE) per AGENTS.md.', style: AppTypography.supporting.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Export Transactions as CSV',
              icon: Icons.table_chart_outlined,
              onPressed: () async {
                final csv = await ref.read(settingsNotifierProvider.notifier).exportTransactionsCsv();
                await Clipboard.setData(ClipboardData(text: csv));
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sanitized CSV copied to clipboard!')),
                  );
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: 'Export Complete Data as JSON',
              icon: Icons.code_outlined,
              onPressed: () async {
                final json = await ref.read(settingsNotifierProvider.notifier).exportDataJson();
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Complete JSON backup copied to clipboard!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Transactions (CSV)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste CSV records formatted as:\nDate,Type,Amount,Category,Account,Description'),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Paste CSV text here...'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final count = await ref.read(settingsNotifierProvider.notifier).importTransactionsCsv(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Successfully imported $count transactions.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import failed: $e')),
                  );
                }
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDataDialog(BuildContext context, WidgetRef ref) {
    final confirmationController = TextEditingController();
    final palette = context.appColors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: palette.negative),
            const SizedBox(width: AppSpacing.sm),
            const Text('Reset All Data?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is an irreversible destructive action. All transactions, accounts, budgets, goals, and AI memory will be erased and reset to fresh defaults.',
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Type "RESET" to confirm:'),
            const SizedBox(height: 4),
            TextField(
              controller: confirmationController,
              decoration: const InputDecoration(hintText: 'RESET'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: palette.negative),
            onPressed: () async {
              if (confirmationController.text.trim().toUpperCase() != 'RESET') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please type "RESET" to confirm.')),
                );
                return;
              }
              await ref.read(settingsNotifierProvider.notifier).clearAllData();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data successfully cleared and reset.')),
                );
              }
            },
            child: const Text('Clear Everything', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('MayPeraPa'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0+1 (Production Release)'),
            SizedBox(height: AppSpacing.xs),
            Text('Architecture: Offline-First Clean Architecture'),
            SizedBox(height: AppSpacing.xs),
            Text('Database: Encrypted SQLCipher (AES-256)'),
            SizedBox(height: AppSpacing.xs),
            Text('Security: Keystore / Hardware-Backed Key Management'),
            SizedBox(height: AppSpacing.xs),
            Text('AI Engine: Maya Intelligence'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showPrivacyPolicySheet(BuildContext context) {
    final palette = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Privacy Policy', style: AppTypography.sectionHeading.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '1. 100% Offline & Local Storage\nMayPeraPa is built from the ground up to respect your financial privacy. All transactions, accounts, categories, budgets, and goals remain exclusively on your local device.\n\n'
              '2. No Cloud Transmission or Telemetry\nWe do not operate remote tracking servers, third-party analytics, or behavioral telemetry. Your financial numbers are never sold, collected, or shared.\n\n'
              '3. Encryption at Rest\nSensitive local databases are encrypted using SQLCipher with keys generated in your device\'s hardware-backed Keystore or Keychain.\n\n'
              '4. On-Device AI Intelligence\nWhen using Instant Offline or Local Neural modes, all AI financial logic executes 100% locally on your device\'s CPU/NPU without internet connectivity.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsSheet(BuildContext context) {
    final palette = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Terms of Service', style: AppTypography.sectionHeading.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '1. Personal Finance Tool\nMayPeraPa is designed solely for informational, tracking, and budgeting purposes. AI suggestions and simulations do not constitute certified legal, tax, or investment advice.\n\n'
              '2. Data Ownership\nYou hold sole ownership and control of your financial records. Because data is stored locally on your device, you are responsible for maintaining regular offline backups via the Backup & Restore feature.\n\n'
              '3. Open Source & License\nMayPeraPa is licensed under the MIT License. You are free to inspect, modify, and audit the application source code.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext context) {
    final feedbackController = TextEditingController();
    final palette = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Send Feedback & Diagnostics', style: AppTypography.sectionHeading.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Help us improve MayPeraPa or report an issue.', style: AppTypography.supporting.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share your feedback or bug details...',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(
              label: 'Copy Diagnostic Report',
              icon: Icons.copy_outlined,
              onPressed: () async {
                final report = 'MayPeraPa Diagnostics\n'
                    'Version: 1.0.0+1\n'
                    'Timestamp: ${DateTime.now().toIso8601String()}\n'
                    'User feedback: ${feedbackController.text.trim()}\n';
                await Clipboard.setData(ClipboardData(text: report));
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Diagnostic report copied to clipboard!')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet({
    required BuildContext context,
    required String title,
    required List<_SelectionOption> items,
  }) {
    final palette = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(color: palette.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(title, style: AppTypography.sectionHeading.copyWith(color: palette.textPrimary)),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...items.map((item) => TactileBounce(
                    onTap: item.onTap,
                    child: ListTile(
                      title: Text(item.title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w500)),
                      subtitle: item.subtitle != null
                          ? Text(item.subtitle!, style: AppTypography.caption.copyWith(color: palette.textSecondary))
                          : null,
                      trailing: item.isSelected ? Icon(Icons.check, color: palette.primary) : null,
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionOption {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  _SelectionOption({
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../infrastructure/security/key_management/security_manager.dart';
import '../../../../shared/presentation/providers/app_providers.dart';
import '../../../accounts/presentation/accounts_provider.dart';
import '../../../ai_assistant/presentation/providers/ai_chat_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../goals/presentation/providers/goals_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../services/data_management_service.dart';

final securityManagerProvider = Provider<SecurityManager>((ref) {
  return SecurityManager();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  final securityManager = ref.watch(securityManagerProvider);
  return SettingsRepositoryImpl(dbHelper, securityManager);
});

final dataManagementServiceProvider = Provider<DataManagementService>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return DataManagementService(dbHelper);
});

class SettingsNotifier extends Notifier<AsyncValue<AppSettings>> {
  @override
  AsyncValue<AppSettings> build() {
    _loadSettings();
    return const AsyncValue.loading();
  }

  Future<void> _loadSettings() async {
    final userId = ref.read(currentUserIdProvider);
    final repo = ref.read(settingsRepositoryProvider);
    try {
      final settings = await repo.getSettings(userId);
      // Synchronize CurrencyFormatter default with persisted currency code
      CurrencyFormatter.defaultCurrency = settings.currencyCode;
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setCurrency(String currencyCode) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(currencyCode: currencyCode);
    state = AsyncValue.data(updated);
    CurrencyFormatter.defaultCurrency = currencyCode;
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
    // Invalidate dependent providers so UI re-renders with new currency
    ref.invalidate(transactionsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(activeBudgetProvider);
    ref.invalidate(goalsProvider);
  }

  Future<void> setTheme(String theme) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(theme: theme);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> setLanguage(String language) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(language: language);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> toggleAppLock(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(autoLockEnabled: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> toggleBiometrics(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(biometricEnabled: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> setAutoLockTimeout(int seconds) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(autoLockTimeoutSeconds: seconds);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> setPIN(String pin) async {
    final sec = ref.read(securityManagerProvider);
    await sec.setPIN(pin);
    final current = state.valueOrNull;
    if (current != null) {
      final updated = current.copyWith(
        hasPinConfigured: true,
        autoLockEnabled: true,
      );
      state = AsyncValue.data(updated);
      await ref.read(settingsRepositoryProvider).saveSettings(updated);
    }
  }

  Future<bool> verifyPIN(String pin) async {
    final sec = ref.read(securityManagerProvider);
    return sec.verifyPIN(pin);
  }

  Future<void> toggleAiMemory(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(aiMemoryEnabled: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> toggleBudgetAlerts(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(budgetAlertsEnabled: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> toggleGoalReminders(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(goalRemindersEnabled: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> toggleUpcomingExpenses(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(upcomingExpensesEnabled: enabled);
    state = AsyncValue.data(updated);
    await ref.read(settingsRepositoryProvider).saveSettings(updated);
  }

  Future<void> clearAiMemory() async {
    final userId = ref.read(currentUserIdProvider);
    await ref.read(dataManagementServiceProvider).clearAiMemory(userId);
    ref.read(aiChatProvider.notifier).clearChat();
  }

  Future<String> exportTransactionsCsv() async {
    final userId = ref.read(currentUserIdProvider);
    return ref.read(dataManagementServiceProvider).exportTransactionsCsv(userId);
  }

  Future<String> exportDataJson() async {
    final userId = ref.read(currentUserIdProvider);
    return ref.read(dataManagementServiceProvider).exportDataJson(userId);
  }

  Future<String> createBackup() async {
    final userId = ref.read(currentUserIdProvider);
    final backup = await ref.read(dataManagementServiceProvider).createBackup(userId);
    final current = state.valueOrNull;
    if (current != null) {
      final updated = current.copyWith(lastBackupDate: DateTime.now());
      state = AsyncValue.data(updated);
    }
    return backup;
  }

  Future<Map<String, int>> restoreBackup(String jsonContent) async {
    final userId = ref.read(currentUserIdProvider);
    final counts = await ref.read(dataManagementServiceProvider).restoreBackup(jsonContent, userId);
    _invalidateAllUserData();
    return counts;
  }

  Future<int> importTransactionsCsv(String csvContent) async {
    final userId = ref.read(currentUserIdProvider);
    final count = await ref.read(dataManagementServiceProvider).importTransactionsCsv(csvContent, userId);
    _invalidateAllUserData();
    return count;
  }

  Future<void> clearAllData() async {
    final userId = ref.read(currentUserIdProvider);
    await ref.read(dataManagementServiceProvider).clearAllData(userId);
    await ref.read(settingsRepositoryProvider).resetSettings(userId);
    ref.read(aiChatProvider.notifier).clearChat();
    _invalidateAllUserData();
    await _loadSettings();
  }

  void _invalidateAllUserData() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(accountsProvider);
    ref.invalidate(activeBudgetProvider);
    ref.invalidate(goalsProvider);
  }
}

final settingsNotifierProvider =
    NotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>(SettingsNotifier.new);

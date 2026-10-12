import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';
import 'package:mayperapa/features/accounts/presentation/accounts_provider.dart';
import 'package:mayperapa/features/settings/presentation/providers/settings_provider.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize in main or override in tests');
});

final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingCompletedNotifier, bool>(OnboardingCompletedNotifier.new);

class OnboardingCompletedNotifier extends AsyncNotifier<bool> {
  static const String _prefKey = 'mayperapa_onboarding_completed';

  @override
  Future<bool> build() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompleted = prefs.getBool(_prefKey);
      if (hasCompleted != null) return hasCompleted;

      // For existing active installs with seeded transactions, do not disrupt user
      final accountRepo = ref.read(accountRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      final accounts = await accountRepo.getAllForUser(userId);
      if (accounts.length > 1) {
        await prefs.setBool(_prefKey, true);
        return true;
      }

      return false;
    } catch (_) {
      return true; // Fallback to avoid locking app if storage is unavailable
    }
  }

  /// Completes onboarding, configures initial currency, seeds starting balances,
  /// sets optional security PIN, and marks onboarding complete.
  Future<void> completeOnboarding({
    required String currencyCode,
    double? initialCash,
    double? initialEWallet,
    String? eWalletName,
    String? pin,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Set Currency
    await ref.read(settingsNotifierProvider.notifier).setCurrency(currencyCode);

    // 2. Seed Starting Cash Balance if provided
    if (initialCash != null && initialCash > 0) {
      await ref.read(accountsProvider.notifier).createAccount(
            name: 'Cash in Hand',
            type: AccountType.cash,
            initialBalance: initialCash,
            currencyCode: currencyCode,
            colorHex: '#10B981',
          );
    }

    // 3. Seed Starting E-Wallet Balance if provided
    if (initialEWallet != null && initialEWallet > 0) {
      final name = eWalletName ?? 'GCash';
      final isMaya = name.toLowerCase().contains('maya');
      await ref.read(accountsProvider.notifier).createAccount(
            name: name,
            type: AccountType.digitalWallet,
            initialBalance: initialEWallet,
            currencyCode: currencyCode,
            institutionName: name,
            colorHex: isMaya ? '#00D632' : '#007DFE',
          );
    }

    // 4. Configure PIN if supplied
    if (pin != null && pin.length == 4) {
      final securityManager = ref.read(securityManagerProvider);
      await securityManager.setPIN(pin);
      ref.invalidate(settingsNotifierProvider);
    }

    // 5. Persist completion flag
    await prefs.setBool(_prefKey, true);
    state = const AsyncValue.data(true);
  }

  /// Reset onboarding state (useful for testing or full reset in debug mode)
  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    state = const AsyncValue.data(false);
  }
}

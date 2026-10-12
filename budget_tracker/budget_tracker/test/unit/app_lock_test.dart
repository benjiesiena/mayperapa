import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/features/security/presentation/providers/app_lock_provider.dart';
import 'package:mayperapa/features/settings/domain/entities/app_settings.dart';
import 'package:mayperapa/features/settings/presentation/providers/settings_provider.dart';
import 'package:mayperapa/infrastructure/security/key_management/security_manager.dart';

class FakeSecurityManager extends SecurityManager {
  String? configuredPin;
  bool biometricAvailable;
  bool biometricAuthSuccess;

  FakeSecurityManager({
    this.configuredPin,
    this.biometricAvailable = true,
    this.biometricAuthSuccess = true,
  });

  @override
  Future<bool> hasPINConfigured() async => configuredPin != null;

  @override
  Future<bool> verifyPIN(String pin) async => pin == configuredPin;

  @override
  Future<bool> isBiometricAvailable() async => biometricAvailable;

  @override
  Future<bool> authenticateWithBiometrics({String reason = 'Unlock MayPeraPa'}) async {
    return biometricAuthSuccess;
  }
}

void main() {
  group('AppLockNotifier Unit Tests', () {
    test('initializes unlocked if user has not configured a PIN', () async {
      final fakeSecurity = FakeSecurityManager(configuredPin: null);
      final container = ProviderContainer(
        overrides: [
          securityManagerProvider.overrideWithValue(fakeSecurity),
          settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(
                const AppSettings(userId: 1, autoLockEnabled: true, hasPinConfigured: false),
              )),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(appLockProvider);
      expect(state.isLocked, isFalse);
    });

    test('initializes locked if PIN is configured and autoLockEnabled is true', () async {
      final fakeSecurity = FakeSecurityManager(configuredPin: '1234');
      final container = ProviderContainer(
        overrides: [
          securityManagerProvider.overrideWithValue(fakeSecurity),
          settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(
                const AppSettings(userId: 1, autoLockEnabled: true, hasPinConfigured: true),
              )),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(appLockProvider);
      expect(state.isLocked, isTrue);
    });

    test('digit entry, deletion, and successful PIN unlock', () async {
      final fakeSecurity = FakeSecurityManager(configuredPin: '1234');
      final container = ProviderContainer(
        overrides: [
          securityManagerProvider.overrideWithValue(fakeSecurity),
          settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(
                const AppSettings(userId: 1, autoLockEnabled: true, hasPinConfigured: true),
              )),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      expect(container.read(appLockProvider).isLocked, isTrue);

      notifier.appendPinDigit('1');
      notifier.appendPinDigit('2');
      notifier.appendPinDigit('9'); // Wrong digit
      expect(container.read(appLockProvider).pinInput, '129');

      notifier.deletePinDigit();
      expect(container.read(appLockProvider).pinInput, '12');

      notifier.appendPinDigit('3');
      notifier.appendPinDigit('4'); // Total "1234"
      expect(container.read(appLockProvider).pinInput, '1234');

      final unlocked = await notifier.submitPin();
      expect(unlocked, isTrue);
      expect(container.read(appLockProvider).isLocked, isFalse);
      expect(container.read(appLockProvider).pinInput, '');
      expect(container.read(appLockProvider).errorMessage, isNull);
    });

    test('wrong PIN increments shake key and sets error message', () async {
      final fakeSecurity = FakeSecurityManager(configuredPin: '1234');
      final container = ProviderContainer(
        overrides: [
          securityManagerProvider.overrideWithValue(fakeSecurity),
          settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(
                const AppSettings(userId: 1, autoLockEnabled: true, hasPinConfigured: true),
              )),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      notifier.appendPinDigit('9');
      notifier.appendPinDigit('9');
      notifier.appendPinDigit('9');
      notifier.appendPinDigit('9');

      final unlocked = await notifier.submitPin();
      expect(unlocked, isFalse);
      expect(container.read(appLockProvider).isLocked, isTrue);
      expect(container.read(appLockProvider).shakeKey, greaterThan(0));
      expect(container.read(appLockProvider).errorMessage, contains('Incorrect PIN'));
      expect(container.read(appLockProvider).pinInput, '');
    });

    test('biometric authentication unlocks application', () async {
      final fakeSecurity = FakeSecurityManager(configuredPin: '1234', biometricAuthSuccess: true);
      final container = ProviderContainer(
        overrides: [
          securityManagerProvider.overrideWithValue(fakeSecurity),
          settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(
                const AppSettings(userId: 1, autoLockEnabled: true, hasPinConfigured: true, biometricEnabled: true),
              )),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      expect(container.read(appLockProvider).isLocked, isTrue);

      final success = await notifier.authenticateWithBiometrics();
      expect(success, isTrue);
      expect(container.read(appLockProvider).isLocked, isFalse);
    });

    test('lifecycle observer: lock on resume when background timeout expired', () async {
      final fakeSecurity = FakeSecurityManager(configuredPin: '1234');
      final container = ProviderContainer(
        overrides: [
          securityManagerProvider.overrideWithValue(fakeSecurity),
          settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(
                const AppSettings(
                  userId: 1,
                  autoLockEnabled: true,
                  hasPinConfigured: true,
                  autoLockTimeoutSeconds: 60, // 1 minute
                ),
              )),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      // Unlock first
      notifier.unlock();
      expect(container.read(appLockProvider).isLocked, isFalse);

      // App paused 30s ago (less than 60s timeout) -> should NOT lock
      notifier.onAppPaused(pausedAt: DateTime.now().subtract(const Duration(seconds: 30)));
      notifier.onAppResumed(resumedAt: DateTime.now());
      expect(container.read(appLockProvider).isLocked, isFalse);

      // App paused 70s ago (exceeds 60s timeout) -> should lock
      notifier.onAppPaused(pausedAt: DateTime.now().subtract(const Duration(seconds: 70)));
      notifier.onAppResumed(resumedAt: DateTime.now());
      expect(container.read(appLockProvider).isLocked, isTrue);
    });

    test('updating settings while in unlocked session preserves unlocked state', () async {
      final fakeSecurity = FakeSecurityManager(configuredPin: '1234');
      final settingsNotifier = _FakeSettingsNotifier(
        const AppSettings(
          userId: 1,
          autoLockEnabled: true,
          hasPinConfigured: true,
          currencyCode: 'PHP',
          theme: 'light',
        ),
      );

      final container = ProviderContainer(
        overrides: [
          securityManagerProvider.overrideWithValue(fakeSecurity),
          settingsNotifierProvider.overrideWith(() => settingsNotifier),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(appLockProvider.notifier);
      expect(container.read(appLockProvider).isLocked, isTrue);

      // User unlocks with PIN
      notifier.unlock();
      expect(container.read(appLockProvider).isLocked, isFalse);

      // User changes currency / theme setting in Settings
      settingsNotifier.updateSettings(
        const AppSettings(
          userId: 1,
          autoLockEnabled: true,
          hasPinConfigured: true,
          currencyCode: 'USD',
          theme: 'dark',
        ),
      );

      // Verify that app lock state remains UNLOCKED
      expect(container.read(appLockProvider).isLocked, isFalse);
    });
  });
}

class _FakeSettingsNotifier extends SettingsNotifier {
  AppSettings _current;
  _FakeSettingsNotifier(this._current);

  @override
  AsyncValue<AppSettings> build() => AsyncValue.data(_current);

  void updateSettings(AppSettings newSettings) {
    _current = newSettings;
    state = AsyncValue.data(newSettings);
  }
}

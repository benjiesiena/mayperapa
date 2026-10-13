import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_lock_state.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(() {
  return AppLockNotifier();
});

class AppLockNotifier extends Notifier<AppLockState> {
  DateTime? _lastPausedAt;
  bool _isAuthenticatedSession = false;

  @override
  AppLockState build() {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final settings = settingsAsync.valueOrNull;

    final hasSecurityConfigured = settings != null &&
        settings.autoLockEnabled &&
        settings.hasPinConfigured;

    final canBiometrics = settings != null &&
        settings.biometricEnabled &&
        settings.hasPinConfigured;

    // Only mark session as authenticated if settings have finished loading
    // and security is confirmed to be unconfigured or disabled.
    // If settings are still loading (settings == null), do NOT mark session authenticated.
    if (settings != null && !hasSecurityConfigured) {
      _isAuthenticatedSession = true;
    }

    // Lock on cold boot when security is configured and session is not yet unlocked
    final isLocked = hasSecurityConfigured && !_isAuthenticatedSession;

    final currentPinLength = stateOrNull?.pinLength ?? 4;
    if (isLocked) {
      _loadPinLength();
    }

    return AppLockState(
      isLocked: isLocked,
      canUseBiometrics: canBiometrics,
      pinLength: currentPinLength,
    );
  }

  Future<void> _loadPinLength() async {
    final sec = ref.read(securityManagerProvider);
    final length = await sec.getPinLength();
    if (state.pinLength != length) {
      state = state.copyWith(pinLength: length);
    }
  }

  void onAppPaused({DateTime? pausedAt}) {
    _lastPausedAt = pausedAt ?? DateTime.now();
  }

  void onAppResumed({DateTime? resumedAt}) {
    final pausedAt = _lastPausedAt;
    _lastPausedAt = null;

    final settings = ref.read(settingsNotifierProvider).valueOrNull;
    if (settings == null) return;

    if (!settings.autoLockEnabled || !settings.hasPinConfigured) return;

    if (pausedAt != null) {
      final now = resumedAt ?? DateTime.now();
      final elapsed = now.difference(pausedAt).inSeconds;
      if (elapsed >= settings.autoLockTimeoutSeconds) {
        lock();
      }
    }
  }

  void lock() {
    _isAuthenticatedSession = false;
    final settings = ref.read(settingsNotifierProvider).valueOrNull;
    final canBiometrics = (settings?.biometricEnabled ?? false) &&
        (settings?.hasPinConfigured ?? false);
    state = state.copyWith(
      isLocked: true,
      pinInput: '',
      clearError: true,
      canUseBiometrics: canBiometrics,
    );
    _loadPinLength();
  }

  void unlock() {
    _isAuthenticatedSession = true;
    state = state.copyWith(
      isLocked: false,
      pinInput: '',
      clearError: true,
      isAuthenticating: false,
    );
  }

  void appendPinDigit(String digit) {
    if (state.pinInput.length >= state.pinLength) return;
    final newPin = state.pinInput + digit;
    state = state.copyWith(pinInput: newPin, clearError: true);
  }

  void deletePinDigit() {
    if (state.pinInput.isEmpty) return;
    final newPin = state.pinInput.substring(0, state.pinInput.length - 1);
    state = state.copyWith(pinInput: newPin, clearError: true);
  }

  void clearPin() {
    state = state.copyWith(pinInput: '', clearError: true);
  }

  Future<bool> submitPin([String? explicitPin]) async {
    final pinToTest = explicitPin ?? state.pinInput;
    if (pinToTest.isEmpty) return false;

    state = state.copyWith(isAuthenticating: true);
    final security = ref.read(securityManagerProvider);
    final isValid = await security.verifyPIN(pinToTest);

    if (isValid) {
      _isAuthenticatedSession = true;
      state = state.copyWith(
        isLocked: false,
        isAuthenticating: false,
        pinInput: '',
        clearError: true,
      );
      return true;
    } else {
      state = state.copyWith(
        isLocked: true,
        isAuthenticating: false,
        pinInput: '',
        errorMessage: 'Incorrect PIN. Try again.',
        shakeKey: state.shakeKey + 1,
      );
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    if (state.isAuthenticating) return false;

    state = state.copyWith(isAuthenticating: true);
    final security = ref.read(securityManagerProvider);
    final authenticated = await security.authenticateWithBiometrics(reason: 'Unlock MayPeraPa');

    if (authenticated) {
      _isAuthenticatedSession = true;
      state = state.copyWith(
        isLocked: false,
        isAuthenticating: false,
        clearError: true,
      );
      return true;
    } else {
      state = state.copyWith(
        isAuthenticating: false,
      );
      return false;
    }
  }
}

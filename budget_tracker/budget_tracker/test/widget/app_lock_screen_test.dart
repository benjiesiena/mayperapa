import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/security/presentation/widgets/app_lock_gateway.dart';
import 'package:mayperapa/features/settings/domain/entities/app_settings.dart';
import 'package:mayperapa/features/settings/presentation/providers/settings_provider.dart';
import 'package:mayperapa/infrastructure/security/key_management/security_manager.dart';

class _FakeSecurityManager extends SecurityManager {
  String? configuredPin;
  bool biometricAuthSuccess;

  _FakeSecurityManager({
    this.configuredPin = '1234',
    this.biometricAuthSuccess = true,
  });

  @override
  Future<bool> hasPINConfigured() async => configuredPin != null;

  @override
  Future<bool> verifyPIN(String pin) async => pin == configuredPin;

  @override
  Future<bool> isBiometricAvailable() async => true;

  @override
  Future<bool> authenticateWithBiometrics({String reason = 'Unlock MayPeraPa'}) async {
    return biometricAuthSuccess;
  }

  @override
  Future<int> getPinLength() async => configuredPin?.length ?? 4;
}

class _FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings _initial;
  _FakeSettingsNotifier(this._initial);

  @override
  AsyncValue<AppSettings> build() => AsyncValue.data(_initial);
}

void main() {
  Widget buildTestApp({
    required _FakeSecurityManager fakeSecurity,
    required AppSettings settings,
    Widget? child,
  }) {
    return ProviderScope(
      overrides: [
        securityManagerProvider.overrideWithValue(fakeSecurity),
        settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(settings)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: AppLockGateway(
          child: child ?? const Scaffold(body: Center(child: Text('Protected Vault Content'))),
        ),
      ),
    );
  }

  group('AppLockScreen & AppLockGateway Widget Tests', () {
    testWidgets('renders AppLockScreen when locked and displays keypad & branding', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSecurity = _FakeSecurityManager(
        configuredPin: '1234',
        biometricAuthSuccess: false,
      );
      const settings = AppSettings(
        userId: 1,
        autoLockEnabled: true,
        hasPinConfigured: true,
        biometricEnabled: true,
      );

      await tester.pumpWidget(buildTestApp(fakeSecurity: fakeSecurity, settings: settings));
      await tester.pumpAndSettle();

      expect(find.text('MayPeraPa'), findsOneWidget);
      expect(find.text('Enter your PIN to unlock'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      // Verify numeric keypad digits 0-9 exist
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }

      // Verify biometric icon exists
      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
      // Verify backspace exists
      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

      // Protected content should NOT be visible yet
      expect(find.text('Protected Vault Content'), findsNothing);
    });

    testWidgets('entering correct PIN unlocks AppLockGateway to reveal content', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSecurity = _FakeSecurityManager(configuredPin: '1234');
      const settings = AppSettings(
        userId: 1,
        autoLockEnabled: true,
        hasPinConfigured: true,
        biometricEnabled: false,
      );

      await tester.pumpWidget(buildTestApp(fakeSecurity: fakeSecurity, settings: settings));
      await tester.pumpAndSettle();

      // Tap 1, 2, 3, 4
      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('3'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      // App unlocks and shows protected content!
      expect(find.text('Protected Vault Content'), findsOneWidget);
      expect(find.text('Enter your PIN to unlock'), findsNothing);
    });

    testWidgets('entering wrong PIN shows error message', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSecurity = _FakeSecurityManager(configuredPin: '1234');
      const settings = AppSettings(
        userId: 1,
        autoLockEnabled: true,
        hasPinConfigured: true,
        biometricEnabled: false,
      );

      await tester.pumpWidget(buildTestApp(fakeSecurity: fakeSecurity, settings: settings));
      await tester.pumpAndSettle();

      // Tap wrong PIN: 9, 9, 9, 9
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('9'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();

      // Error message is shown and stays locked
      expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);
      expect(find.text('Protected Vault Content'), findsNothing);
    });

    testWidgets('tapping backspace removes entered digits', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSecurity = _FakeSecurityManager(configuredPin: '1234');
      const settings = AppSettings(
        userId: 1,
        autoLockEnabled: true,
        hasPinConfigured: true,
        biometricEnabled: false,
      );

      await tester.pumpWidget(buildTestApp(fakeSecurity: fakeSecurity, settings: settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 50));

      // Tap backspace
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();

      // Continue with 2, 3, 4 -> Total "1234"
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('3'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      expect(find.text('Protected Vault Content'), findsOneWidget);
    });

    testWidgets('tapping biometric button unlocks the screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fakeSecurity = _FakeSecurityManager(
        configuredPin: '1234',
        biometricAuthSuccess: false,
      );
      const settings = AppSettings(
        userId: 1,
        autoLockEnabled: true,
        hasPinConfigured: true,
        biometricEnabled: true,
      );

      await tester.pumpWidget(buildTestApp(fakeSecurity: fakeSecurity, settings: settings));
      await tester.pumpAndSettle();

      // Fingerprint button is visible and app is still locked
      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);

      // Now user presents valid biometric
      fakeSecurity.biometricAuthSuccess = true;
      await tester.tap(find.byIcon(Icons.fingerprint_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Protected Vault Content'), findsOneWidget);
    });
  });
}

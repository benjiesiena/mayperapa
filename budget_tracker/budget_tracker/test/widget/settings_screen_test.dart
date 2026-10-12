import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/settings/domain/entities/app_settings.dart';
import 'package:mayperapa/features/settings/presentation/providers/settings_provider.dart';
import 'package:mayperapa/features/settings/presentation/settings_screen.dart';

void main() {
  Widget buildTestApp({AppSettings? customSettings}) {
    final settings = customSettings ??
        const AppSettings(
          userId: 1,
          theme: 'system',
          currencyCode: 'PHP',
          language: 'en',
          autoLockEnabled: true,
          biometricEnabled: false,
          autoLockTimeoutSeconds: 300,
          aiMemoryEnabled: true,
          budgetAlertsEnabled: true,
          goalRemindersEnabled: true,
          upcomingExpensesEnabled: true,
          hasPinConfigured: true,
        );

    return ProviderScope(
      overrides: [
        settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(settings)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const SettingsScreen(),
      ),
    );
  }

  void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('SettingsScreen — UI/UX & Interaction Tests', () {
    testWidgets('renders Preferences, Security and AI Settings rows', (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Verify Section Headers
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('SECURITY'), findsOneWidget);
      expect(find.text('AI SETTINGS'), findsOneWidget);
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('DATA'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);

      // Verify rows
      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('App Lock'), findsOneWidget);
      expect(find.text('Biometrics'), findsOneWidget);
      expect(find.text('Auto-lock timeout'), findsOneWidget);
      expect(find.text('Change PIN'), findsOneWidget);
      expect(find.text('AI Memory'), findsOneWidget);
      expect(find.text('Coaching Tone'), findsOneWidget);
      expect(find.text('Payday Schedule'), findsOneWidget);
      expect(find.text('Model Version'), findsOneWidget);
      expect(find.text('Clear AI Memory'), findsOneWidget);
    });

    testWidgets('tapping Coaching Tone opens persona selection sheet', (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Coaching Tone'));
      await tester.pumpAndSettle();

      expect(find.text('Coaching Persona Tone'), findsOneWidget);
      expect(find.text('Gentle Guide'), findsWidgets);
      expect(find.text('Direct Analyst'), findsOneWidget);
      expect(find.text('Socratic Challenger'), findsOneWidget);
    });

    testWidgets('tapping Payday Schedule opens payday selection sheet', (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Payday Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Payday Schedule'), findsWidgets);
      expect(find.text('15th and 30th of the month'), findsWidgets);
      expect(find.text('10th and 25th of the month'), findsOneWidget);
    });

    testWidgets('tapping Currency opens selection bottom sheet', (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      expect(find.text('Select Currency'), findsOneWidget);
      expect(find.text('USD (\$)'), findsOneWidget);
      expect(find.text('EUR (€)'), findsOneWidget);
      expect(find.text('Philippine Peso'), findsOneWidget);
    });

    testWidgets('tapping Theme opens theme choice sheet', (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Theme'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('tapping Model Version opens AI Engine selection sheet', (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Model Version'));
      await tester.pumpAndSettle();

      expect(find.text('AI Engine & Model Architecture'), findsOneWidget);
      expect(find.text('Instant Offline (Rule-based)'), findsOneWidget);
      expect(find.text('Cloud Advisor (Google Gemini Flash)'), findsOneWidget);
    });

    testWidgets('tapping Version opens about app dialog', (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Version'));
      await tester.pumpAndSettle();

      expect(find.text('MayPeraPa'), findsOneWidget);
      expect(find.text('Version: 1.0.0+1 (Production Release)'), findsOneWidget);
      expect(find.text('Database: Encrypted SQLCipher (AES-256)'), findsOneWidget);
    });

    testWidgets('tapping Privacy Policy opens privacy policy modal sheet', (tester) async {
      setupViewport(tester);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.textContaining('100% Offline & Local Storage'), findsOneWidget);
    });
  });
}

class _FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings _initial;

  _FakeSettingsNotifier(this._initial);

  @override
  AsyncValue<AppSettings> build() {
    return AsyncValue.data(_initial);
  }
}

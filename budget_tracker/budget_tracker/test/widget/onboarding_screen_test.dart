import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mayperapa/features/settings/domain/entities/app_settings.dart';
import 'package:mayperapa/features/settings/presentation/providers/settings_provider.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';

import '../unit/accounts_management_test.dart';

class _FakeSettingsNotifier extends SettingsNotifier {
  final AppSettings _initial;

  _FakeSettingsNotifier(this._initial);

  @override
  AsyncValue<AppSettings> build() {
    return AsyncValue.data(_initial);
  }

  @override
  Future<void> setCurrency(String currencyCode) async {
    final current = state.valueOrNull ?? _initial;
    state = AsyncValue.data(current.copyWith(currencyCode: currencyCode));
  }
}

void main() {
  group('OnboardingScreen Widget Tests', () {
    late FakeAccountRepository fakeAccountRepo;
    late FakeTransactionRepository fakeTxnRepo;
    late FakeCategoryRepository fakeCategoryRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeAccountRepo = FakeAccountRepository();
      fakeTxnRepo = FakeTransactionRepository();
      fakeCategoryRepo = FakeCategoryRepository();
    });

    Widget createTestWidget({VoidCallback? onFinished}) {
      return ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(fakeAccountRepo),
          transactionRepositoryProvider.overrideWithValue(fakeTxnRepo),
          categoryRepositoryProvider.overrideWithValue(fakeCategoryRepo),
          settingsNotifierProvider.overrideWith(
            () => _FakeSettingsNotifier(const AppSettings(
              userId: 1,
              theme: 'dark',
              currencyCode: 'PHP',
              language: 'en',
              autoLockEnabled: false,
              biometricEnabled: false,
              autoLockTimeoutSeconds: 300,
              aiMemoryEnabled: true,
              budgetAlertsEnabled: true,
              goalRemindersEnabled: true,
              upcomingExpensesEnabled: true,
              hasPinConfigured: false,
            )),
          ),
          currentUserIdProvider.overrideWithValue(1),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: OnboardingScreen(onFinished: onFinished),
        ),
      );
    }

    testWidgets('walks through 3-step setup flow from currency to Maya finish', (tester) async {
      bool finishedCalled = false;

      await tester.pumpWidget(createTestWidget(onFinished: () {
        finishedCalled = true;
      }));
      await tester.pumpAndSettle();

      // Step 1: Currency Selection
      expect(find.text('Welcome to MayPeraPa'), findsOneWidget);
      expect(find.text('Philippine Peso'), findsOneWidget);
      expect(find.text('US Dollar'), findsOneWidget);

      // Select USD
      await tester.tap(find.text('US Dollar'));
      await tester.pumpAndSettle();

      // Tap Continue to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 2: Starting Balances
      expect(find.text('Starting Balances'), findsOneWidget);
      expect(find.text('PHYSICAL CASH'), findsOneWidget);
      expect(find.text('GCash'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);

      // Enter cash and ewallet
      await tester.enterText(find.byType(TextField).first, '1200');
      await tester.enterText(find.byType(TextField).last, '3500');
      await tester.pumpAndSettle();

      // Tap Continue to Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Step 3: Meet Maya
      expect(find.text('Meet Maya'), findsOneWidget);
      expect(find.text('Maya Financial Co-Pilot'), findsOneWidget);
      expect(find.text('Local & Privacy First'), findsOneWidget);
      expect(find.text('Protect app with 4-Digit PIN'), findsOneWidget);

      // Tap Launch MayPeraPa
      await tester.tap(find.text('Launch MayPeraPa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(finishedCalled, true);
    });
  });
}

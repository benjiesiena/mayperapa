import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/features/notifications/domain/services/notification_scheduler.dart';
import 'package:mayperapa/features/notifications/presentation/notifications_provider.dart';
import 'package:mayperapa/features/settings/presentation/providers/settings_provider.dart';
import 'package:mayperapa/features/settings/domain/entities/app_settings.dart';
import 'package:mayperapa/features/budgets/presentation/providers/budgets_provider.dart';
import 'package:mayperapa/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:mayperapa/shared/domain/entities/budget.dart';
import 'package:mayperapa/shared/domain/entities/enums.dart';
import 'package:mayperapa/shared/domain/entities/transaction.dart';

class MockNotificationScheduler implements NotificationScheduler {
  bool initialized = false;
  int cancelAllCount = 0;
  final List<String> triggeredAlerts = [];
  final List<int> scheduledBillIds = [];

  @override
  Future<void> initialize() async => initialized = true;

  @override
  Future<void> scheduleBillReminder({
    required int billId,
    required String title,
    required double amount,
    required DateTime dueDate,
  }) async {
    scheduledBillIds.add(billId);
  }

  @override
  Future<void> triggerThresholdAlert({
    required String categoryName,
    required double percentUsed,
  }) async {
    triggeredAlerts.add('$categoryName:${(percentUsed * 100).toInt()}%');
  }

  @override
  Future<void> triggerGoalMilestoneAlert({
    required String goalName,
    required double progressPercent,
  }) async {
    triggeredAlerts.add('goal:$goalName');
  }

  @override
  Future<void> cancelReminder(int reminderId) async {}

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
  }
}

class _FakeSettingsNotifier extends Notifier<AsyncValue<AppSettings>> implements SettingsNotifier {
  final AppSettings _settings;
  _FakeSettingsNotifier(this._settings);

  @override
  AsyncValue<AppSettings> build() => AsyncValue.data(_settings);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransactionsNotifier extends AsyncNotifier<List<Transaction>> implements TransactionsNotifier {
  final List<Transaction> _initial;
  _FakeTransactionsNotifier(this._initial);

  @override
  Future<List<Transaction>> build() async => _initial;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Notification Coordinator Tests', () {
    late MockNotificationScheduler mockScheduler;

    setUp(() {
      mockScheduler = MockNotificationScheduler();
    });

    test('cancels all alerts when budgetAlertsEnabled is disabled', () {
      final testContainer = ProviderContainer(
        overrides: [
          notificationSchedulerProvider.overrideWithValue(mockScheduler),
          settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(
                const AppSettings(
                  userId: 1,
                  budgetAlertsEnabled: false,
                ),
              )),
        ],
      );

      testContainer.read(notificationCoordinatorProvider);
      expect(mockScheduler.cancelAllCount, 1);
    });

    test('triggers threshold alert when spending reaches 85%+', () async {
      final now = DateTime.now();
      final testBudget = Budget(
        id: 1,
        userId: 1,
        name: 'Monthly Groceries',
        type: BudgetType.monthly,
        periodStart: DateTime(now.year, now.month, 1),
        periodEnd: DateTime(now.year, now.month, 28),
        totalBudget: 10000,
        strategy: BudgetStrategy.zeroBased,
        createdAt: now,
        updatedAt: now,
      );

      final testTxns = [
        Transaction(
          id: 1,
          userId: 1,
          accountId: 1,
          categoryId: 1,
          type: TransactionType.expense,
          amount: 8800, // 88%
          date: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final testContainer = ProviderContainer(
        overrides: [
          notificationSchedulerProvider.overrideWithValue(mockScheduler),
          settingsNotifierProvider.overrideWith(() => _FakeSettingsNotifier(
                const AppSettings(
                  userId: 1,
                  budgetAlertsEnabled: true,
                ),
              )),
          activeBudgetProvider.overrideWith((ref) => Future.value(
                ActiveBudgetState(budget: testBudget, spent: 8800),
              )),
          transactionsProvider.overrideWith(() => _FakeTransactionsNotifier(testTxns)),
        ],
      );

      await testContainer.read(activeBudgetProvider.future);
      await testContainer.read(transactionsProvider.future);
      testContainer.read(notificationCoordinatorProvider);
      expect(mockScheduler.triggeredAlerts.isNotEmpty, true);
      expect(mockScheduler.triggeredAlerts.first, contains('Monthly Groceries'));
    });
  });
}

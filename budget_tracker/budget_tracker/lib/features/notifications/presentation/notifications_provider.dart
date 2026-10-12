import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../budgets/presentation/providers/budgets_provider.dart';
import '../../settings/presentation/providers/settings_provider.dart';
import '../../transactions/presentation/providers/transactions_provider.dart';
import '../domain/services/budget_alert_evaluator.dart';
import '../domain/services/notification_scheduler.dart';
import '../infrastructure/local_notification_scheduler.dart';

/// Provider for the notification scheduler singleton.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final scheduler = LocalNotificationScheduler();
  scheduler.initialize();
  return scheduler;
});

/// Provider for pure threshold and bill evaluator.
final budgetAlertEvaluatorProvider = Provider<BudgetAlertEvaluator>((ref) {
  return const BudgetAlertEvaluator();
});

/// Coordinator that synchronizes user alert settings, active transactions,
/// and budget thresholds.
final notificationCoordinatorProvider = Provider<void>((ref) {
  final settings = ref.watch(settingsNotifierProvider).valueOrNull;
  final scheduler = ref.watch(notificationSchedulerProvider);
  final evaluator = ref.watch(budgetAlertEvaluatorProvider);

  if (settings == null) return;

  // If alerts are disabled in Settings, cleanly cancel all alarms
  if (!settings.budgetAlertsEnabled) {
    scheduler.cancelAll();
    return;
  }

  // Watch transactions and budgets for proactive threshold monitoring
  final transactions = ref.watch(transactionsProvider).valueOrNull ?? [];
  final activeBudgetState = ref.watch(activeBudgetProvider).valueOrNull;
  final budget = activeBudgetState?.budget;

  if (budget != null && budget.isActive) {
    final alerts = evaluator.evaluateBudgetThresholds(
      budgets: [budget],
      transactions: transactions,
    );

    for (final alert in alerts) {
      final ratio = double.tryParse(alert.payload?['ratio'] ?? '0') ?? 0;
      scheduler.triggerThresholdAlert(
        categoryName: budget.name,
        percentUsed: ratio,
      );
    }
  }
});

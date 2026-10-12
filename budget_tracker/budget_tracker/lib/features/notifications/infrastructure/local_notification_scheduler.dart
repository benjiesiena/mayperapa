import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/currency_formatter.dart';
import '../domain/services/notification_scheduler.dart';

class LocalNotificationScheduler implements NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  LocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String _channelId = 'mayperapa_alerts';
  static const String _channelName = 'MayPeraPa Alerts';
  static const String _channelDesc = 'Proactive threshold warnings and bill due date reminders';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      // On non-supported desktop platforms (Windows/Linux without dbus/win-toast), plugin may be no-op
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux)) {
        await _plugin.initialize(initSettings);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('LocalNotificationScheduler init notice: $e');
      _initialized = true; // non-fatal fallback
    }
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }

  @override
  Future<void> scheduleBillReminder({
    required int billId,
    required String title,
    required double amount,
    required DateTime dueDate,
  }) async {
    await initialize();
    try {
      final scheduledTz = tz.TZDateTime.from(dueDate, tz.local);
      if (scheduledTz.isBefore(tz.TZDateTime.now(tz.local))) return;

      await _plugin.zonedSchedule(
        billId,
        'Upcoming Bill: $title',
        '${CurrencyFormatter.format(amount)} is due on ${dueDate.month}/${dueDate.day}.',
        scheduledTz,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule bill reminder $billId: $e');
    }
  }

  @override
  Future<void> triggerThresholdAlert({
    required String categoryName,
    required double percentUsed,
  }) async {
    await initialize();
    try {
      final percentString = (percentUsed * 100).toStringAsFixed(0);
      final isExceeded = percentUsed >= 1.0;
      final title = isExceeded ? 'Budget Limit Exceeded: $categoryName' : 'Budget Warning: $categoryName';
      final body = isExceeded
          ? 'You have spent 100%+ of your $categoryName budget.'
          : 'You have used $percentString% of your $categoryName budget.';

      await _plugin.show(
        categoryName.hashCode.abs() % 100000,
        title,
        body,
        _notificationDetails(),
      );
    } catch (e) {
      debugPrint('Failed to trigger threshold alert for $categoryName: $e');
    }
  }

  @override
  Future<void> triggerGoalMilestoneAlert({
    required String goalName,
    required double progressPercent,
  }) async {
    await initialize();
    try {
      final isComplete = progressPercent >= 1.0;
      final title = isComplete ? 'Goal Completed!' : 'Goal Milestone Reached!';
      final body = isComplete
          ? 'Congratulations! You reached 100% of your $goalName goal!'
          : 'Keep it up! You reached ${(progressPercent * 100).toStringAsFixed(0)}% of your $goalName goal.';

      await _plugin.show(
        goalName.hashCode.abs() % 100000,
        title,
        body,
        _notificationDetails(),
      );
    } catch (e) {
      debugPrint('Failed to trigger goal alert for $goalName: $e');
    }
  }

  @override
  Future<void> cancelReminder(int reminderId) async {
    try {
      await _plugin.cancel(reminderId);
    } catch (e) {
      debugPrint('Failed to cancel reminder $reminderId: $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }
}

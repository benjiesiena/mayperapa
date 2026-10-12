abstract class NotificationScheduler {
  Future<void> initialize();

  /// Schedules a proactive reminder for an upcoming bill or subscription.
  Future<void> scheduleBillReminder({
    required int billId,
    required String title,
    required double amount,
    required DateTime dueDate,
  });

  /// Immediately triggers a threshold warning when spending reaches 85% or 100%.
  Future<void> triggerThresholdAlert({
    required String categoryName,
    required double percentUsed,
  });

  /// Immediately fires when a savings goal milestone (e.g. 50%, 100%) is achieved.
  Future<void> triggerGoalMilestoneAlert({
    required String goalName,
    required double progressPercent,
  });

  /// Cancels a specific scheduled reminder.
  Future<void> cancelReminder(int reminderId);

  /// Cancels all scheduled alerts (e.g. when budget alerts setting is disabled).
  Future<void> cancelAll();
}

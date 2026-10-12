import 'package:equatable/equatable.dart';

enum AlertTriggerType {
  budgetThreshold85,
  upcomingBill,
  goalMilestone,
}

class ScheduledAlert extends Equatable {
  final int id;
  final String title;
  final String body;
  final AlertTriggerType triggerType;
  final DateTime scheduledDate;
  final Map<String, String>? payload;

  const ScheduledAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.triggerType,
    required this.scheduledDate,
    this.payload,
  });

  @override
  List<Object?> get props => [id, title, body, triggerType, scheduledDate, payload];
}

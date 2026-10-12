import 'package:flutter/material.dart';

/// AppSettings entity representing the user's persisted preferences,
/// security posture, AI settings, and data hygiene flags.
class AppSettings {
  final int userId;
  final String theme; // 'system', 'light', 'dark'
  final String language; // 'en', 'fil', 'es'
  final String currencyCode; // 'PHP', 'USD', 'EUR', 'GBP', 'JPY'
  final bool biometricEnabled;
  final bool autoLockEnabled;
  final int autoLockTimeoutSeconds; // 0, 60, 300, 900, 1800
  final bool notificationsEnabled;
  final bool budgetAlertsEnabled;
  final bool goalRemindersEnabled;
  final bool upcomingExpensesEnabled;
  final bool aiMemoryEnabled;
  final String aiModelVersion;
  final DateTime? lastBackupDate;
  final bool hasPinConfigured;

  const AppSettings({
    required this.userId,
    this.theme = 'system',
    this.language = 'en',
    this.currencyCode = 'PHP',
    this.biometricEnabled = false,
    this.autoLockEnabled = true,
    this.autoLockTimeoutSeconds = 300,
    this.notificationsEnabled = true,
    this.budgetAlertsEnabled = true,
    this.goalRemindersEnabled = true,
    this.upcomingExpensesEnabled = true,
    this.aiMemoryEnabled = true,
    this.aiModelVersion = 'v1.0 (rule-based)',
    this.lastBackupDate,
    this.hasPinConfigured = false,
  });

  /// Map string theme to Flutter [ThemeMode]
  ThemeMode get themeMode {
    switch (theme.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String get themeLabel {
    switch (theme.toLowerCase()) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'system':
      default:
        return 'System';
    }
  }

  String get currencySymbol {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'PHP':
      default:
        return '₱';
    }
  }

  String get languageLabel {
    switch (language.toLowerCase()) {
      case 'fil':
        return 'Filipino';
      case 'es':
        return 'Español';
      case 'en':
      default:
        return 'English';
    }
  }

  String get autoLockTimeoutLabel {
    if (autoLockTimeoutSeconds <= 0) return 'Immediately';
    if (autoLockTimeoutSeconds < 60) return '$autoLockTimeoutSeconds sec';
    final mins = autoLockTimeoutSeconds ~/ 60;
    return '$mins min';
  }

  AppSettings copyWith({
    int? userId,
    String? theme,
    String? language,
    String? currencyCode,
    bool? biometricEnabled,
    bool? autoLockEnabled,
    int? autoLockTimeoutSeconds,
    bool? notificationsEnabled,
    bool? budgetAlertsEnabled,
    bool? goalRemindersEnabled,
    bool? upcomingExpensesEnabled,
    bool? aiMemoryEnabled,
    String? aiModelVersion,
    DateTime? lastBackupDate,
    bool? hasPinConfigured,
  }) {
    return AppSettings(
      userId: userId ?? this.userId,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      currencyCode: currencyCode ?? this.currencyCode,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeoutSeconds: autoLockTimeoutSeconds ?? this.autoLockTimeoutSeconds,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      budgetAlertsEnabled: budgetAlertsEnabled ?? this.budgetAlertsEnabled,
      goalRemindersEnabled: goalRemindersEnabled ?? this.goalRemindersEnabled,
      upcomingExpensesEnabled: upcomingExpensesEnabled ?? this.upcomingExpensesEnabled,
      aiMemoryEnabled: aiMemoryEnabled ?? this.aiMemoryEnabled,
      aiModelVersion: aiModelVersion ?? this.aiModelVersion,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      hasPinConfigured: hasPinConfigured ?? this.hasPinConfigured,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'user_id': userId,
      'theme': theme,
      'language': language,
      'currency_format': 'symbol',
      'date_format': 'MM/dd/yyyy',
      'first_day_of_week': 0,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'auto_lock_enabled': autoLockEnabled ? 1 : 0,
      'auto_lock_timeout_seconds': autoLockTimeoutSeconds,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'budget_alert_threshold': budgetAlertsEnabled ? 0.85 : 0.0,
      'goal_reminder_enabled': goalRemindersEnabled ? 1 : 0,
      'ai_model_version': aiModelVersion,
      'last_backup_date': lastBackupDate?.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory AppSettings.fromDbMap(
    Map<String, dynamic> map, {
    String currencyCode = 'PHP',
    bool aiMemoryEnabled = true,
    bool hasPinConfigured = false,
  }) {
    final lastBackupMillis = map['last_backup_date'] as int?;
    final budgetThreshold = (map['budget_alert_threshold'] as num?)?.toDouble() ?? 0.85;

    return AppSettings(
      userId: (map['user_id'] as int?) ?? 1,
      theme: (map['theme'] as String?) ?? 'system',
      language: (map['language'] as String?) ?? 'en',
      currencyCode: currencyCode,
      biometricEnabled: ((map['biometric_enabled'] as int?) ?? 0) == 1,
      autoLockEnabled: ((map['auto_lock_enabled'] as int?) ?? 1) == 1,
      autoLockTimeoutSeconds: (map['auto_lock_timeout_seconds'] as int?) ?? 300,
      notificationsEnabled: ((map['notifications_enabled'] as int?) ?? 1) == 1,
      budgetAlertsEnabled: budgetThreshold > 0.0,
      goalRemindersEnabled: ((map['goal_reminder_enabled'] as int?) ?? 1) == 1,
      upcomingExpensesEnabled: ((map['notifications_enabled'] as int?) ?? 1) == 1,
      aiMemoryEnabled: aiMemoryEnabled,
      aiModelVersion: (map['ai_model_version'] as String?) ?? 'v1.0 (rule-based)',
      lastBackupDate: lastBackupMillis != null ? DateTime.fromMillisecondsSinceEpoch(lastBackupMillis) : null,
      hasPinConfigured: hasPinConfigured,
    );
  }
}

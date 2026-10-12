import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/features/settings/domain/entities/app_settings.dart';

void main() {
  group('AppSettings Entity & Domain Logic Tests', () {
    test('maps string themes correctly to Flutter ThemeMode', () {
      const systemSettings = AppSettings(userId: 1, theme: 'system');
      expect(systemSettings.themeMode, equals(ThemeMode.system));
      expect(systemSettings.themeLabel, equals('System'));

      const lightSettings = AppSettings(userId: 1, theme: 'light');
      expect(lightSettings.themeMode, equals(ThemeMode.light));
      expect(lightSettings.themeLabel, equals('Light'));

      const darkSettings = AppSettings(userId: 1, theme: 'dark');
      expect(darkSettings.themeMode, equals(ThemeMode.dark));
      expect(darkSettings.themeLabel, equals('Dark'));
    });

    test('maps currency codes to correct symbols', () {
      const php = AppSettings(userId: 1, currencyCode: 'PHP');
      expect(php.currencySymbol, equals('₱'));

      const usd = AppSettings(userId: 1, currencyCode: 'USD');
      expect(usd.currencySymbol, equals('\$'));

      const eur = AppSettings(userId: 1, currencyCode: 'EUR');
      expect(eur.currencySymbol, equals('€'));

      const gbp = AppSettings(userId: 1, currencyCode: 'GBP');
      expect(gbp.currencySymbol, equals('£'));

      const jpy = AppSettings(userId: 1, currencyCode: 'JPY');
      expect(jpy.currencySymbol, equals('¥'));
    });

    test('formats auto-lock timeout labels accurately', () {
      expect(const AppSettings(userId: 1, autoLockTimeoutSeconds: 0).autoLockTimeoutLabel, equals('Immediately'));
      expect(const AppSettings(userId: 1, autoLockTimeoutSeconds: 30).autoLockTimeoutLabel, equals('30 sec'));
      expect(const AppSettings(userId: 1, autoLockTimeoutSeconds: 60).autoLockTimeoutLabel, equals('1 min'));
      expect(const AppSettings(userId: 1, autoLockTimeoutSeconds: 300).autoLockTimeoutLabel, equals('5 min'));
      expect(const AppSettings(userId: 1, autoLockTimeoutSeconds: 900).autoLockTimeoutLabel, equals('15 min'));
    });

    test('serializes to and from database map with schema integrity', () {
      final now = DateTime(2026, 10, 6, 12, 0);
      final original = AppSettings(
        userId: 1,
        theme: 'dark',
        language: 'fil',
        currencyCode: 'PHP',
        biometricEnabled: true,
        autoLockEnabled: true,
        autoLockTimeoutSeconds: 600,
        notificationsEnabled: true,
        budgetAlertsEnabled: true,
        goalRemindersEnabled: false,
        upcomingExpensesEnabled: true,
        aiMemoryEnabled: false,
        aiModelVersion: 'v1.0 (rule-based)',
        lastBackupDate: now,
        hasPinConfigured: true,
      );

      final dbMap = original.toDbMap();
      expect(dbMap['theme'], equals('dark'));
      expect(dbMap['language'], equals('fil'));
      expect(dbMap['biometric_enabled'], equals(1));
      expect(dbMap['auto_lock_enabled'], equals(1));
      expect(dbMap['auto_lock_timeout_seconds'], equals(600));
      expect(dbMap['budget_alert_threshold'], equals(0.85));
      expect(dbMap['goal_reminder_enabled'], equals(0));
      expect(dbMap['last_backup_date'], equals(now.millisecondsSinceEpoch));

      final restored = AppSettings.fromDbMap(
        dbMap,
        currencyCode: 'PHP',
        aiMemoryEnabled: false,
        hasPinConfigured: true,
      );

      expect(restored.userId, equals(1));
      expect(restored.theme, equals('dark'));
      expect(restored.language, equals('fil'));
      expect(restored.currencyCode, equals('PHP'));
      expect(restored.biometricEnabled, isTrue);
      expect(restored.autoLockEnabled, isTrue);
      expect(restored.autoLockTimeoutSeconds, equals(600));
      expect(restored.budgetAlertsEnabled, isTrue);
      expect(restored.goalRemindersEnabled, isFalse);
      expect(restored.aiMemoryEnabled, isFalse);
      expect(restored.hasPinConfigured, isTrue);
      expect(restored.lastBackupDate, equals(now));
    });

    test('copyWith preserves immutability and updates specific fields', () {
      const base = AppSettings(userId: 1, currencyCode: 'PHP', theme: 'light');
      final updated = base.copyWith(currencyCode: 'USD', theme: 'dark');

      expect(base.currencyCode, equals('PHP'));
      expect(base.theme, equals('light'));
      expect(updated.currencyCode, equals('USD'));
      expect(updated.theme, equals('dark'));
      expect(updated.userId, equals(1));
    });
  });
}

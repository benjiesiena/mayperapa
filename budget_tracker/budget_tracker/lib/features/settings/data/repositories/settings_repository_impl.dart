import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../infrastructure/security/key_management/security_manager.dart';
import '../../../../shared/data/database/database_helper.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final DatabaseHelper _dbHelper;
  final SecurityManager _securityManager;

  SettingsRepositoryImpl(this._dbHelper, [SecurityManager? securityManager])
      : _securityManager = securityManager ?? SecurityManager();

  @override
  Future<AppSettings> getSettings(int userId) async {
    final db = await _dbHelper.database;

    // 1. Fetch app_settings
    final settingsRows = await db.query(
      'app_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    // 2. Fetch user currency_code
    final userRows = await db.query(
      'users',
      columns: ['currency_code'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final currencyCode = userRows.isNotEmpty ? (userRows.first['currency_code'] as String? ?? 'PHP') : 'PHP';

    // 3. Fetch financial_profile ai_memory_enabled
    final profileRows = await db.query(
      'financial_profile',
      columns: ['ai_memory_enabled'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final aiMemoryEnabled = profileRows.isNotEmpty
        ? ((profileRows.first['ai_memory_enabled'] as int? ?? 1) == 1)
        : true;

    // 4. Fetch PIN status from SecurityManager
    final hasPin = await _securityManager.hasPINConfigured();

    if (settingsRows.isEmpty) {
      // Seed default settings row if not present
      final defaultSettings = AppSettings(
        userId: userId,
        currencyCode: currencyCode,
        aiMemoryEnabled: aiMemoryEnabled,
        hasPinConfigured: hasPin,
      );
      await saveSettings(defaultSettings);
      return defaultSettings;
    }

    return AppSettings.fromDbMap(
      settingsRows.first,
      currencyCode: currencyCode,
      aiMemoryEnabled: aiMemoryEnabled,
      hasPinConfigured: hasPin,
    );
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      // Upsert app_settings
      final existing = await txn.query(
        'app_settings',
        where: 'user_id = ?',
        whereArgs: [settings.userId],
        limit: 1,
      );

      final dbMap = settings.toDbMap();

      if (existing.isEmpty) {
        dbMap['created_at'] = now;
        await txn.insert('app_settings', dbMap, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await txn.update(
          'app_settings',
          dbMap,
          where: 'user_id = ?',
          whereArgs: [settings.userId],
        );
      }

      // Update user currency_code
      await txn.update(
        'users',
        {'currency_code': settings.currencyCode, 'updated_at': now},
        where: 'id = ?',
        whereArgs: [settings.userId],
      );

      // Upsert financial_profile ai_memory_enabled
      final profileExisting = await txn.query(
        'financial_profile',
        where: 'user_id = ?',
        whereArgs: [settings.userId],
        limit: 1,
      );

      if (profileExisting.isEmpty) {
        await txn.insert(
          'financial_profile',
          {
            'user_id': settings.userId,
            'ai_memory_enabled': settings.aiMemoryEnabled ? 1 : 0,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } else {
        await txn.update(
          'financial_profile',
          {
            'ai_memory_enabled': settings.aiMemoryEnabled ? 1 : 0,
            'updated_at': now,
          },
          where: 'user_id = ?',
          whereArgs: [settings.userId],
        );
      }
    });
  }

  @override
  Future<void> resetSettings(int userId) async {
    final defaultSettings = AppSettings(userId: userId);
    await saveSettings(defaultSettings);
  }
}

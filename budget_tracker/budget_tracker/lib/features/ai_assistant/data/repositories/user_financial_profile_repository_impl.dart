import 'package:sqflite/sqflite.dart';

import '../../../../shared/data/database/database_helper.dart';
import '../../domain/user_financial_profile_repository.dart';

/// SQLite implementation of [UserFinancialProfileRepository].
/// Interacts directly with the encrypted `financial_profile` table on-device.
class UserFinancialProfileRepositoryImpl implements UserFinancialProfileRepository {
  final DatabaseHelper _dbHelper;

  UserFinancialProfileRepositoryImpl(this._dbHelper);

  @override
  Future<UserFinancialProfile> getProfile(int userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'financial_profile',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      final defaultProfile = UserFinancialProfile.defaultProfile(userId);
      await saveProfile(defaultProfile);
      return defaultProfile;
    }

    return UserFinancialProfile.fromDbMap(rows.first);
  }

  @override
  Future<void> saveProfile(UserFinancialProfile profile) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await db.query(
      'financial_profile',
      where: 'user_id = ?',
      whereArgs: [profile.userId],
      limit: 1,
    );

    final map = profile.toDbMap();

    if (existing.isEmpty) {
      map['created_at'] = now;
      await db.insert(
        'financial_profile',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.update(
        'financial_profile',
        map,
        where: 'user_id = ?',
        whereArgs: [profile.userId],
      );
    }
  }

  @override
  Future<void> updateTone(int userId, MayaTone tone) async {
    final profile = await getProfile(userId);
    await saveProfile(profile.copyWith(
      coachingTone: tone,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> updatePaydays(int userId, List<int> paydays) async {
    final profile = await getProfile(userId);
    await saveProfile(profile.copyWith(
      paydayDays: paydays,
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> addHabitNote(int userId, String note) async {
    final profile = await getProfile(userId);
    if (!profile.habitNotes.contains(note)) {
      await saveProfile(profile.copyWith(
        habitNotes: [...profile.habitNotes, note],
        updatedAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<void> removeHabitNote(int userId, String note) async {
    final profile = await getProfile(userId);
    await saveProfile(profile.copyWith(
      habitNotes: profile.habitNotes.where((n) => n != note).toList(),
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> clearMemory(int userId) async {
    final defaultProfile = UserFinancialProfile.defaultProfile(userId);
    await saveProfile(defaultProfile);
  }
}

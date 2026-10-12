import 'user_financial_profile.dart';
export 'user_financial_profile.dart';

/// Contract for loading and persisting personal financial memory,
/// coaching tone preferences, payday dates, and habit notes.
abstract class UserFinancialProfileRepository {
  /// Fetches the profile for [userId]. If none exists, creates and persists defaults.
  Future<UserFinancialProfile> getProfile(int userId);

  /// Persists full [profile] to SQLite database.
  Future<void> saveProfile(UserFinancialProfile profile);

  /// Updates Maya's coaching persona tone.
  Future<void> updateTone(int userId, MayaTone tone);

  /// Updates user's regular payday days of the month.
  Future<void> updatePaydays(int userId, List<int> paydays);

  /// Appends a new habit or preference note to AI memory.
  Future<void> addHabitNote(int userId, String note);

  /// Removes an existing habit note from memory.
  Future<void> removeHabitNote(int userId, String note);

  /// Clears conversational memory and resets profile to defaults.
  Future<void> clearMemory(int userId);
}

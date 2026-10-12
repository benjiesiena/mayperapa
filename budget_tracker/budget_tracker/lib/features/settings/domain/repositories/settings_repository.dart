import '../entities/app_settings.dart';

abstract class SettingsRepository {
  /// Fetches settings for a user, loading preferences, security state, and AI profile flags.
  Future<AppSettings> getSettings(int userId);

  /// Saves updated settings to database.
  Future<void> saveSettings(AppSettings settings);

  /// Resets settings to default values.
  Future<void> resetSettings(int userId);
}

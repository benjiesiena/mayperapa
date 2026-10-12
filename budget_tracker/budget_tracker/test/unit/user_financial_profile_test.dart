import 'package:flutter_test/flutter_test.dart';

import 'package:mayperapa/features/ai_assistant/domain/user_financial_profile_repository.dart';

class InMemoryFinancialProfileRepository implements UserFinancialProfileRepository {
  UserFinancialProfile? _profile;

  @override
  Future<UserFinancialProfile> getProfile(int userId) async {
    return _profile ?? UserFinancialProfile.defaultProfile(userId);
  }

  @override
  Future<void> saveProfile(UserFinancialProfile profile) async {
    _profile = profile;
  }

  @override
  Future<void> updateTone(int userId, MayaTone tone) async {
    final current = await getProfile(userId);
    _profile = current.copyWith(coachingTone: tone, updatedAt: DateTime.now());
  }

  @override
  Future<void> updatePaydays(int userId, List<int> paydays) async {
    final current = await getProfile(userId);
    _profile = current.copyWith(paydayDays: paydays, updatedAt: DateTime.now());
  }

  @override
  Future<void> addHabitNote(int userId, String note) async {
    final current = await getProfile(userId);
    if (!current.habitNotes.contains(note)) {
      _profile = current.copyWith(
        habitNotes: [...current.habitNotes, note],
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<void> removeHabitNote(int userId, String note) async {
    final current = await getProfile(userId);
    _profile = current.copyWith(
      habitNotes: current.habitNotes.where((n) => n != note).toList(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> clearMemory(int userId) async {
    _profile = UserFinancialProfile.defaultProfile(userId);
  }
}

void main() {
  group('Phase 5: UserFinancialProfile & Memory Repository Tests', () {
    test('defaultProfile provides sensible financial defaults and tone', () {
      final profile = UserFinancialProfile.defaultProfile(1);

      expect(profile.userId, 1);
      expect(profile.coachingTone, MayaTone.gentleGuide);
      expect(profile.paydayDays, [15, 30]);
      expect(profile.aiMemoryEnabled, isTrue);
      expect(profile.paydaySummary, '15th and 30th of the month');
      expect(profile.toneInstructionPrompt, contains('warm, empathetic'));
    });

    test('coaching tones provide calibrated instructions', () {
      const challenger = MayaTone.socraticChallenger;
      expect(challenger.label, 'Socratic Challenger');
      expect(challenger.instruction, contains('trade-offs'));

      const analyst = MayaTone.directAnalyst;
      expect(analyst.label, 'Direct Analyst');
      expect(analyst.instruction, contains('concise'));

      const guide = MayaTone.gentleGuide;
      expect(guide.label, 'Gentle Guide');
      expect(guide.instruction, contains('empathetic'));
    });

    test('serialization roundtrip via toDbMap and fromDbMap preserves all fields', () {
      final now = DateTime.now();
      final original = UserFinancialProfile(
        userId: 42,
        monthlyIncome: 45000.0,
        paydayDays: const [5, 20],
        coachingTone: MayaTone.socraticChallenger,
        savingsAggressiveness: 'aggressive',
        savingsTargetPercentage: 25.0,
        emergencyFundTargetMonths: 6.0,
        habitNotes: const ['Cooks at home', 'Prefers 50/30/20 formula'],
        aiMemoryEnabled: true,
        updatedAt: now,
      );

      final dbMap = original.toDbMap();
      expect(dbMap['user_id'], 42);
      expect(dbMap['monthly_income'], 45000.0);
      expect(dbMap['budget_strategy'], 'socraticChallenger');
      expect(dbMap['risk_tolerance'], 'aggressive');

      final reconstructed = UserFinancialProfile.fromDbMap(dbMap);
      expect(reconstructed.userId, original.userId);
      expect(reconstructed.monthlyIncome, original.monthlyIncome);
      expect(reconstructed.coachingTone, MayaTone.socraticChallenger);
      expect(reconstructed.paydayDays, [5, 20]);
      expect(reconstructed.savingsAggressiveness, 'aggressive');
      expect(reconstructed.habitNotes, ['Cooks at home', 'Prefers 50/30/20 formula']);
      expect(reconstructed.aiMemoryEnabled, isTrue);
    });

    test('repository updates tone, paydays, and habit notes', () async {
      final repo = InMemoryFinancialProfileRepository();

      // Initial state
      var profile = await repo.getProfile(1);
      expect(profile.coachingTone, MayaTone.gentleGuide);
      expect(profile.paydayDays, [15, 30]);

      // Update tone to Direct Analyst
      await repo.updateTone(1, MayaTone.directAnalyst);
      profile = await repo.getProfile(1);
      expect(profile.coachingTone, MayaTone.directAnalyst);

      // Update paydays to [10, 25]
      await repo.updatePaydays(1, [10, 25]);
      profile = await repo.getProfile(1);
      expect(profile.paydayDays, [10, 25]);
      expect(profile.paydaySummary, '10th and 25th of the month');

      // Add habit notes
      await repo.addHabitNote(1, 'Paid off credit card');
      profile = await repo.getProfile(1);
      expect(profile.habitNotes, contains('Paid off credit card'));

      // Remove habit note
      await repo.removeHabitNote(1, 'Paid off credit card');
      profile = await repo.getProfile(1);
      expect(profile.habitNotes, isNot(contains('Paid off credit card')));

      // Clear memory resets to default
      await repo.clearMemory(1);
      profile = await repo.getProfile(1);
      expect(profile.coachingTone, MayaTone.gentleGuide);
      expect(profile.paydayDays, [15, 30]);
      expect(profile.habitNotes, isEmpty);
    });
  });
}

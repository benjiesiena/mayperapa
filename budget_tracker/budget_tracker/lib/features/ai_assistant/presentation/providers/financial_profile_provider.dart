import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/presentation/providers/app_providers.dart';
import '../../domain/user_financial_profile_repository.dart';


class FinancialProfileNotifier extends AsyncNotifier<UserFinancialProfile> {
  @override
  Future<UserFinancialProfile> build() async {
    final repo = ref.watch(userFinancialProfileRepositoryProvider);
    final userId = ref.watch(currentUserIdProvider);
    return repo.getProfile(userId);
  }

  Future<void> updateTone(MayaTone tone) async {
    final repo = ref.read(userFinancialProfileRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await repo.updateTone(userId, tone);
    state = AsyncData(await repo.getProfile(userId));
  }

  Future<void> updatePaydays(List<int> paydays) async {
    final repo = ref.read(userFinancialProfileRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await repo.updatePaydays(userId, paydays);
    state = AsyncData(await repo.getProfile(userId));
  }

  Future<void> toggleMemory(bool enabled) async {
    final repo = ref.read(userFinancialProfileRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    final current = await repo.getProfile(userId);
    await repo.saveProfile(current.copyWith(
      aiMemoryEnabled: enabled,
      updatedAt: DateTime.now(),
    ));
    state = AsyncData(await repo.getProfile(userId));
  }

  Future<void> addHabitNote(String note) async {
    final repo = ref.read(userFinancialProfileRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await repo.addHabitNote(userId, note);
    state = AsyncData(await repo.getProfile(userId));
  }

  Future<void> removeHabitNote(String note) async {
    final repo = ref.read(userFinancialProfileRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await repo.removeHabitNote(userId, note);
    state = AsyncData(await repo.getProfile(userId));
  }

  Future<void> clearMemory() async {
    final repo = ref.read(userFinancialProfileRepositoryProvider);
    final userId = ref.read(currentUserIdProvider);
    await repo.clearMemory(userId);
    state = AsyncData(await repo.getProfile(userId));
  }
}

final financialProfileProvider =
    AsyncNotifierProvider<FinancialProfileNotifier, UserFinancialProfile>(
  FinancialProfileNotifier.new,
);

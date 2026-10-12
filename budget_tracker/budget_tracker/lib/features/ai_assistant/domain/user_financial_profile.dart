import 'dart:convert';
import 'package:equatable/equatable.dart';

/// Persona coaching tone for Maya AI Assistant.
enum MayaTone {
  gentleGuide(
    label: 'Gentle Guide',
    description: 'Warm, encouraging, and supportive. Emphasizes small wins and reduces financial anxiety.',
    instruction: 'Adopt a warm, empathetic, and encouraging demeanor. Validate financial efforts, reduce anxiety around money, celebrate positive habits, and offer gentle guidance.',
  ),
  directAnalyst(
    label: 'Direct Analyst',
    description: 'Crisp, concise, and numbers-first. Focuses on data, margins, and bottom-line math.',
    instruction: 'Adopt a concise, metric-driven, and pragmatic demeanor. Be direct, lead with numbers and percentages, minimize pleasantries, and focus squarely on the bottom line.',
  ),
  socraticChallenger(
    label: 'Socratic Challenger',
    description: 'Inquisitive and provocative. Prods on spending trade-offs and questions impulse purchases.',
    instruction: 'Adopt a Socratic, inquisitive demeanor. Ask sharp reflective questions about trade-offs, challenge impulse desires, and prompt the user to evaluate how current decisions affect long-term goals.',
  );

  final String label;
  final String description;
  final String instruction;

  const MayaTone({
    required this.label,
    required this.description,
    required this.instruction,
  });
}

/// Represents the persistent financial memory and persona profile for the user.
/// Stored locally in SQLite `financial_profile` table.
class UserFinancialProfile extends Equatable {
  final int userId;
  final double monthlyIncome;
  final List<int> paydayDays;
  final MayaTone coachingTone;
  final String savingsAggressiveness;
  final double savingsTargetPercentage;
  final double emergencyFundTargetMonths;
  final List<String> habitNotes;
  final bool aiMemoryEnabled;
  final DateTime updatedAt;

  const UserFinancialProfile({
    required this.userId,
    this.monthlyIncome = 30000.0,
    this.paydayDays = const [15, 30],
    this.coachingTone = MayaTone.gentleGuide,
    this.savingsAggressiveness = 'balanced',
    this.savingsTargetPercentage = 20.0,
    this.emergencyFundTargetMonths = 3.0,
    this.habitNotes = const [],
    this.aiMemoryEnabled = true,
    required this.updatedAt,
  });

  factory UserFinancialProfile.defaultProfile(int userId) {
    return UserFinancialProfile(
      userId: userId,
      monthlyIncome: 30000.0,
      paydayDays: const [15, 30],
      coachingTone: MayaTone.gentleGuide,
      savingsAggressiveness: 'balanced',
      savingsTargetPercentage: 20.0,
      emergencyFundTargetMonths: 3.0,
      habitNotes: const [],
      aiMemoryEnabled: true,
      updatedAt: DateTime.now(),
    );
  }

  String get paydaySummary {
    if (paydayDays.isEmpty) return 'No fixed payday set';
    if (paydayDays.length == 1) return '${_ordinal(paydayDays.first)} of the month';
    final parts = paydayDays.map(_ordinal).toList();
    if (parts.length == 2) return '${parts[0]} and ${parts[1]} of the month';
    return '${parts.sublist(0, parts.length - 1).join(", ")}, and ${parts.last} of the month';
  }

  String get toneInstructionPrompt => coachingTone.instruction;

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  UserFinancialProfile copyWith({
    int? userId,
    double? monthlyIncome,
    List<int>? paydayDays,
    MayaTone? coachingTone,
    String? savingsAggressiveness,
    double? savingsTargetPercentage,
    double? emergencyFundTargetMonths,
    List<String>? habitNotes,
    bool? aiMemoryEnabled,
    DateTime? updatedAt,
  }) {
    return UserFinancialProfile(
      userId: userId ?? this.userId,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      paydayDays: paydayDays ?? this.paydayDays,
      coachingTone: coachingTone ?? this.coachingTone,
      savingsAggressiveness: savingsAggressiveness ?? this.savingsAggressiveness,
      savingsTargetPercentage: savingsTargetPercentage ?? this.savingsTargetPercentage,
      emergencyFundTargetMonths: emergencyFundTargetMonths ?? this.emergencyFundTargetMonths,
      habitNotes: habitNotes ?? this.habitNotes,
      aiMemoryEnabled: aiMemoryEnabled ?? this.aiMemoryEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'user_id': userId,
      'monthly_income': monthlyIncome,
      'budget_strategy': coachingTone.name,
      'savings_target_percentage': savingsTargetPercentage,
      'emergency_fund_target_months': emergencyFundTargetMonths,
      'risk_tolerance': savingsAggressiveness,
      'financial_goals_summary': jsonEncode(habitNotes),
      'recurring_expenses_summary': jsonEncode({'paydayDays': paydayDays}),
      'ai_memory_enabled': aiMemoryEnabled ? 1 : 0,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory UserFinancialProfile.fromDbMap(Map<String, dynamic> map) {
    final toneName = map['budget_strategy'] as String? ?? 'gentleGuide';
    final tone = MayaTone.values.firstWhere(
      (t) => t.name == toneName,
      orElse: () => MayaTone.gentleGuide,
    );

    List<int> paydays = const [15, 30];
    final recurringJson = map['recurring_expenses_summary'] as String?;
    if (recurringJson != null && recurringJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(recurringJson) as Map<String, dynamic>;
        final rawDays = decoded['paydayDays'] as List?;
        if (rawDays != null) {
          paydays = rawDays.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {}
    }

    List<String> habits = const [];
    final goalsJson = map['financial_goals_summary'] as String?;
    if (goalsJson != null && goalsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(goalsJson) as List?;
        if (decoded != null) {
          habits = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    final rawUpdatedAt = map['updated_at'];
    final updated = rawUpdatedAt is int
        ? DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt)
        : DateTime.now();

    return UserFinancialProfile(
      userId: map['user_id'] as int? ?? 1,
      monthlyIncome: (map['monthly_income'] as num?)?.toDouble() ?? 30000.0,
      paydayDays: paydays,
      coachingTone: tone,
      savingsAggressiveness: map['risk_tolerance'] as String? ?? 'balanced',
      savingsTargetPercentage: (map['savings_target_percentage'] as num?)?.toDouble() ?? 20.0,
      emergencyFundTargetMonths:
          (map['emergency_fund_target_months'] as num?)?.toDouble() ?? 3.0,
      habitNotes: habits,
      aiMemoryEnabled: (map['ai_memory_enabled'] as int? ?? 1) == 1,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'monthlyIncome': monthlyIncome,
        'paydayDays': paydayDays,
        'paydaySummary': paydaySummary,
        'coachingTone': coachingTone.name,
        'coachingToneLabel': coachingTone.label,
        'toneInstruction': coachingTone.instruction,
        'savingsAggressiveness': savingsAggressiveness,
        'savingsTargetPercentage': savingsTargetPercentage,
        'emergencyFundTargetMonths': emergencyFundTargetMonths,
        'habitNotes': habitNotes,
        'aiMemoryEnabled': aiMemoryEnabled,
      };

  @override
  List<Object?> get props => [
        userId,
        monthlyIncome,
        paydayDays,
        coachingTone,
        savingsAggressiveness,
        savingsTargetPercentage,
        emergencyFundTargetMonths,
        habitNotes,
        aiMemoryEnabled,
      ];
}

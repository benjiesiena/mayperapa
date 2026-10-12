import "package:equatable/equatable.dart";
import "enums.dart";

class Account extends Equatable {
  final int? id;
  final int userId;
  final String name;
  final AccountType type;
  final double balance;
  final String currencyCode;
  final bool isActive;
  final String? icon;
  final String? color;
  final String? institutionName;
  final String? accountNumberMasked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Account({
    this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0,
    required this.currencyCode,
    this.isActive = true,
    this.icon,
    this.color,
    this.institutionName,
    this.accountNumberMasked,
    required this.createdAt,
    required this.updatedAt,
  });

  Account copyWith({
    int? id,
    int? userId,
    String? name,
    AccountType? type,
    double? balance,
    String? currencyCode,
    bool? isActive,
    String? icon,
    String? color,
    String? institutionName,
    String? accountNumberMasked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      institutionName: institutionName ?? this.institutionName,
      accountNumberMasked: accountNumberMasked ?? this.accountNumberMasked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        type,
        balance,
        currencyCode,
        isActive,
        icon,
        color,
        institutionName,
        accountNumberMasked,
      ];

  /// Default accounts seeded for every new user on first launch.
  static List<Map<String, Object?>> defaults({String currencyCode = "PHP"}) => [
        {
          "name": "Cash",
          "type": AccountType.cash.dbValue,
          "balance": 0.0,
          "currency_code": currencyCode,
          "icon": "account_balance_wallet",
          "color": "#10B981",
        },
        {
          "name": "Main Bank",
          "type": AccountType.bank.dbValue,
          "balance": 0.0,
          "currency_code": currencyCode,
          "icon": "account_balance",
          "color": "#3B82F6",
        },
        {
          "name": "Savings",
          "type": AccountType.bank.dbValue,
          "balance": 0.0,
          "currency_code": currencyCode,
          "icon": "savings",
          "color": "#8B5CF6",
        },
      ];
}

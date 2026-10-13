import 'package:equatable/equatable.dart';

/// Immutable state representing the application lock gate.
class AppLockState extends Equatable {
  final bool isLocked;
  final bool isAuthenticating;
  final String pinInput;
  final String? errorMessage;
  final int shakeKey;
  final bool canUseBiometrics;
  final int pinLength;

  const AppLockState({
    required this.isLocked,
    this.isAuthenticating = false,
    this.pinInput = '',
    this.errorMessage,
    this.shakeKey = 0,
    this.canUseBiometrics = false,
    this.pinLength = 4,
  });

  AppLockState copyWith({
    bool? isLocked,
    bool? isAuthenticating,
    String? pinInput,
    String? errorMessage,
    bool clearError = false,
    int? shakeKey,
    bool? canUseBiometrics,
    int? pinLength,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      pinInput: pinInput ?? this.pinInput,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      shakeKey: shakeKey ?? this.shakeKey,
      canUseBiometrics: canUseBiometrics ?? this.canUseBiometrics,
      pinLength: pinLength ?? this.pinLength,
    );
  }

  @override
  List<Object?> get props => [
        isLocked,
        isAuthenticating,
        pinInput,
        errorMessage,
        shakeKey,
        canUseBiometrics,
        pinLength,
      ];
}

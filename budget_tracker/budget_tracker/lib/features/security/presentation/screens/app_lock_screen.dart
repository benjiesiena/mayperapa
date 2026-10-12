import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/app_buttons.dart';
import '../../domain/entities/app_lock_state.dart';
import '../providers/app_lock_provider.dart';

/// Full-screen App Lock Gate with numeric keypad, animated PIN dots,
/// haptic feedback, and biometric integration.
class AppLockScreen extends ConsumerStatefulWidget {
  const AppLockScreen({super.key});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  int _lastShakeKey = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Auto-prompt biometrics if enabled after screen mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lockState = ref.read(appLockProvider);
      if (lockState.canUseBiometrics && lockState.isLocked) {
        ref.read(appLockProvider.notifier).authenticateWithBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    HapticFeedback.lightImpact();
    final notifier = ref.read(appLockProvider.notifier);
    notifier.appendPinDigit(digit);

    final currentPin = ref.read(appLockProvider).pinInput;
    // Auto-verify if 4 digits are reached (common PIN length)
    if (currentPin.length >= 4) {
      notifier.submitPin();
    }
  }

  void _onDeletePressed() {
    HapticFeedback.selectionClick();
    ref.read(appLockProvider.notifier).deletePinDigit();
  }

  void _onBiometricsPressed() {
    HapticFeedback.mediumImpact();
    ref.read(appLockProvider.notifier).authenticateWithBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);
    final palette = context.appColors;

    // Trigger shake animation when error occurs
    if (lockState.shakeKey != _lastShakeKey) {
      _lastShakeKey = lockState.shakeKey;
      _shakeController.forward(from: 0.0);
    }

    return PopScope(
      canPop: false, // Prevent back navigation while locked
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Header Branding
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: palette.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.primary.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Icon(Icons.lock_rounded, size: 30, color: palette.primary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'MayPeraPa',
                    style: AppTypography.pageTitle.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Enter your PIN to unlock',
                    style: AppTypography.body.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // PIN Dots with Shake Animation
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final offset = math.sin(_shakeController.value * math.pi * 4) *
                          (1.0 - _shakeController.value) *
                          14;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: _buildPinDots(lockState.pinInput.length, palette),
                  ),

                  // Error Message
                  SizedBox(
                    height: 28,
                    child: Center(
                      child: lockState.errorMessage != null
                          ? Text(
                              lockState.errorMessage!,
                              style: AppTypography.caption.copyWith(
                                color: palette.negative,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : (lockState.isAuthenticating
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: palette.primary,
                                  ),
                                )
                              : null),
                    ),
                  ),
                ],
              ),

              // Keypad
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _buildKeypad(context, lockState, palette),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots(int filledCount, AppColorPalette palette) {
    const totalDots = 4;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        final isFilled = index < filledCount;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: isFilled ? 16 : 14,
          height: isFilled ? 16 : 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? palette.primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? palette.primary : palette.textTertiary,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(
    BuildContext context,
    AppLockState lockState,
    AppColorPalette palette,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          _keypadRow(['1', '2', '3'], palette),
          const SizedBox(height: AppSpacing.md),
          _keypadRow(['4', '5', '6'], palette),
          const SizedBox(height: AppSpacing.md),
          _keypadRow(['7', '8', '9'], palette),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Biometrics or blank
              if (lockState.canUseBiometrics)
                _iconKey(
                  icon: Icons.fingerprint_rounded,
                  palette: palette,
                  onTap: _onBiometricsPressed,
                )
              else
                const SizedBox(width: 68, height: 68),

              // Zero
              _numberKey('0', palette),

              // Backspace
              _iconKey(
                icon: Icons.backspace_outlined,
                palette: palette,
                onTap: _onDeletePressed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _keypadRow(List<String> digits, AppColorPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _numberKey(d, palette)).toList(),
    );
  }

  Widget _numberKey(String digit, AppColorPalette palette) {
    return TactileBounce(
      onTap: () => _onDigitPressed(digit),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surfaceVariant.withValues(alpha: 0.6),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: AppTypography.pageTitle.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _iconKey({
    required IconData icon,
    required AppColorPalette palette,
    required VoidCallback onTap,
  }) {
    return TactileBounce(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        alignment: Alignment.center,
        child: Icon(icon, size: 28, color: palette.textSecondary),
      ),
    );
  }
}

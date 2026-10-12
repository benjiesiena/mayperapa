import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

/// Tactile bounce wrapper implementing Emil Kowalski interaction physics:
/// scales down to 0.97 on press with custom cubic-bezier easing and instant feedback.
class TactileBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;

  const TactileBounce({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.97,
  });

  @override
  State<TactileBounce> createState() => _TactileBounceState();
}

class _TactileBounceState extends State<TactileBounce> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) setState(() => _isPressed = true);
  }

  void _onTapUp(TapUpDetails _) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: AppDurations.quick,
        curve: AppCurves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TactileBounce(
        onTap: isLoading ? null : onPressed,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : (icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    )
                  : Text(label, overflow: TextOverflow.ellipsis, maxLines: 1)),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TactileBounce(
        onTap: onPressed,
        child: OutlinedButton(
          onPressed: onPressed,
          child: icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                )
              : Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'app_buttons.dart';

/// Persistent floating copilot capsule providing 1-tap reachability to Maya
/// from any primary view without switching bottom navigation tabs manually.
class MayaFloatingCapsule extends StatelessWidget {
  final VoidCallback onTap;

  const MayaFloatingCapsule({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appColors;

    return Semantics(
      button: true,
      label: 'Ask Maya AI Assistant',
      child: Tooltip(
        message: 'Ask Maya',
        child: TactileBounce(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: palette.primary,
              borderRadius: BorderRadius.circular(AppRadius.full),
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  'Ask Maya',
                  style: AppTypography.button.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

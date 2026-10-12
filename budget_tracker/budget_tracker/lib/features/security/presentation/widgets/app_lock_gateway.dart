import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_lock_provider.dart';
import '../screens/app_lock_screen.dart';

/// Wraps the application to enforce the App Lock security boundary and
/// monitor lifecycle events (app paused, inactive, background timeout, resumed).
class AppLockGateway extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockGateway({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLockGateway> createState() => _AppLockGatewayState();
}

class _AppLockGatewayState extends ConsumerState<AppLockGateway>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final notifier = ref.read(appLockProvider.notifier);

    switch (state) {
      case AppLifecycleState.paused:
        notifier.onAppPaused();
        break;
      case AppLifecycleState.resumed:
        notifier.onAppResumed();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: lockState.isLocked
          ? const AppLockScreen(key: ValueKey('app_lock_screen'))
          : KeyedSubtree(
              key: const ValueKey('app_unlocked_content'),
              child: widget.child,
            ),
    );
  }
}

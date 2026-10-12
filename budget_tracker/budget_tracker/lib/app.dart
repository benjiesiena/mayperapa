import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_provider.dart';
import 'features/security/presentation/widgets/app_lock_gateway.dart';
import 'app_shell.dart';

class BudgetTrackerApp extends ConsumerWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final themeMode = settingsAsync.maybeWhen(
      data: (settings) => settings.themeMode,
      orElse: () => ThemeMode.system,
    );

    return MaterialApp(
      title: 'MayPeraPa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const AppLockGateway(child: AppShell()),
    );
  }
}

/// Backward-compatible alias for the MayPeraPa root widget.
typedef MayPeraPaApp = BudgetTrackerApp;

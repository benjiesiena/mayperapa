import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/transactions/presentation/screens/transaction_list_screen.dart';
import '../../features/budgets/presentation/screens/budget_overview_screen.dart';
import '../../features/goals/presentation/screens/goals_list_screen.dart';
import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/notifications/presentation/notifications_provider.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../shared/presentation/widgets/maya_floating_capsule.dart';

/// Root navigation shell (PRD 10.1): Home / Transactions / Budget / Goals /
/// AI, all reachable from a persistent bottom bar. Uses IndexedStack so
/// each tab keeps its scroll position and provider state when switching.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _goToAssistant() => setState(() => _index = 4);

  void _goToSettings() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

  @override
  Widget build(BuildContext context) {
    // Passively maintain notification thresholds and bill reminders
    ref.watch(notificationCoordinatorProvider);

    final onboardingAsync = ref.watch(onboardingCompletedProvider);

    return onboardingAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => _buildMainShell(context),
      data: (hasCompleted) {
        if (!hasCompleted) {
          return OnboardingScreen(
            onFinished: () => ref.invalidate(onboardingCompletedProvider),
          );
        }
        return _buildMainShell(context);
      },
    );
  }

  Widget _buildMainShell(BuildContext context) {
    final screens = [
      HomeScreen(onOpenAssistant: _goToAssistant, onOpenSettings: _goToSettings),
      const TransactionListScreen(),
      const BudgetOverviewScreen(),
      const GoalsListScreen(),
      const AIAssistantScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      floatingActionButton: _index == 4 ? null : MayaFloatingCapsule(onTap: _goToAssistant),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Budget',
          ),
          NavigationDestination(icon: Icon(Icons.flag_outlined), selectedIcon: Icon(Icons.flag), label: 'Goals'),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
        ],
      ),
    );
  }
}

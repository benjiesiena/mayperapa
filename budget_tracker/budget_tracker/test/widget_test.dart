import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mayperapa/app.dart';

void main() {
  testWidgets('App shell renders navigation destinations smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'mayperapa_onboarding_completed': true});

    await tester.pumpWidget(
      const ProviderScope(
        child: BudgetTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify root navigation destinations exist in AppShell
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Budget'), findsWidgets);
    expect(find.text('Goals'), findsWidgets);
    expect(find.text('AI'), findsWidgets);
  });
}

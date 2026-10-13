import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mayperapa/core/theme/app_theme.dart';
import 'package:mayperapa/features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import 'package:mayperapa/shared/presentation/providers/app_providers.dart';

void main() {
  testWidgets('AIAssistantScreen and _ModelManagerSheet mode switching test', (WidgetTester tester) async {
    // Set screen size
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const AIAssistantScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify screen renders initial UI and banner
    expect(find.text('Maya — AI Assistant'), findsOneWidget);
    expect(find.text('Change Mode'), findsOneWidget);
    expect(find.text('Mode'), findsOneWidget);

    // 2. Tap "Change Mode" to open the bottom sheet
    await tester.tap(find.text('Change Mode'));
    await tester.pumpAndSettle();

    // 3. Verify bottom sheet items are rendered
    expect(find.text('Maya AI Engine'), findsOneWidget);
    expect(find.text('Instant Offline Coach'), findsOneWidget);
    expect(find.text('Cloud Advisor (Gemini Flash)'), findsOneWidget);
    expect(find.text('Lightweight On-Device LLM'), findsOneWidget);

    // 4. Tap "Cloud Advisor" mode
    await tester.tap(find.text('🌐 Cloud Advisor (Gemini Flash)'));
    await tester.pumpAndSettle();

    // Verify Cloud Advisor is selected
    expect(container.read(aiEngineModeProvider), AIEngineMode.cloudAdvisor);

    // Verify API Key section is visible without throwing BoxConstraints error
    expect(find.text('Google Gemini API Key'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Enter an API key and tap Save
    final textField = find.byType(TextField).last;
    await tester.enterText(textField, 'test-gemini-key-123');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(container.read(geminiApiKeyProvider), 'test-gemini-key-123');

    // 5. Tap "Instant Offline Coach" mode
    await tester.tap(find.text('⚡ Instant Offline Coach'));
    await tester.pumpAndSettle();

    expect(container.read(aiEngineModeProvider), AIEngineMode.instantOffline);
    // API key section should not be in the tree
    expect(find.text('Google Gemini API Key'), findsNothing);

    // 6. Tap "Lightweight On-Device LLM" mode
    await tester.tap(find.text('🧠 Lightweight On-Device LLM'));
    await tester.pumpAndSettle();

    expect(container.read(aiEngineModeProvider), AIEngineMode.localNeural);
    expect(find.text('Model: Qwen 2.5 0.5B Instruct (Q4_K_M)'), findsOneWidget);

    // 7. Close the sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Bottom sheet is closed, main screen reflects new mode
    expect(find.text('Maya AI Engine'), findsNothing);
    expect(find.text('Change Mode'), findsOneWidget);
  });
}

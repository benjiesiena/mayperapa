@Tags(['live'])
library;
import 'package:flutter_test/flutter_test.dart';
import 'package:mayperapa/infrastructure/ai/runtime/cloud_ai_engine.dart';
import 'package:mayperapa/infrastructure/ai/runtime/ai_config.dart';

void main() {
  group('CloudAIEngine Live Test', () {
    final hasKey = AIConfig.defaultGeminiApiKey.trim().isNotEmpty;

    test('generateResponse returns real Gemini output with user API key',
        timeout: const Timeout(Duration(minutes: 2)),
        skip: hasKey ? null : 'No GEMINI_API_KEY configured for live cloud tests', () async {
      final engine = CloudAIEngine(
        apiKey: AIConfig.defaultGeminiApiKey,
      );

      expect(await engine.isReady, isTrue);

      final response = await engine.generateResponse(
        userMessage: 'What is the 50/30/20 rule?',
        toolResults: {},
        conversationHistory: [],
      );

      expect(response, isNotEmpty);
      expect(response.toLowerCase().contains('50') || response.toLowerCase().contains('budget') || response.toLowerCase().contains('needs'), isTrue);
    });

    test('generateResponse includes financial context when tool results are present',
        timeout: const Timeout(Duration(minutes: 2)),
        skip: hasKey ? null : 'No GEMINI_API_KEY configured for live cloud tests', () async {
      final engine = CloudAIEngine(
        apiKey: AIConfig.defaultGeminiApiKey,
      );

      final response = await engine.generateResponse(
        userMessage: 'How is my budget this month?',
        toolResults: {
          'get_budget_status': {
            'budget_name': 'October 2026',
            'spent': 1000.0,
            'total_budget': 1500.0,
            'percent_used': 66.7,
            'remaining': 500.0,
          }
        },
        conversationHistory: [],
      );

      expect(response, isNotEmpty);
      expect(response.contains('1,000') || response.contains('1000') || response.contains('500') || response.contains('October'), isTrue);
    });
  });
}

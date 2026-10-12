class ValidationResult {
  final bool isValid;
  final String? error;
  const ValidationResult._(this.isValid, this.error);
  const ValidationResult.valid() : this._(true, null);
  const ValidationResult.error(String message) : this._(false, message);
}

/// Second line of defense against hallucinated numbers, per PRD 6.5.
///
/// [RuleBasedAIEngine]'s templates already only interpolate values pulled
/// from tool results, so in this scaffold the validator's main job is
/// catching genuinely unexpected output (e.g. a future response-generation
/// backend, or a real LLM, drifting from the tool data) rather than fixing
/// bugs in the template engine itself. It flags:
///   - currency-looking numbers in the response that don't appear anywhere
///     in the tool results (possible fabrication)
///   - responses produced when zero tools were called for a question that
///     clearly needed financial data
class AIResponseValidator {
  const AIResponseValidator();

  ValidationResult validate({
    required String response,
    required Map<String, Map<String, dynamic>> toolResults,
    required bool questionNeedsData,
  }) {
    final sanitizedResponse = _sanitizeTextForValidation(response);
    final numbersInResponse = _extractNumbers(sanitizedResponse);
    final numbersInToolResults = _extractNumbersFromResults(toolResults);
    final derivedPercentages = numbersInToolResults.map((v) => v * 100).toList();

    // 1. If the question explicitly asked for data and tool results are empty:
    // If the model honestly reports no data without fabricating numbers, that is valid.
    // But if it asserts fabricated figures, or claims data when none exists, flag it.
    if (questionNeedsData && toolResults.isEmpty && numbersInResponse.any((n) => n.abs() >= 100)) {
      return const ValidationResult.error('Response answers a data question with fabricated numbers and no tool results backing it.');
    }

    // 2. Strict grounding: Any figures >= 100 in the response must match verified tool figures.
    for (final n in numbersInResponse) {
      // Small numbers (percentages, counts, days) are allowed without an exact tool match
      if (n.abs() < 100) continue;
      final matchesRawValue = numbersInToolResults.any((t) => (t.abs() - n.abs()).abs() < 1.0);
      final matchesPercentage = derivedPercentages.any((t) => (t.abs() - n.abs()).abs() < 1.0);
      if (!matchesRawValue && !matchesPercentage) {
        return ValidationResult.error('Response contains a figure ($n) not found in any tool result.');
      }
    }

    return const ValidationResult.valid();
  }

  String _sanitizeTextForValidation(String text) {
    var clean = text;

    // 1. Strip suggestion / advice sections where illustrative numbers and examples reside
    clean = clean.replaceAll(RegExp(r'\*\*(?:Proactive\s+)?Suggestion:\*\*.*?(?:\n\n|$)', caseSensitive: false, dotAll: true), ' ');
    clean = clean.replaceAll(RegExp(r'\*\*Next Step:\*\*.*?(?:\n\n|$)', caseSensitive: false, dotAll: true), ' ');
    clean = clean.replaceAll(RegExp(r'\*\*Action:\*\*.*?(?:\n\n|$)', caseSensitive: false, dotAll: true), ' ');
    clean = clean.replaceAll(RegExp(r'\*\*Your Call:\*\*.*?(?:\n\n|$)', caseSensitive: false, dotAll: true), ' ');

    // 2. Strip illustrative quoted commands/prompts e.g. *"Set food budget to ₱6,000"*, 'Can I afford ₱2,000?'
    // Note: Do not mix single and double quotes, and do not match contractions (e.g. You've, don't, it's).
    clean = clean.replaceAll(RegExp(r'(?:\*|")[\u201C"]?[^"\u201D\r\n]+["\u201D](\*)?'), ' ');
    clean = clean.replaceAll(RegExp(r"(?:^|\s)\*?'[^'\r\n]+'\*?(?:\s|$|[.,!?])"), ' ');

    return clean;
  }

  List<double> _extractNumbers(String text) {
    final clean = text.replaceAll(',', '');
    final regex = RegExp(
      r'(?<prefix>[₱$€£]|PHP\s*|Php\s*|USD\s*)?(?<number>\d+(?:\.\d+)?)(?<suffix>\s*(?:%|days?|months?|weeks?|years?|hours?|hrs?|mins?|minutes?|seconds?|pesos?|PHP))?',
      caseSensitive: false,
    );

    final numbers = <double>[];
    for (final match in regex.allMatches(clean)) {
      final numStr = match.namedGroup('number');
      if (numStr == null) continue;
      final val = double.tryParse(numStr);
      if (val == null) continue;

      final prefix = match.namedGroup('prefix')?.trim() ?? '';
      final suffix = match.namedGroup('suffix')?.trim().toLowerCase() ?? '';

      // Ignore non-currency numbers associated with time durations (e.g. 180 days, 12 months)
      if (suffix.startsWith('day') ||
          suffix.startsWith('month') ||
          suffix.startsWith('week') ||
          suffix.startsWith('year') ||
          suffix.startsWith('hour') ||
          suffix.startsWith('hr') ||
          suffix.startsWith('min') ||
          suffix.startsWith('sec')) {
        continue;
      }

      // Ignore 4-digit calendar years without currency prefix (e.g. 1900..2099)
      if (prefix.isEmpty && val >= 1900 && val <= 2099 && val == val.roundToDouble() && !suffix.contains('peso')) {
        continue;
      }

      numbers.add(val);
    }
    return numbers;
  }

  List<double> _extractNumbersFromResults(Map<String, Map<String, dynamic>> results) {
    final numbers = <double>[];
    void walk(dynamic value) {
      if (value is num) numbers.add(value.toDouble());
      if (value is Map) value.values.forEach(walk);
      if (value is List) value.forEach(walk);
    }

    results.values.forEach(walk);
    return numbers;
  }
}

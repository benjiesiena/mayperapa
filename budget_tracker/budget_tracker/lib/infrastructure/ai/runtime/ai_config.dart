/// Configuration for AI engine selection and model parameters.
class AIConfig {
  /// When true, attempts to use the on-device Local LLM (Llama 3.2 1B).
  /// By default, false to ensure instantaneous sub-50ms responses via RuleBasedAIEngine.
  static const bool useLocalLLM = false;

  /// Model file name (Lightweight Qwen 2.5 0.5B Instruct Q4_K_M GGUF, ~390MB)
  static const String modelFileName = 'qwen2.5-0.5b-instruct-q4_k_m.gguf';

  /// Optional default Google Gemini API key.
  /// Set to empty by default. Can be supplied via --dart-define=GEMINI_API_KEY=your_key
  /// or entered directly by the user in the app's AI Settings sheet.
  /// Get a free key with zero credit card at: https://aistudio.google.com/
  static const String defaultGeminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  /// Context window size for model inference (tokens)
  static const int contextSize = 2048;

  /// CPU inference threads
  static const int nThreads = 4;

  /// Sampling temperature (0.0 - 1.0)
  /// Grounded to 0.1 to eliminate hallucinations on financial figures
  static const double temp = 0.1;

  /// Top-k sampling (constrained for factual grounding)
  static const int topK = 10;

  /// Top-p sampling (constrained for factual grounding)
  static const double topP = 0.7;

  /// GPU layers to offload (0 = CPU only)
  static const int nGpuLayers = 0;
}
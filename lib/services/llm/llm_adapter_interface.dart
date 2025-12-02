import '../../models/llm_config.dart';

/// Interfaccia base per tutti gli adapter LLM
abstract class LLMAdapterInterface {
  /// ID del provider
  String get providerId;

  /// Nome visualizzato del provider
  String get providerName;

  /// Massimo numero di token nel contesto
  int get maxContextTokens;

  /// Supporta ragionamento multi-step
  bool get supportsReasoning;

  /// Supporta streaming delle risposte
  bool get supportsStreaming;

  /// Lista dei modelli disponibili
  List<String> get availableModels;

  /// Inizializza l'adapter con la configurazione
  Future<void> initialize(LLMConfig config);

  /// Genera una risposta completa
  Future<LLMResponse> complete(LLMRequest request);

  /// Genera una risposta in streaming
  Stream<String> streamComplete(LLMRequest request);

  /// Valida la API key
  Future<bool> validateApiKey(String apiKey);

  /// Stima il numero di token nel testo
  Future<int> estimateTokens(String text);

  /// Rilascia le risorse
  Future<void> dispose();
}

/// Factory per creare adapter LLM
class LLMAdapterFactory {
  /// Crea un adapter in base al provider
  static LLMAdapterInterface create(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.openai:
        // Import dinamico per evitare dipendenze circolari
        throw UnimplementedError('OpenAI adapter - usa OpenAIAdapter()');
      case LLMProvider.anthropic:
        throw UnimplementedError('Anthropic adapter - usa AnthropicAdapter()');
      case LLMProvider.perplexity:
        throw UnimplementedError('Perplexity adapter - usa PerplexityAdapter()');
      case LLMProvider.ollama:
      case LLMProvider.lmstudio:
      case LLMProvider.llamacpp:
        throw UnimplementedError('Local adapter - usa LocalAdapter()');
    }
  }

  /// Informazioni sui provider disponibili
  static List<ProviderInfo> getAvailableProviders() {
    return [
      ProviderInfo(
        id: 'openai',
        name: 'OpenAI',
        description: 'GPT-4, GPT-3.5-turbo e altri modelli OpenAI',
        requiresApiKey: true,
        icon: '🤖',
      ),
      ProviderInfo(
        id: 'anthropic',
        name: 'Anthropic',
        description: 'Claude 3 Opus, Sonnet e Haiku',
        requiresApiKey: true,
        icon: '🧠',
      ),
      ProviderInfo(
        id: 'perplexity',
        name: 'Perplexity',
        description: 'Modelli Llama ottimizzati per ricerca',
        requiresApiKey: true,
        icon: '🔍',
      ),
      ProviderInfo(
        id: 'ollama',
        name: 'Ollama (Local)',
        description: 'Esegui modelli localmente con Ollama',
        requiresApiKey: false,
        icon: '🏠',
      ),
      ProviderInfo(
        id: 'lmstudio',
        name: 'LM Studio',
        description: 'Interfaccia GUI per modelli locali',
        requiresApiKey: false,
        icon: '💻',
      ),
      ProviderInfo(
        id: 'llamacpp',
        name: 'llama.cpp',
        description: 'Server llama.cpp per inferenza locale',
        requiresApiKey: false,
        icon: '🦙',
      ),
    ];
  }
}

/// Informazioni su un provider
class ProviderInfo {
  final String id;
  final String name;
  final String description;
  final bool requiresApiKey;
  final String icon;

  const ProviderInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.requiresApiKey,
    this.icon = '🤖',
  });
}

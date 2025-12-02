import 'package:equatable/equatable.dart';

/// Provider LLM supportati
enum LLMProvider {
  openai,
  anthropic,
  perplexity,
  ollama,
  lmstudio,
  llamacpp,
}

/// Estensione per LLMProvider
extension LLMProviderExtension on LLMProvider {
  String get displayName {
    switch (this) {
      case LLMProvider.openai:
        return 'OpenAI';
      case LLMProvider.anthropic:
        return 'Anthropic';
      case LLMProvider.perplexity:
        return 'Perplexity';
      case LLMProvider.ollama:
        return 'Ollama (Local)';
      case LLMProvider.lmstudio:
        return 'LM Studio';
      case LLMProvider.llamacpp:
        return 'llama.cpp';
    }
  }

  String get defaultEndpoint {
    switch (this) {
      case LLMProvider.openai:
        return 'https://api.openai.com/v1/chat/completions';
      case LLMProvider.anthropic:
        return 'https://api.anthropic.com/v1/messages';
      case LLMProvider.perplexity:
        return 'https://api.perplexity.ai/chat/completions';
      case LLMProvider.ollama:
        return 'http://localhost:11434/api/generate';
      case LLMProvider.lmstudio:
        return 'http://localhost:1234/v1/chat/completions';
      case LLMProvider.llamacpp:
        return 'http://localhost:8080/completion';
    }
  }

  bool get requiresApiKey {
    switch (this) {
      case LLMProvider.openai:
      case LLMProvider.anthropic:
      case LLMProvider.perplexity:
        return true;
      case LLMProvider.ollama:
      case LLMProvider.lmstudio:
      case LLMProvider.llamacpp:
        return false;
    }
  }

  List<String> get defaultModels {
    switch (this) {
      case LLMProvider.openai:
        return ['gpt-4o', 'gpt-4-turbo', 'gpt-4', 'gpt-3.5-turbo'];
      case LLMProvider.anthropic:
        return ['claude-3-opus-20240229', 'claude-3-sonnet-20240229', 'claude-3-haiku-20240307'];
      case LLMProvider.perplexity:
        return ['sonar-pro', 'sonar', 'sonar-reasoning-pro', 'sonar-reasoning'];
      case LLMProvider.ollama:
        return ['llama3', 'llama2', 'codellama', 'mistral', 'mixtral'];
      case LLMProvider.lmstudio:
        return ['local-model'];
      case LLMProvider.llamacpp:
        return ['local-model'];
    }
  }

  int get maxContextTokens {
    switch (this) {
      case LLMProvider.openai:
        return 128000; // gpt-4-turbo
      case LLMProvider.anthropic:
        return 200000; // claude-3
      case LLMProvider.perplexity:
        return 128000;
      case LLMProvider.ollama:
        return 32000;
      case LLMProvider.lmstudio:
        return 32000;
      case LLMProvider.llamacpp:
        return 32000;
    }
  }

  bool get supportsReasoning {
    switch (this) {
      case LLMProvider.openai:
      case LLMProvider.anthropic:
      case LLMProvider.perplexity:
        return true;
      case LLMProvider.ollama:
      case LLMProvider.lmstudio:
      case LLMProvider.llamacpp:
        return false; // dipende dal modello
    }
  }

  bool get supportsStreaming {
    return true; // tutti supportano streaming
  }
}

/// Configurazione LLM
class LLMConfig extends Equatable {
  final LLMProvider provider;
  final String? apiKey;
  final String model;
  final String? endpoint;
  final double temperature;
  final int maxTokens;
  final bool enableReasoning;
  final bool enableStreaming;

  const LLMConfig({
    required this.provider,
    this.apiKey,
    required this.model,
    this.endpoint,
    this.temperature = 0.3,
    this.maxTokens = 4096,
    this.enableReasoning = false,
    this.enableStreaming = true,
  });

  /// Endpoint effettivo (usa default se endpoint è null o vuoto)
  String get effectiveEndpoint {
    if (endpoint == null || endpoint!.isEmpty) {
      return provider.defaultEndpoint;
    }
    return endpoint!;
  }

  /// Crea una copia con valori modificati
  LLMConfig copyWith({
    LLMProvider? provider,
    String? apiKey,
    String? model,
    String? endpoint,
    double? temperature,
    int? maxTokens,
    bool? enableReasoning,
    bool? enableStreaming,
  }) {
    return LLMConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      endpoint: endpoint ?? this.endpoint,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      enableReasoning: enableReasoning ?? this.enableReasoning,
      enableStreaming: enableStreaming ?? this.enableStreaming,
    );
  }

  /// Converte in Map per JSON (senza API key)
  Map<String, dynamic> toJson() {
    return {
      'provider': provider.name,
      'model': model,
      if (endpoint != null) 'endpoint': endpoint,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'enableReasoning': enableReasoning,
      'enableStreaming': enableStreaming,
    };
  }

  /// Crea da Map JSON
  factory LLMConfig.fromJson(Map<String, dynamic> json) {
    return LLMConfig(
      provider: LLMProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => LLMProvider.openai,
      ),
      model: json['model'] as String,
      endpoint: json['endpoint'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.3,
      maxTokens: json['maxTokens'] as int? ?? 4096,
      enableReasoning: json['enableReasoning'] as bool? ?? false,
      enableStreaming: json['enableStreaming'] as bool? ?? true,
    );
  }

  /// Configurazione default OpenAI
  factory LLMConfig.defaultOpenAI() {
    return const LLMConfig(
      provider: LLMProvider.openai,
      model: 'gpt-4o',
    );
  }

  /// Configurazione default Anthropic
  factory LLMConfig.defaultAnthropic() {
    return const LLMConfig(
      provider: LLMProvider.anthropic,
      model: 'claude-3-sonnet-20240229',
    );
  }

  /// Configurazione default Ollama
  factory LLMConfig.defaultOllama() {
    return const LLMConfig(
      provider: LLMProvider.ollama,
      model: 'llama3',
    );
  }

  @override
  List<Object?> get props => [
        provider,
        apiKey,
        model,
        endpoint,
        temperature,
        maxTokens,
        enableReasoning,
        enableStreaming,
      ];
}

/// Richiesta LLM
class LLMRequest {
  final String systemPrompt;
  final String userPrompt;
  final List<Map<String, String>>? conversationHistory;
  final LLMConfig config;

  const LLMRequest({
    required this.systemPrompt,
    required this.userPrompt,
    this.conversationHistory,
    required this.config,
  });
}

/// Risposta LLM
class LLMResponse {
  final String content;
  final int promptTokens;
  final int completionTokens;
  final String? finishReason;
  final Duration? latency;

  const LLMResponse({
    required this.content,
    this.promptTokens = 0,
    this.completionTokens = 0,
    this.finishReason,
    this.latency,
  });

  int get totalTokens => promptTokens + completionTokens;
}

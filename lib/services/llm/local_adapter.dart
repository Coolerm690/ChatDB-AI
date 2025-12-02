import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../models/llm_config.dart';
import 'llm_adapter_interface.dart';

/// Tipo di server locale supportato
enum LocalServerType {
  ollama,
  lmstudio,
  llamacpp,
}

/// Adapter per modelli LLM locali (Ollama, LM Studio, llama.cpp)
class LocalAdapter implements LLMAdapterInterface {
  static final Logger _logger = Logger();

  final LocalServerType serverType;
  LLMConfig? _config;
  final http.Client _httpClient = http.Client();

  LocalAdapter({this.serverType = LocalServerType.ollama});

  @override
  String get providerId => serverType.name;

  @override
  String get providerName {
    switch (serverType) {
      case LocalServerType.ollama:
        return 'Ollama';
      case LocalServerType.lmstudio:
        return 'LM Studio';
      case LocalServerType.llamacpp:
        return 'llama.cpp';
    }
  }

  @override
  int get maxContextTokens => 32000;

  @override
  bool get supportsReasoning => false;

  @override
  bool get supportsStreaming => true;

  @override
  List<String> get availableModels {
    switch (serverType) {
      case LocalServerType.ollama:
        return ['llama3', 'llama2', 'codellama', 'mistral', 'mixtral', 'phi', 'gemma'];
      case LocalServerType.lmstudio:
      case LocalServerType.llamacpp:
        return ['local-model'];
    }
  }

  @override
  Future<void> initialize(LLMConfig config) async {
    _config = config;
    _logger.i('$providerName adapter inizializzato con modello: ${config.model}');
  }

  @override
  Future<LLMResponse> complete(LLMRequest request) async {
    _ensureInitialized();

    final startTime = DateTime.now();

    try {
      late http.Response response;

      switch (serverType) {
        case LocalServerType.ollama:
          response = await _completeOllama(request);
          break;
        case LocalServerType.lmstudio:
          response = await _completeLMStudio(request);
          break;
        case LocalServerType.llamacpp:
          response = await _completeLlamaCpp(request);
          break;
      }

      if (response.statusCode != 200) {
        throw Exception('$providerName error: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = _extractContent(data);
      final latency = DateTime.now().difference(startTime);

      return LLMResponse(
        content: content,
        latency: latency,
      );
    } catch (e) {
      _logger.e('Errore chiamata $providerName: $e');
      rethrow;
    }
  }

  Future<http.Response> _completeOllama(LLMRequest request) async {
    final prompt = '${request.systemPrompt}\n\nUser: ${request.userPrompt}\n\nAssistant:';

    return await _httpClient.post(
      Uri.parse(_config!.effectiveEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': _config!.model,
        'prompt': prompt,
        'stream': false,
        'options': {
          'temperature': _config!.temperature,
          'num_predict': _config!.maxTokens,
        },
      }),
    );
  }

  Future<http.Response> _completeLMStudio(LLMRequest request) async {
    return await _httpClient.post(
      Uri.parse(_config!.effectiveEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': _config!.model,
        'messages': [
          {'role': 'system', 'content': request.systemPrompt},
          {'role': 'user', 'content': request.userPrompt},
        ],
        'temperature': _config!.temperature,
        'max_tokens': _config!.maxTokens,
        'stream': false,
      }),
    );
  }

  Future<http.Response> _completeLlamaCpp(LLMRequest request) async {
    final prompt = '${request.systemPrompt}\n\nUser: ${request.userPrompt}\n\nAssistant:';

    return await _httpClient.post(
      Uri.parse(_config!.effectiveEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'prompt': prompt,
        'temperature': _config!.temperature,
        'n_predict': _config!.maxTokens,
        'stream': false,
      }),
    );
  }

  String _extractContent(Map<String, dynamic> data) {
    switch (serverType) {
      case LocalServerType.ollama:
        return data['response'] ?? '';
      case LocalServerType.lmstudio:
        return data['choices']?[0]?['message']?['content'] ?? '';
      case LocalServerType.llamacpp:
        return data['content'] ?? '';
    }
  }

  @override
  Stream<String> streamComplete(LLMRequest request) async* {
    _ensureInitialized();

    try {
      switch (serverType) {
        case LocalServerType.ollama:
          yield* _streamOllama(request);
          break;
        case LocalServerType.lmstudio:
          yield* _streamLMStudio(request);
          break;
        case LocalServerType.llamacpp:
          yield* _streamLlamaCpp(request);
          break;
      }
    } catch (e) {
      _logger.e('Errore streaming $providerName: $e');
      rethrow;
    }
  }

  Stream<String> _streamOllama(LLMRequest request) async* {
    final prompt = '${request.systemPrompt}\n\nUser: ${request.userPrompt}\n\nAssistant:';

    final httpRequest = http.Request('POST', Uri.parse(_config!.effectiveEndpoint));
    httpRequest.headers.addAll({'Content-Type': 'application/json'});
    httpRequest.body = jsonEncode({
      'model': _config!.model,
      'prompt': prompt,
      'stream': true,
      'options': {
        'temperature': _config!.temperature,
        'num_predict': _config!.maxTokens,
      },
    });

    final streamedResponse = await _httpClient.send(httpRequest);

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.isNotEmpty) {
          try {
            final data = jsonDecode(line);
            final text = data['response'];
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          } catch (_) {}
        }
      }
    }
  }

  Stream<String> _streamLMStudio(LLMRequest request) async* {
    final httpRequest = http.Request('POST', Uri.parse(_config!.effectiveEndpoint));
    httpRequest.headers.addAll({'Content-Type': 'application/json'});
    httpRequest.body = jsonEncode({
      'model': _config!.model,
      'messages': [
        {'role': 'system', 'content': request.systemPrompt},
        {'role': 'user', 'content': request.userPrompt},
      ],
      'temperature': _config!.temperature,
      'max_tokens': _config!.maxTokens,
      'stream': true,
    });

    final streamedResponse = await _httpClient.send(httpRequest);

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ') && !line.contains('[DONE]')) {
          try {
            final data = jsonDecode(line.substring(6));
            final delta = data['choices']?[0]?['delta']?['content'];
            if (delta != null) {
              yield delta;
            }
          } catch (_) {}
        }
      }
    }
  }

  Stream<String> _streamLlamaCpp(LLMRequest request) async* {
    final prompt = '${request.systemPrompt}\n\nUser: ${request.userPrompt}\n\nAssistant:';

    final httpRequest = http.Request('POST', Uri.parse(_config!.effectiveEndpoint));
    httpRequest.headers.addAll({'Content-Type': 'application/json'});
    httpRequest.body = jsonEncode({
      'prompt': prompt,
      'temperature': _config!.temperature,
      'n_predict': _config!.maxTokens,
      'stream': true,
    });

    final streamedResponse = await _httpClient.send(httpRequest);

    await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final data = jsonDecode(line.substring(6));
            final text = data['content'];
            if (text != null) {
              yield text;
            }
          } catch (_) {}
        }
      }
    }
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    // I modelli locali non richiedono API key
    return true;
  }

  /// Verifica se il server locale è raggiungibile
  Future<bool> isServerAvailable() async {
    try {
      String healthUrl;
      switch (serverType) {
        case LocalServerType.ollama:
          healthUrl = 'http://localhost:11434/api/tags';
          break;
        case LocalServerType.lmstudio:
          healthUrl = 'http://localhost:1234/v1/models';
          break;
        case LocalServerType.llamacpp:
          healthUrl = 'http://localhost:8080/health';
          break;
      }

      final response = await _httpClient.get(Uri.parse(healthUrl)).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Ottiene i modelli disponibili da Ollama
  Future<List<String>> getOllamaModels() async {
    if (serverType != LocalServerType.ollama) return [];

    try {
      final response = await _httpClient.get(
        Uri.parse('http://localhost:11434/api/tags'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List?;
        return models?.map((m) => m['name'] as String).toList() ?? [];
      }
    } catch (e) {
      _logger.e('Errore recupero modelli Ollama: $e');
    }

    return [];
  }

  @override
  Future<int> estimateTokens(String text) async {
    return (text.length / 4).ceil();
  }

  @override
  Future<void> dispose() async {
    _httpClient.close();
  }

  void _ensureInitialized() {
    if (_config == null) {
      throw Exception('Adapter non inizializzato. Chiama initialize() prima.');
    }
  }
}

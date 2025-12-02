import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../models/llm_config.dart';
import 'llm_adapter_interface.dart';

/// Adapter per OpenAI API
class OpenAIAdapter implements LLMAdapterInterface {
  static final Logger _logger = Logger();

  LLMConfig? _config;
  final http.Client _httpClient = http.Client();

  @override
  String get providerId => 'openai';

  @override
  String get providerName => 'OpenAI';

  @override
  int get maxContextTokens => 128000;

  @override
  bool get supportsReasoning => true;

  @override
  bool get supportsStreaming => true;

  @override
  List<String> get availableModels => [
        'gpt-4o',
        'gpt-4o-mini',
        'gpt-4-turbo',
        'gpt-4',
        'gpt-3.5-turbo',
      ];

  @override
  Future<void> initialize(LLMConfig config) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      throw Exception('API key OpenAI richiesta');
    }
    _config = config;
    _logger.i('OpenAI adapter inizializzato con modello: ${config.model}');
  }

  @override
  Future<LLMResponse> complete(LLMRequest request) async {
    _ensureInitialized();

    final startTime = DateTime.now();

    final messages = _buildMessages(request);

    final body = {
      'model': _config!.model,
      'messages': messages,
      'temperature': _config!.temperature,
      'max_tokens': _config!.maxTokens,
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(_config!.effectiveEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_config!.apiKey}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception('OpenAI API error: ${error['error']?['message'] ?? response.body}');
      }

      final data = jsonDecode(response.body);
      final choice = data['choices'][0];
      final usage = data['usage'];

      final latency = DateTime.now().difference(startTime);

      return LLMResponse(
        content: choice['message']['content'],
        promptTokens: usage['prompt_tokens'],
        completionTokens: usage['completion_tokens'],
        finishReason: choice['finish_reason'],
        latency: latency,
      );
    } catch (e) {
      _logger.e('Errore chiamata OpenAI: $e');
      rethrow;
    }
  }

  @override
  Stream<String> streamComplete(LLMRequest request) async* {
    _ensureInitialized();

    final messages = _buildMessages(request);

    final body = {
      'model': _config!.model,
      'messages': messages,
      'temperature': _config!.temperature,
      'max_tokens': _config!.maxTokens,
      'stream': true,
    };

    try {
      final httpRequest = http.Request('POST', Uri.parse(_config!.effectiveEndpoint));
      httpRequest.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_config!.apiKey}',
      });
      httpRequest.body = jsonEncode(body);

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
    } catch (e) {
      _logger.e('Errore streaming OpenAI: $e');
      rethrow;
    }
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final response = await _httpClient.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> estimateTokens(String text) async {
    // Stima approssimativa: ~4 caratteri per token
    return (text.length / 4).ceil();
  }

  @override
  Future<void> dispose() async {
    _httpClient.close();
  }

  List<Map<String, String>> _buildMessages(LLMRequest request) {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': request.systemPrompt},
    ];

    if (request.conversationHistory != null) {
      messages.addAll(request.conversationHistory!);
    }

    messages.add({'role': 'user', 'content': request.userPrompt});

    return messages;
  }

  void _ensureInitialized() {
    if (_config == null) {
      throw Exception('Adapter non inizializzato. Chiama initialize() prima.');
    }
  }
}

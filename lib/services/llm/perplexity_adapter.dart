import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../models/llm_config.dart';
import 'llm_adapter_interface.dart';

/// Adapter per Perplexity API
class PerplexityAdapter implements LLMAdapterInterface {
  static final Logger _logger = Logger();

  LLMConfig? _config;
  final http.Client _httpClient = http.Client();

  @override
  String get providerId => 'perplexity';

  @override
  String get providerName => 'Perplexity';

  @override
  int get maxContextTokens => 128000;

  @override
  bool get supportsReasoning => true;

  @override
  bool get supportsStreaming => true;

  @override
  List<String> get availableModels => [
        'sonar-pro',
        'sonar',
        'sonar-reasoning-pro',
        'sonar-reasoning',
      ];

  @override
  Future<void> initialize(LLMConfig config) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      throw Exception('API key Perplexity richiesta');
    }
    _config = config;
    _logger.i('Perplexity adapter inizializzato con modello: ${config.model}');
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
        throw Exception('Perplexity API error: ${error['error']?['message'] ?? response.body}');
      }

      final data = jsonDecode(response.body);
      final choice = data['choices'][0];
      final usage = data['usage'];

      final latency = DateTime.now().difference(startTime);

      return LLMResponse(
        content: choice['message']['content'],
        promptTokens: usage?['prompt_tokens'] ?? 0,
        completionTokens: usage?['completion_tokens'] ?? 0,
        finishReason: choice['finish_reason'],
        latency: latency,
      );
    } catch (e) {
      _logger.e('Errore chiamata Perplexity: $e');
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
      _logger.e('Errore streaming Perplexity: $e');
      rethrow;
    }
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('https://api.perplexity.ai/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'sonar',
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
          'max_tokens': 10,
        }),
      );
      _logger.d('Perplexity validation response: ${response.statusCode}');
      if (response.statusCode != 200) {
        _logger.e('Perplexity validation failed: ${response.body}');
      }
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Perplexity validation error: $e');
      return false;
    }
  }

  @override
  Future<int> estimateTokens(String text) async {
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

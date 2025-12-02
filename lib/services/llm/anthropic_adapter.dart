import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../../models/llm_config.dart';
import 'llm_adapter_interface.dart';

/// Adapter per Anthropic Claude API
class AnthropicAdapter implements LLMAdapterInterface {
  static final Logger _logger = Logger();

  LLMConfig? _config;
  final http.Client _httpClient = http.Client();

  @override
  String get providerId => 'anthropic';

  @override
  String get providerName => 'Anthropic';

  @override
  int get maxContextTokens => 200000;

  @override
  bool get supportsReasoning => true;

  @override
  bool get supportsStreaming => true;

  @override
  List<String> get availableModels => [
        'claude-3-5-sonnet-20241022',
        'claude-3-opus-20240229',
        'claude-3-sonnet-20240229',
        'claude-3-haiku-20240307',
      ];

  @override
  Future<void> initialize(LLMConfig config) async {
    if (config.apiKey == null || config.apiKey!.isEmpty) {
      throw Exception('API key Anthropic richiesta');
    }
    _config = config;
    _logger.i('Anthropic adapter inizializzato con modello: ${config.model}');
  }

  @override
  Future<LLMResponse> complete(LLMRequest request) async {
    _ensureInitialized();

    final startTime = DateTime.now();

    final messages = _buildMessages(request);

    final body = {
      'model': _config!.model,
      'max_tokens': _config!.maxTokens,
      'system': request.systemPrompt,
      'messages': messages,
    };

    try {
      final response = await _httpClient.post(
        Uri.parse(_config!.effectiveEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _config!.apiKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception('Anthropic API error: ${error['error']?['message'] ?? response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['content'][0]['text'];
      final usage = data['usage'];

      final latency = DateTime.now().difference(startTime);

      return LLMResponse(
        content: content,
        promptTokens: usage['input_tokens'],
        completionTokens: usage['output_tokens'],
        finishReason: data['stop_reason'],
        latency: latency,
      );
    } catch (e) {
      _logger.e('Errore chiamata Anthropic: $e');
      rethrow;
    }
  }

  @override
  Stream<String> streamComplete(LLMRequest request) async* {
    _ensureInitialized();

    final messages = _buildMessages(request);

    final body = {
      'model': _config!.model,
      'max_tokens': _config!.maxTokens,
      'system': request.systemPrompt,
      'messages': messages,
      'stream': true,
    };

    try {
      final httpRequest = http.Request('POST', Uri.parse(_config!.effectiveEndpoint));
      httpRequest.headers.addAll({
        'Content-Type': 'application/json',
        'x-api-key': _config!.apiKey!,
        'anthropic-version': '2023-06-01',
      });
      httpRequest.body = jsonEncode(body);

      final streamedResponse = await _httpClient.send(httpRequest);

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              if (data['type'] == 'content_block_delta') {
                final text = data['delta']?['text'];
                if (text != null) {
                  yield text;
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      _logger.e('Errore streaming Anthropic: $e');
      rethrow;
    }
  }

  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307',
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> estimateTokens(String text) async {
    // Stima approssimativa per Claude: ~4 caratteri per token
    return (text.length / 4).ceil();
  }

  @override
  Future<void> dispose() async {
    _httpClient.close();
  }

  List<Map<String, String>> _buildMessages(LLMRequest request) {
    final messages = <Map<String, String>>[];

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

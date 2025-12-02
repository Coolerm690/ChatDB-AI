import 'package:logger/logger.dart';

import '../../models/schema_model.dart';
import '../../models/chat_message.dart';
import '../../models/chat_session.dart';
import '../../models/llm_config.dart';
import '../llm/llm_adapter_interface.dart';
import '../llm/openai_adapter.dart';
import '../llm/anthropic_adapter.dart';
import '../llm/perplexity_adapter.dart';
import '../llm/local_adapter.dart';
import '../database/mysql_service.dart';
import '../security/query_validator.dart';
import '../security/data_masking.dart';
import 'prompt_builder.dart';

/// Motore principale del chatbot
class ChatEngine {
  static final Logger _logger = Logger();

  final MySQLService _mysqlService;
  final PromptBuilder _promptBuilder;
  final QueryValidator _queryValidator;
  final DataMasking _dataMasking;

  LLMAdapterInterface? _currentAdapter;
  LLMConfig? _currentConfig;
  SchemaModel? _currentSchema;

  ChatEngine({
    required MySQLService mysqlService,
    PromptBuilder? promptBuilder,
    QueryValidator? queryValidator,
    DataMasking? dataMasking,
  })  : _mysqlService = mysqlService,
        _promptBuilder = promptBuilder ?? PromptBuilder(),
        _queryValidator = queryValidator ?? QueryValidator(),
        _dataMasking = dataMasking ?? DataMasking();

  /// Configura il motore con schema e LLM
  Future<void> configure({
    required SchemaModel schema,
    required LLMConfig llmConfig,
  }) async {
    _currentSchema = schema;
    _currentConfig = llmConfig;

    // Crea e inizializza l'adapter appropriato
    _currentAdapter = _createAdapter(llmConfig.provider);
    await _currentAdapter!.initialize(llmConfig);

    _logger.i('ChatEngine configurato con provider: ${llmConfig.provider.displayName}');
  }

  /// Crea l'adapter LLM appropriato
  LLMAdapterInterface _createAdapter(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.openai:
        return OpenAIAdapter();
      case LLMProvider.anthropic:
        return AnthropicAdapter();
      case LLMProvider.perplexity:
        return PerplexityAdapter();
      case LLMProvider.ollama:
        return LocalAdapter(serverType: LocalServerType.ollama);
      case LLMProvider.lmstudio:
        return LocalAdapter(serverType: LocalServerType.lmstudio);
      case LLMProvider.llamacpp:
        return LocalAdapter(serverType: LocalServerType.llamacpp);
    }
  }

  /// Processa un messaggio utente e genera la risposta
  Future<ChatMessage> processMessage(
    String userMessage,
    ChatSession session,
  ) async {
    _ensureConfigured();

    try {
      // Costruisci i prompt
      final systemPrompt = _promptBuilder.buildSystemPrompt(_currentSchema!);
      
      // Costruisci la cronologia conversazione
      final history = _buildConversationHistory(session);
      
      final userPrompt = _promptBuilder.buildUserPrompt(
        userMessage,
        conversationHistory: history,
      );

      // Crea la richiesta LLM
      final request = LLMRequest(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
        conversationHistory: history,
        config: _currentConfig!,
      );

      // Ottieni la risposta dal LLM
      final response = await _currentAdapter!.complete(request);

      // Estrai eventuale SQL dalla risposta
      final sql = _extractSql(response.content);

      // Se c'è SQL, validalo ed eseguilo
      List<Map<String, dynamic>>? queryResults;
      List<String>? maskedFields;

      if (sql != null) {
        // Valida la query
        final validationResult = _queryValidator.validate(sql, _currentSchema!);
        
        if (validationResult.isValid && validationResult.isReadOnly) {
          // Esegui la query
          queryResults = await _mysqlService.executeQuery(sql);
          
          // Applica masking ai dati sensibili
          final maskingResult = _dataMasking.maskResults(
            queryResults,
            _currentSchema!,
          );
          queryResults = maskingResult.maskedData;
          maskedFields = maskingResult.maskedFields;
        } else {
          _logger.w('Query non valida o non read-only: ${validationResult.errors}');
        }
      }

      return ChatMessage.assistant(
        content: response.content,
        sql: sql,
        queryResults: queryResults,
        maskedFields: maskedFields,
      );
    } catch (e) {
      _logger.e('Errore elaborazione messaggio: $e');
      return ChatMessage.error(e.toString());
    }
  }

  /// Processa un messaggio in streaming
  Stream<String> processMessageStream(
    String userMessage,
    ChatSession session,
  ) async* {
    _ensureConfigured();

    // Costruisci i prompt
    final systemPrompt = _promptBuilder.buildSystemPrompt(_currentSchema!);
    final history = _buildConversationHistory(session);
    final userPrompt = _promptBuilder.buildUserPrompt(
      userMessage,
      conversationHistory: history,
    );

    // Crea la richiesta LLM
    final request = LLMRequest(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      conversationHistory: history,
      config: _currentConfig!,
    );

    // Stream la risposta
    yield* _currentAdapter!.streamComplete(request);
  }

  /// Costruisce la cronologia conversazione per il contesto
  /// Esclude l'ultimo messaggio user perché viene aggiunto separatamente come userPrompt
  List<Map<String, String>> _buildConversationHistory(ChatSession session) {
    final history = <Map<String, String>>[];
    
    // Prendi i messaggi escludendo l'ultimo (che è il messaggio user corrente)
    var messages = session.messages;
    if (messages.isNotEmpty && messages.last.role == MessageRole.user) {
      messages = messages.sublist(0, messages.length - 1);
    }
    
    // Limita agli ultimi N messaggi
    if (messages.length > _promptBuilder.maxContextMessages) {
      messages = messages.sublist(
        messages.length - _promptBuilder.maxContextMessages,
      );
    }

    for (final msg in messages) {
      history.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }

    return history;
  }

  /// Estrae SQL dalla risposta LLM
  String? _extractSql(String response) {
    // Cerca blocchi di codice SQL
    final sqlBlockPattern = RegExp(
      r'```sql\s*([\s\S]*?)\s*```',
      caseSensitive: false,
    );
    
    final match = sqlBlockPattern.firstMatch(response);
    if (match != null) {
      return match.group(1)?.trim();
    }

    // Cerca query SELECT inline
    final selectPattern = RegExp(
      r'\b(SELECT\s+[\s\S]*?(?:;|$))',
      caseSensitive: false,
    );
    
    final selectMatch = selectPattern.firstMatch(response);
    if (selectMatch != null) {
      final sql = selectMatch.group(1)?.trim();
      // Verifica che sia una query ragionevole
      if (sql != null && sql.length > 10 && sql.length < 2000) {
        return sql;
      }
    }

    return null;
  }

  /// Esegue una query diretta (già validata)
  Future<List<Map<String, dynamic>>> executeQuery(String sql) async {
    _ensureConfigured();

    // Valida la query
    final validationResult = _queryValidator.validate(sql, _currentSchema!);
    
    if (!validationResult.isValid) {
      throw Exception('Query non valida: ${validationResult.errors.join(', ')}');
    }

    if (!validationResult.isReadOnly) {
      throw Exception('Solo query SELECT sono permesse');
    }

    return await _mysqlService.executeQuery(sql);
  }

  /// Verifica che il motore sia configurato
  void _ensureConfigured() {
    if (_currentAdapter == null || _currentSchema == null || _currentConfig == null) {
      throw Exception('ChatEngine non configurato. Chiama configure() prima.');
    }
  }

  /// Rilascia le risorse
  Future<void> dispose() async {
    await _currentAdapter?.dispose();
    _currentAdapter = null;
    _currentSchema = null;
    _currentConfig = null;
  }
}

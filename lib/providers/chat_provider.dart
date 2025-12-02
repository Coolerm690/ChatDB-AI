import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/llm_config.dart';
import '../services/chat/chat_engine.dart';
import 'connection_provider.dart';
import 'schema_provider.dart';
import 'settings_provider.dart';

/// Stato della chat
class ChatState {
  final List<ChatSession> sessions;
  final ChatSession? currentSession;
  final bool isLoading;
  final String? error;
  final String? llmProvider;

  const ChatState({
    this.sessions = const [],
    this.currentSession,
    this.isLoading = false,
    this.error,
    this.llmProvider,
  });

  /// Lista messaggi della sessione corrente
  List<ChatMessage> get messages => currentSession?.messages ?? [];

  ChatState copyWith({
    List<ChatSession>? sessions,
    ChatSession? currentSession,
    bool? isLoading,
    String? error,
    String? llmProvider,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      currentSession: currentSession ?? this.currentSession,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      llmProvider: llmProvider ?? this.llmProvider,
    );
  }
}

/// Notifier per la gestione della chat
class ChatNotifier extends StateNotifier<ChatState> {
  final ChatEngine _chatEngine;
  final Ref _ref;

  ChatNotifier(this._chatEngine, this._ref)
      : super(const ChatState()) {
    _initialize();
  }

  /// Inizializza il provider
  Future<void> _initialize() async {
    // Crea una sessione iniziale
    await newSession();
    // Aggiorna il provider dopo un breve delay per dare tempo al settings di caricare
    Future.delayed(const Duration(milliseconds: 500), () {
      refreshLLMProvider();
    });
  }

  /// Aggiorna il provider LLM visualizzato (pubblico per refresh esterno)
  void refreshLLMProvider() {
    final settings = _ref.read(settingsProvider);
    final providerName = settings.llmConfig?.provider.displayName;
    state = state.copyWith(llmProvider: providerName);
  }

  /// Crea una nuova sessione chat
  Future<void> newSession() async {
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Nuova conversazione',
      createdAt: DateTime.now(),
    );

    final updatedSessions = [session, ...state.sessions];
    state = state.copyWith(
      sessions: updatedSessions,
      currentSession: session,
    );
  }

  /// Seleziona una sessione esistente
  void selectSession(String sessionId) {
    final session = state.sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => state.sessions.first,
    );
    state = state.copyWith(currentSession: session);
  }

  /// Elimina una sessione
  Future<void> deleteSession(String sessionId) async {
    final updatedSessions =
        state.sessions.where((s) => s.id != sessionId).toList();

    ChatSession? newCurrentSession;
    if (state.currentSession?.id == sessionId) {
      newCurrentSession =
          updatedSessions.isNotEmpty ? updatedSessions.first : null;
    }

    state = state.copyWith(
      sessions: updatedSessions,
      currentSession: newCurrentSession ?? state.currentSession,
    );

    if (updatedSessions.isEmpty) {
      await newSession();
    }
  }

  /// Invia un messaggio
  Future<void> sendMessage(String content) async {
    if (state.currentSession == null) {
      await newSession();
    }

    // Crea messaggio utente
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
    );

    // Aggiungi messaggio utente alla sessione
    var updatedSession = state.currentSession!.addMessage(userMessage);

    // Aggiorna titolo se è il primo messaggio
    if (updatedSession.messages.length == 1) {
      updatedSession = updatedSession.copyWith(
        title: content.length > 30 ? '${content.substring(0, 30)}...' : content,
      );
    }

    _updateSession(updatedSession);
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Ottieni configurazione LLM
      final settings = _ref.read(settingsProvider);
      final llmConfig = settings.llmConfig;

      if (llmConfig == null) {
        throw Exception('LLM non configurato. Clicca sul badge in alto a destra per configurare.');
      }
      
      if (llmConfig.apiKey == null || llmConfig.apiKey!.isEmpty) {
        throw Exception('API key mancante. Clicca sul badge in alto a destra per configurare.');
      }

      // Ottieni schema
      final schemaState = _ref.read(schemaProvider);
      
      if (schemaState.tables.isEmpty) {
        throw Exception('Schema non caricato. Torna al wizard per configurare le tabelle.');
      }

      // Configura il motore chat
      await _chatEngine.configure(
        schema: schemaState.toSchemaModel(),
        llmConfig: llmConfig,
      );

      // Elabora il messaggio
      final response = await _chatEngine.processMessage(
        content,
        updatedSession,
      );

      // response è già un ChatMessage
      updatedSession = updatedSession.addMessage(response);
      _updateSession(updatedSession);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Crea messaggio errore
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: 'Errore: $e',
        timestamp: DateTime.now(),
        status: MessageStatus.error,
        errorMessage: e.toString(),
      );

      updatedSession = updatedSession.addMessage(errorMessage);
      _updateSession(updatedSession);

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Aggiorna una sessione nella lista
  void _updateSession(ChatSession session) {
    final updatedSessions = state.sessions.map((s) {
      return s.id == session.id ? session : s;
    }).toList();

    state = state.copyWith(
      sessions: updatedSessions,
      currentSession: session,
    );
  }

  /// Pulisce l'errore
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Pulisce la sessione corrente
  Future<void> clearCurrentSession() async {
    if (state.currentSession != null) {
      final clearedSession = state.currentSession!.copyWith(
        messages: [],
        title: 'Nuova Chat',
      );
      _updateSession(clearedSession);
    }
  }
}

/// Provider per il motore chat
final chatEngineProvider = Provider<ChatEngine>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  return ChatEngine(mysqlService: mysqlService);
});

/// Provider per lo stato della chat
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final chatEngine = ref.watch(chatEngineProvider);
  return ChatNotifier(chatEngine, ref);
});

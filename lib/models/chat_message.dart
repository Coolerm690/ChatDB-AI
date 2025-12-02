import 'package:equatable/equatable.dart';

/// Ruolo del messaggio nella chat
enum MessageRole {
  user,
  assistant,
  system,
}

/// Stato del messaggio
enum MessageStatus {
  sending,
  sent,
  error,
}

/// Modello di un messaggio chat
class ChatMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final String? sql;
  final List<Map<String, dynamic>>? queryResults;
  final List<String>? maskedFields;
  final String? errorMessage;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.sql,
    this.queryResults,
    this.maskedFields,
    this.errorMessage,
  });

  /// È un messaggio dell'utente
  bool get isUser => role == MessageRole.user;

  /// È un messaggio dell'assistente
  bool get isAssistant => role == MessageRole.assistant;

  /// Ha risultati query
  bool get hasQueryResults => queryResults != null && queryResults!.isNotEmpty;

  /// Ha SQL generato
  bool get hasSql => sql != null && sql!.isNotEmpty;

  /// Ha errore
  bool get hasError => status == MessageStatus.error || errorMessage != null;

  /// Crea una copia con valori modificati
  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    String? sql,
    List<Map<String, dynamic>>? queryResults,
    List<String>? maskedFields,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      sql: sql ?? this.sql,
      queryResults: queryResults ?? this.queryResults,
      maskedFields: maskedFields ?? this.maskedFields,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Converte in Map per JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      if (sql != null) 'sql': sql,
      if (queryResults != null) 'queryResults': queryResults,
      if (maskedFields != null) 'maskedFields': maskedFields,
      if (errorMessage != null) 'errorMessage': errorMessage,
    };
  }

  /// Crea da Map JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      role: MessageRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      sql: json['sql'] as String?,
      queryResults: json['queryResults'] != null
          ? List<Map<String, dynamic>>.from(json['queryResults'] as List)
          : null,
      maskedFields: json['maskedFields'] != null
          ? List<String>.from(json['maskedFields'] as List)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// Crea messaggio utente
  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
  }

  /// Crea messaggio assistente
  factory ChatMessage.assistant({
    required String content,
    String? sql,
    List<Map<String, dynamic>>? queryResults,
    List<String>? maskedFields,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      sql: sql,
      queryResults: queryResults,
      maskedFields: maskedFields,
    );
  }

  /// Crea messaggio di errore
  factory ChatMessage.error(String errorMessage) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: 'Si è verificato un errore durante l\'elaborazione della richiesta.',
      timestamp: DateTime.now(),
      status: MessageStatus.error,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        content,
        timestamp,
        status,
        sql,
        queryResults,
        maskedFields,
        errorMessage,
      ];
}

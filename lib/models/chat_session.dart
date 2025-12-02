import 'package:equatable/equatable.dart';
import 'chat_message.dart';

/// Modello di una sessione chat
class ChatSession extends Equatable {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ChatMessage> messages;
  final String? databaseName;
  final String? llmProvider;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
    this.databaseName,
    this.llmProvider,
  });

  /// Numero messaggi
  int get messageCount => messages.length;

  /// Ultimo messaggio
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Data ultimo messaggio o creazione
  DateTime get lastActivity => updatedAt ?? createdAt;

  /// Crea una copia con valori modificati
  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
    String? databaseName,
    String? llmProvider,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
      databaseName: databaseName ?? this.databaseName,
      llmProvider: llmProvider ?? this.llmProvider,
    );
  }

  /// Aggiunge un messaggio
  ChatSession addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  /// Aggiorna l'ultimo messaggio
  ChatSession updateLastMessage(ChatMessage message) {
    if (messages.isEmpty) return this;
    final updatedMessages = List<ChatMessage>.from(messages);
    updatedMessages[updatedMessages.length - 1] = message;
    return copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
  }

  /// Converte in Map per JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
      if (databaseName != null) 'databaseName': databaseName,
      if (llmProvider != null) 'llmProvider': llmProvider,
    };
  }

  /// Crea da Map JSON
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      databaseName: json['databaseName'] as String?,
      llmProvider: json['llmProvider'] as String?,
    );
  }

  /// Crea nuova sessione
  factory ChatSession.create({
    required String databaseName,
    String? llmProvider,
  }) {
    final now = DateTime.now();
    return ChatSession(
      id: now.millisecondsSinceEpoch.toString(),
      title: 'Nuova conversazione',
      createdAt: now,
      databaseName: databaseName,
      llmProvider: llmProvider,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        createdAt,
        updatedAt,
        messages,
        databaseName,
        llmProvider,
      ];
}

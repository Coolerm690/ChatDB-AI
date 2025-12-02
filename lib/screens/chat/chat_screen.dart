import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/routes.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/schema_provider.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/query_result_widget.dart';

/// Schermata principale della chat AI
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    _messageController.clear();
    _focusNode.requestFocus();

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _sendMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);
    final schemaState = ref.watch(schemaProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar con sessioni e schema
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header sidebar
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ChatDB-AI',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          ref.read(chatProvider.notifier).newSession();
                        },
                        icon: const Icon(Icons.add),
                        tooltip: 'Nuova sessione',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Schema info
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.storage,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${schemaState.tables.length} tabelle',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Schema configurato',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.wizard);
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          tooltip: 'Modifica schema',
                        ),
                      ],
                    ),
                  ),
                ),

                // Sessioni chat
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: chatState.sessions.length,
                    itemBuilder: (context, index) {
                      final session = chatState.sessions[index];
                      final isActive =
                          session.id == chatState.currentSession?.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 4),
                        color: isActive
                            ? theme.colorScheme.primaryContainer
                            : null,
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.message,
                            size: 18,
                            color: isActive
                                ? theme.colorScheme.primary
                                : null,
                          ),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${session.messages.length} messaggi',
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () {
                            ref
                                .read(chatProvider.notifier)
                                .selectSession(session.id);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () {
                              ref
                                  .read(chatProvider.notifier)
                                  .deleteSession(session.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Pulsanti azioni
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.settings);
                          },
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('Impostazioni'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Area chat principale
          Expanded(
            child: Column(
              children: [
                // Header chat
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chatState.currentSession?.title ?? 'Nuova Chat',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            'Fai domande sul tuo database',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Provider LLM corrente - cliccabile per configurare
                      InkWell(
                        onTap: () async {
                          await Navigator.of(context).pushNamed(AppRoutes.settings);
                          // Aggiorna il provider dopo aver configurato
                          ref.read(chatProvider.notifier).refreshLLMProvider();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: chatState.llmProvider != null
                                ? theme.colorScheme.secondaryContainer
                                : theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                chatState.llmProvider != null
                                    ? Icons.psychology
                                    : Icons.warning,
                                size: 16,
                                color: chatState.llmProvider != null
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                chatState.llmProvider ?? 'Non configurato',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: chatState.llmProvider != null
                                      ? theme.colorScheme.onSecondaryContainer
                                      : theme.colorScheme.onErrorContainer,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: chatState.llmProvider != null
                                    ? theme.colorScheme.onSecondaryContainer
                                    : theme.colorScheme.onErrorContainer,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Messaggi
                Expanded(
                  child: chatState.messages.isEmpty
                      ? _buildEmptyState(theme)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: chatState.messages.length,
                          itemBuilder: (context, index) {
                            final message = chatState.messages[index];
                            return _buildMessageWidget(message, theme);
                          },
                        ),
                ),

                // Loading indicator
                if (chatState.isLoading)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'L\'AI sta elaborando la tua richiesta...',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                // Error message
                if (chatState.error != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            chatState.error!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            ref.read(chatProvider.notifier).clearError();
                          },
                        ),
                      ],
                    ),
                  ),

                // Input area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: KeyboardListener(
                          focusNode: FocusNode(),
                          onKeyEvent: _handleKeyEvent,
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              hintText: 'Scrivi la tua domanda...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton(
                        onPressed:
                            chatState.isLoading ? null : _sendMessage,
                        child: chatState.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Inizia una conversazione',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Fai domande in linguaggio naturale sul tuo database',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 32),
          // Suggerimenti
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Quanti ordini ci sono?', theme),
              _buildSuggestionChip('Mostra gli ultimi 10 clienti', theme),
              _buildSuggestionChip('Qual è il totale vendite?', theme),
              _buildSuggestionChip('Elenca i prodotti più venduti', theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, ThemeData theme) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageWidget(ChatMessage message, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: message.role == MessageRole.user
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          MessageBubble(message: message),
          if (message.sql != null) ...[
            const SizedBox(height: 8),
            _buildSqlQueryWidget(message.sql!, theme),
          ],
          if (message.queryResults != null) ...[
            const SizedBox(height: 8),
            QueryResultWidget(results: message.queryResults!),
          ],
        ],
      ),
    );
  }

  Widget _buildSqlQueryWidget(String sql, ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.code,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Query SQL',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: sql));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Query copiata negli appunti'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Copia query',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            sql,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/chat_message.dart';

/// Widget bubble per i messaggi della chat
class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == MessageRole.user;
    final isError = message.status == MessageStatus.error;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isError
              ? theme.colorScheme.errorContainer
              : isUser
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con icona ruolo
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getRoleIcon(),
                  size: 16,
                  color: isError
                      ? theme.colorScheme.error
                      : isUser
                          ? Colors.white.withOpacity(0.8)
                          : theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _getRoleLabel(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isError
                        ? theme.colorScheme.error
                        : isUser
                            ? Colors.white.withOpacity(0.8)
                            : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isUser
                        ? Colors.white.withOpacity(0.6)
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Contenuto messaggio
            SelectableText(
              message.content,
              style: TextStyle(
                color: isError
                    ? theme.colorScheme.onErrorContainer
                    : isUser
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),

            // Error message (se disponibile)
            if (message.errorMessage != null && isError) ...[
              const SizedBox(height: 8),
              Text(
                message.errorMessage!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon() {
    if (message.status == MessageStatus.error) {
      return Icons.error_outline;
    }
    switch (message.role) {
      case MessageRole.user:
        return Icons.person;
      case MessageRole.assistant:
        return Icons.smart_toy;
      case MessageRole.system:
        return Icons.settings;
    }
  }

  String _getRoleLabel() {
    if (message.status == MessageStatus.error) {
      return 'Errore';
    }
    switch (message.role) {
      case MessageRole.user:
        return 'Tu';
      case MessageRole.assistant:
        return 'AI';
      case MessageRole.system:
        return 'Sistema';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');

    if (messageDate == today) {
      return '$hour:$minute';
    } else {
      final day = timestamp.day.toString().padLeft(2, '0');
      final month = timestamp.month.toString().padLeft(2, '0');
      return '$day/$month $hour:$minute';
    }
  }
}

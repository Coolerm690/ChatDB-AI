import 'dart:convert';

import '../../models/schema_model.dart';
import '../../models/table_model.dart';
import '../../config/app_config.dart';

/// Costruttore di prompt per il chatbot
class PromptBuilder {
  /// Costruisce il system prompt con lo schema del database
  String buildSystemPrompt(SchemaModel schema) {
    final buffer = StringBuffer();

    buffer.writeln('''
Sei ChatDB-AI, un assistente specializzato per l'interrogazione di database MySQL.

REGOLE FONDAMENTALI:

1. FONTE DATI UNICA
   - Rispondi ESCLUSIVAMENTE basandoti sullo schema e dati forniti di seguito
   - NON inventare tabelle, colonne o dati non presenti nello schema
   - Se l'informazione non è disponibile, dillo chiaramente

2. QUERY SQL
   - Genera query SQL SOLO SE necessario per rispondere alla domanda
   - Le query DEVONO essere SOLO SELECT (read-only)
   - NON usare mai: INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE
   - Aggiungi sempre LIMIT per evitare risultati troppo grandi
   - Usa alias chiari per le colonne

3. DATI SENSIBILI
   - Le colonne marcate come sensibili NON devono essere mostrate in chiaro
   - Suggerisci quando applicare masking
   - Non mostrare dati sensibili completi senza richiesta esplicita

4. STILE RISPOSTA
   - Tono professionale ma accessibile
   - Risposte concise ma complete
   - Non generare SQL a meno che non richiesto
   

5. FORMATO RISPOSTA
   - Rispondi alla domanda in modo preciso e in linguaggio testuale
   - Se ti chiedo di generare SQL, fornisci SOLO il codice SQL senza spiegazioni aggiuntive

''');

    // Aggiungi informazioni sul database
    buffer.writeln('DATABASE: ${schema.database.name}');
    if (schema.database.description != null) {
      buffer.writeln('Descrizione: ${schema.database.description}');
    }
    buffer.writeln();

    // Aggiungi lo schema delle tabelle
    buffer.writeln('SCHEMA DATABASE:');
    buffer.writeln('================');
    buffer.writeln();

    for (final table in schema.tables) {
      buffer.writeln('TABELLA: ${table.name}');
      if (table.description != null) {
        buffer.writeln('  Descrizione: ${table.description}');
      }
      buffer.writeln('  Ruolo: ${table.role.displayName}');
      buffer.writeln('  Colonne:');

      for (final column in table.columns) {
        final flags = <String>[];
        if (column.isPrimaryKey) flags.add('PK');
        if (column.isForeignKey) flags.add('FK');
        if (column.isSensitive) flags.add('SENSITIVE');
        if (!column.isNullable) flags.add('NOT NULL');

        final flagsStr = flags.isNotEmpty ? ' [${flags.join(', ')}]' : '';
        buffer.writeln('    - ${column.name} (${column.dataType})$flagsStr');
        
        if (column.description != null) {
          buffer.writeln('      → ${column.description}');
        }
        if (column.isForeignKey && column.foreignKeyReference != null) {
          buffer.writeln('      → Riferimento: ${column.foreignKeyReference}');
        }
      }

      if (table.relationships.isNotEmpty) {
        buffer.writeln('  Relazioni:');
        for (final rel in table.relationships) {
          buffer.writeln('    - ${rel.type}: ${table.name}.${rel.foreignKey} → ${rel.targetTable}');
        }
      }

      if (table.rowCount != null) {
        buffer.writeln('  Righe stimate: ${table.rowCount}');
      }

      buffer.writeln();
    }

    // Aggiungi dati campione se disponibili
    if (schema.sampleData != null && schema.sampleData!.isNotEmpty) {
      buffer.writeln('DATI CAMPIONE (per contesto):');
      buffer.writeln('==============================');
      
      for (final entry in schema.sampleData!.entries) {
        buffer.writeln('\n${entry.key}:');
        final samples = entry.value.take(3); // Max 3 campioni per tabella
        buffer.writeln(jsonEncode(samples.toList()));
      }
    }

    return buffer.toString();
  }

  /// Costruisce il prompt utente con contesto conversazione
  String buildUserPrompt(
    String userQuery, {
    List<Map<String, String>>? conversationHistory,
    int maxHistoryMessages = 5,
  }) {
    final buffer = StringBuffer();

    // Aggiungi contesto conversazione se presente
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final recentHistory = conversationHistory.length > maxHistoryMessages
          ? conversationHistory.sublist(conversationHistory.length - maxHistoryMessages)
          : conversationHistory;

      if (recentHistory.isNotEmpty) {
        buffer.writeln('CONTESTO CONVERSAZIONE PRECEDENTE:');
        for (final msg in recentHistory) {
          final role = msg['role'] == 'user' ? 'Utente' : 'Assistente';
          // Tronca messaggi lunghi nel contesto
          var content = msg['content'] ?? '';
          if (content.length > 500) {
            content = '${content.substring(0, 500)}...';
          }
          buffer.writeln('$role: $content');
        }
        buffer.writeln();
      }
    }

    buffer.writeln('DOMANDA UTENTE:');
    buffer.writeln(userQuery);

    return buffer.toString();
  }

  /// Costruisce il prompt per suggerimenti di modellazione
  String buildModelingSuggestionPrompt(SchemaModel schema) {
    return '''
Analizza lo schema del database fornito e suggerisci:

1. DESCRIZIONI SEMANTICHE
   - Proponi descrizioni chiare per tabelle e colonne senza descrizione
   - Basati sui nomi e sui pattern comuni

2. IDENTIFICAZIONE RUOLI
   - Suggerisci il ruolo appropriato per ogni tabella:
     • SENSITIVE: Dati personali, finanziari, credenziali
     • REFERENCE: Tabelle di lookup, configurazione
     • AGGREGATE: Tabelle di aggregazione, report
     • TRANSACTIONAL: Operazioni, ordini, log
     • MASTER: Entità principali (clienti, prodotti)

3. DATI SENSIBILI
   - Identifica colonne potenzialmente sensibili
   - Suggerisci pattern di masking appropriati

4. RELAZIONI
   - Identifica relazioni implicite non dichiarate come FK
   - Suggerisci relazioni mancanti basandoti sui nomi delle colonne

Rispondi in formato JSON strutturato.

SCHEMA DA ANALIZZARE:
${jsonEncode(schema.toJson())}
''';
  }

  /// Costruisce il prompt per validazione query
  String buildQueryValidationPrompt(String sql, SchemaModel schema) {
    return '''
Analizza la seguente query SQL e verifica:

1. È una query di sola lettura (SELECT)?
2. Le tabelle menzionate esistono nello schema?
3. Le colonne menzionate esistono nelle rispettive tabelle?
4. La sintassi è valida per MySQL?
5. Ci sono potenziali problemi di performance?
6. Ci sono dati sensibili che verrebbero esposti?

QUERY DA VALIDARE:
```sql
$sql
```

SCHEMA DATABASE:
${_schemaToCompactString(schema)}

Rispondi in formato JSON:
{
  "valid": true/false,
  "readOnly": true/false,
  "tablesExist": true/false,
  "columnsExist": true/false,
  "syntaxValid": true/false,
  "performanceWarnings": [...],
  "sensitiveDataExposed": [...],
  "errors": [...],
  "suggestions": [...]
}
''';
  }

  String _schemaToCompactString(SchemaModel schema) {
    final buffer = StringBuffer();
    for (final table in schema.tables) {
      final columns = table.columns.map((c) => c.name).join(', ');
      buffer.writeln('${table.name}: [$columns]');
    }
    return buffer.toString();
  }

  /// Numero massimo di messaggi nel contesto
  int get maxContextMessages => AppConfig.maxContextMessages;
}

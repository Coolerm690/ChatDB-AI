import '../../models/schema_model.dart';

/// Risultato della validazione query
class QueryValidationResult {
  final bool isValid;
  final bool isReadOnly;
  final List<String> errors;
  final List<String> warnings;
  final List<String> suggestions;

  const QueryValidationResult({
    required this.isValid,
    required this.isReadOnly,
    this.errors = const [],
    this.warnings = const [],
    this.suggestions = const [],
  });

  factory QueryValidationResult.valid() {
    return const QueryValidationResult(
      isValid: true,
      isReadOnly: true,
    );
  }

  factory QueryValidationResult.invalid(List<String> errors) {
    return QueryValidationResult(
      isValid: false,
      isReadOnly: false,
      errors: errors,
    );
  }
}

/// Validatore delle query SQL per garantire solo operazioni read-only
class QueryValidator {
  /// Keywords SQL proibite (operazioni di modifica)
  static const List<String> _forbiddenKeywords = [
    'INSERT',
    'UPDATE',
    'DELETE',
    'DROP',
    'ALTER',
    'CREATE',
    'TRUNCATE',
    'REPLACE',
    'MERGE',
    'EXECUTE',
    'EXEC',
    'CALL',
    'GRANT',
    'REVOKE',
    'RENAME',
    'LOAD',
    'HANDLER',
    'DO',
    'FLUSH',
    'RESET',
    'PURGE',
    'START',
    'STOP',
    'LOCK',
    'UNLOCK',
    'XA',
    'SAVEPOINT',
    'ROLLBACK',
    'COMMIT',
    'SET',
    'PREPARE',
    'DEALLOCATE',
  ];

  /// Keywords SQL permesse
  static const List<String> _allowedStartKeywords = [
    'SELECT',
    'SHOW',
    'DESCRIBE',
    'DESC',
    'EXPLAIN',
    'WITH', // per CTE
  ];

  /// Pattern pericolosi
  static const List<String> _dangerousPatterns = [
    r'INTO\s+OUTFILE',
    r'INTO\s+DUMPFILE',
    r'LOAD_FILE',
    r'--\s*$', // commenti SQL
    r'/\*.*\*/', // commenti block
    r';\s*\w', // query multiple
    r'UNION\s+ALL\s+SELECT.*FROM\s+information_schema',
    r'@@', // variabili di sistema
    r'BENCHMARK\s*\(',
    r'SLEEP\s*\(',
    r'WAITFOR',
  ];

  /// Valida una query SQL
  QueryValidationResult validate(String sql, SchemaModel schema) {
    final errors = <String>[];
    final warnings = <String>[];
    final suggestions = <String>[];

    // Normalizza la query
    final normalizedSql = sql.trim().toUpperCase();

    // Verifica che inizi con keyword permessa
    bool startsWithAllowed = false;
    for (final keyword in _allowedStartKeywords) {
      if (normalizedSql.startsWith(keyword)) {
        startsWithAllowed = true;
        break;
      }
    }

    if (!startsWithAllowed) {
      errors.add('La query deve iniziare con SELECT, SHOW, DESCRIBE o EXPLAIN');
    }

    // Verifica keywords proibite
    for (final keyword in _forbiddenKeywords) {
      // Cerca la keyword come parola intera
      final pattern = RegExp('\\b$keyword\\b', caseSensitive: false);
      if (pattern.hasMatch(sql)) {
        errors.add('Keyword proibita trovata: $keyword');
      }
    }

    // Verifica pattern pericolosi
    for (final pattern in _dangerousPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      if (regex.hasMatch(sql)) {
        errors.add('Pattern pericoloso rilevato: $pattern');
      }
    }

    // Verifica query multiple (punto e virgola non finale)
    final semicolonCount = ';'.allMatches(sql.trim().replaceAll(RegExp(r';\s*$'), '')).length;
    if (semicolonCount > 0) {
      errors.add('Query multiple non sono permesse');
    }

    // Verifica tabelle esistenti nello schema
    final tablesInQuery = _extractTableNames(sql);
    final schemaTables = schema.tables.map((t) => t.name.toLowerCase()).toSet();
    
    for (final table in tablesInQuery) {
      if (!schemaTables.contains(table.toLowerCase()) &&
          !_isSystemTable(table)) {
        warnings.add('Tabella non trovata nello schema: $table');
      }
    }

    // Verifica colonne sensibili
    final sensitiveColumns = <String>[];
    for (final table in schema.tables) {
      for (final column in table.columns) {
        if (column.isSensitive) {
          sensitiveColumns.add('${table.name}.${column.name}');
        }
      }
    }

    if (sensitiveColumns.isNotEmpty) {
      for (final col in sensitiveColumns) {
        final parts = col.split('.');
        final columnName = parts.last;
        if (sql.toLowerCase().contains(columnName.toLowerCase())) {
          warnings.add('La query potrebbe esporre dati sensibili: $col');
        }
      }
    }

    // Verifica LIMIT
    if (!normalizedSql.contains('LIMIT') && normalizedSql.contains('SELECT')) {
      suggestions.add('Considera di aggiungere LIMIT per limitare i risultati');
    }

    final isValid = errors.isEmpty;
    final isReadOnly = isValid && startsWithAllowed;

    return QueryValidationResult(
      isValid: isValid,
      isReadOnly: isReadOnly,
      errors: errors,
      warnings: warnings,
      suggestions: suggestions,
    );
  }

  /// Estrae i nomi delle tabelle dalla query
  List<String> _extractTableNames(String sql) {
    final tables = <String>[];

    // Pattern per FROM e JOIN
    final patterns = [
      RegExp(r'\bFROM\s+[`"]?(\w+)[`"]?', caseSensitive: false),
      RegExp(r'\bJOIN\s+[`"]?(\w+)[`"]?', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(sql);
      for (final match in matches) {
        final table = match.group(1);
        if (table != null && !tables.contains(table)) {
          tables.add(table);
        }
      }
    }

    return tables;
  }

  /// Verifica se è una tabella di sistema
  bool _isSystemTable(String table) {
    const systemTables = [
      'dual',
      'information_schema',
      'mysql',
      'performance_schema',
      'sys',
    ];
    return systemTables.contains(table.toLowerCase());
  }

  /// Sanitizza una query rimuovendo elementi pericolosi
  String sanitize(String sql) {
    var sanitized = sql;

    // Rimuovi commenti
    sanitized = sanitized.replaceAll(RegExp(r'--.*$', multiLine: true), '');
    sanitized = sanitized.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    // Rimuovi spazi multipli
    sanitized = sanitized.replaceAll(RegExp(r'\s+'), ' ');

    // Trim
    sanitized = sanitized.trim();

    // Rimuovi punto e virgola finale
    if (sanitized.endsWith(';')) {
      sanitized = sanitized.substring(0, sanitized.length - 1).trim();
    }

    return sanitized;
  }
}

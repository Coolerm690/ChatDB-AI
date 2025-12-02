import '../../models/schema_model.dart';

/// Risultato del masking
class MaskingResult {
  final List<Map<String, dynamic>> maskedData;
  final List<String> maskedFields;

  const MaskingResult({
    required this.maskedData,
    required this.maskedFields,
  });
}

/// Servizio per il masking dei dati sensibili
class DataMasking {
  /// Pattern di masking predefiniti
  static const Map<String, MaskingPattern> _patterns = {
    'email': MaskingPattern(
      pattern: r'^(.{2})(.*)(@.*)$',
      replacement: r'$1***$3',
    ),
    'phone': MaskingPattern(
      pattern: r'^(.{3})(.*)(.{4})$',
      replacement: r'$1***$3',
    ),
    'credit_card': MaskingPattern(
      pattern: r'^(.{4})(.*)(.{4})$',
      replacement: r'$1 **** **** $3',
    ),
    'ssn': MaskingPattern(
      pattern: r'^(.*)(.{3})$',
      replacement: r'******$2',
    ),
    'full': MaskingPattern(
      pattern: r'.*',
      replacement: '[HIDDEN]',
    ),
    'partial': MaskingPattern(
      pattern: r'^(.{3})(.*)$',
      replacement: r'$1***',
    ),
  };

  /// Applica il masking ai risultati della query
  MaskingResult maskResults(
    List<Map<String, dynamic>> data,
    SchemaModel schema,
  ) {
    if (data.isEmpty) {
      return const MaskingResult(maskedData: [], maskedFields: []);
    }

    // Trova le colonne sensibili nello schema
    final sensitiveColumns = <String, String>{};
    for (final table in schema.tables) {
      for (final column in table.columns) {
        if (column.isSensitive) {
          final pattern = column.maskingPattern ?? _detectPattern(column.name);
          sensitiveColumns[column.name.toLowerCase()] = pattern;
        }
      }
    }

    if (sensitiveColumns.isEmpty) {
      return MaskingResult(maskedData: data, maskedFields: []);
    }

    // Applica il masking
    final maskedData = <Map<String, dynamic>>[];
    final maskedFields = <String>{};

    for (final row in data) {
      final maskedRow = <String, dynamic>{};
      
      for (final entry in row.entries) {
        final key = entry.key;
        final value = entry.value;

        // Cerca match case-insensitive
        String? patternKey;
        for (final sensitiveKey in sensitiveColumns.keys) {
          if (key.toLowerCase() == sensitiveKey ||
              key.toLowerCase().contains(sensitiveKey) ||
              sensitiveKey.contains(key.toLowerCase())) {
            patternKey = sensitiveColumns[sensitiveKey];
            break;
          }
        }

        if (patternKey != null && value != null) {
          maskedRow[key] = _applyMask(value.toString(), patternKey);
          maskedFields.add(key);
        } else {
          maskedRow[key] = value;
        }
      }

      maskedData.add(maskedRow);
    }

    return MaskingResult(
      maskedData: maskedData,
      maskedFields: maskedFields.toList(),
    );
  }

  /// Applica un pattern di masking specifico
  String _applyMask(String value, String patternKey) {
    if (value.isEmpty) return value;

    final pattern = _patterns[patternKey];
    if (pattern == null) {
      return _patterns['partial']!.apply(value);
    }

    return pattern.apply(value);
  }

  /// Rileva il pattern appropriato basandosi sul nome della colonna
  String _detectPattern(String columnName) {
    final name = columnName.toLowerCase();

    if (name.contains('email') || name.contains('mail')) {
      return 'email';
    }
    if (name.contains('phone') ||
        name.contains('telefono') ||
        name.contains('cellulare') ||
        name.contains('mobile')) {
      return 'phone';
    }
    if (name.contains('card') ||
        name.contains('carta') ||
        name.contains('credit')) {
      return 'credit_card';
    }
    if (name.contains('ssn') ||
        name.contains('codice_fiscale') ||
        name.contains('cf') ||
        name.contains('tax')) {
      return 'ssn';
    }
    if (name.contains('password') ||
        name.contains('pwd') ||
        name.contains('secret') ||
        name.contains('token') ||
        name.contains('api_key')) {
      return 'full';
    }

    return 'partial';
  }

  /// Maschera un singolo valore
  String maskValue(String value, String patternKey) {
    return _applyMask(value, patternKey);
  }

  /// Maschera un'email
  String maskEmail(String email) {
    return _applyMask(email, 'email');
  }

  /// Maschera un numero di telefono
  String maskPhone(String phone) {
    return _applyMask(phone, 'phone');
  }

  /// Maschera una carta di credito
  String maskCreditCard(String card) {
    return _applyMask(card, 'credit_card');
  }

  /// Maschera un codice fiscale/SSN
  String maskSSN(String ssn) {
    return _applyMask(ssn, 'ssn');
  }

  /// Maschera completamente un valore
  String maskFull(String value) {
    return _applyMask(value, 'full');
  }

  /// Identifica colonne potenzialmente sensibili
  List<String> detectSensitiveColumns(List<String> columnNames) {
    const sensitivePatterns = [
      'password',
      'pwd',
      'secret',
      'token',
      'api_key',
      'apikey',
      'email',
      'mail',
      'phone',
      'telefono',
      'cellulare',
      'mobile',
      'ssn',
      'codice_fiscale',
      'cf',
      'tax_id',
      'credit_card',
      'carta',
      'card',
      'iban',
      'bank',
      'conto',
      'indirizzo',
      'address',
      'ip_address',
      'ip',
      'birth',
      'nascita',
      'dob',
      'salary',
      'stipendio',
      'income',
      'reddito',
    ];

    final sensitive = <String>[];

    for (final column in columnNames) {
      final lowerColumn = column.toLowerCase();
      for (final pattern in sensitivePatterns) {
        if (lowerColumn.contains(pattern)) {
          sensitive.add(column);
          break;
        }
      }
    }

    return sensitive;
  }
}

/// Pattern di masking
class MaskingPattern {
  final String pattern;
  final String replacement;

  const MaskingPattern({
    required this.pattern,
    required this.replacement,
  });

  String apply(String value) {
    try {
      final regex = RegExp(pattern);
      if (regex.hasMatch(value)) {
        return value.replaceFirstMapped(regex, (match) {
          var result = replacement;
          for (var i = 0; i <= match.groupCount; i++) {
            result = result.replaceAll('\$$i', match.group(i) ?? '');
          }
          return result;
        });
      }
    } catch (e) {
      // In caso di errore, usa masking parziale
      if (value.length > 6) {
        return '${value.substring(0, 3)}***${value.substring(value.length - 3)}';
      }
    }
    return '***';
  }
}

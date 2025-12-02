import 'package:logger/logger.dart';

import '../../models/schema_model.dart';
import '../../models/table_model.dart';
import '../../config/app_config.dart';
import 'mysql_service.dart';

/// Servizio per la lettura e costruzione dello schema database
class SchemaReader {
  final MySQLService _mysqlService;
  static final Logger _logger = Logger();

  SchemaReader(this._mysqlService);

  /// Legge lo schema completo del database
  Future<SchemaModel> readFullSchema({
    bool includeSampleData = true,
  }) async {
    if (!_mysqlService.isConnected) {
      throw Exception('Database non connesso');
    }

    final config = _mysqlService.currentConfig!;
    _logger.i('Lettura schema per database: ${config.database}');

    // Ottieni lista tabelle
    final tableNames = await _mysqlService.getTables();
    _logger.d('Trovate ${tableNames.length} tabelle');

    // Leggi schema di ogni tabella
    final tables = <TableModel>[];
    final sampleData = <String, List<Map<String, dynamic>>>{};

    for (final tableName in tableNames) {
      try {
        final tableSchema = await _mysqlService.getTableSchema(tableName);
        tables.add(tableSchema);

        // Leggi dati campione se richiesto
        if (includeSampleData) {
          final samples = await _mysqlService.getSampleData(
            tableName,
            limit: AppConfig.dataSampleLimit,
          );
          if (samples.isNotEmpty) {
            sampleData[tableName] = samples;
          }
        }
      } catch (e) {
        _logger.w('Errore lettura tabella $tableName: $e');
      }
    }

    return SchemaModel(
      createdAt: DateTime.now(),
      database: DatabaseInfo(
        name: config.database,
      ),
      tables: tables,
      sampleData: includeSampleData && sampleData.isNotEmpty ? sampleData : null,
    );
  }

  /// Suggerisce colonne sensibili basandosi sui nomi
  List<String> detectSensitiveColumns(List<TableModel> tables) {
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
      'carta_credito',
      'iban',
      'bank_account',
      'conto',
      'indirizzo',
      'address',
      'ip_address',
      'ip',
      'birth_date',
      'data_nascita',
      'dob',
      'salary',
      'stipendio',
      'income',
      'reddito',
    ];

    final sensitiveColumns = <String>[];

    for (final table in tables) {
      for (final column in table.columns) {
        final columnName = column.name.toLowerCase();
        for (final pattern in sensitivePatterns) {
          if (columnName.contains(pattern)) {
            sensitiveColumns.add('${table.name}.${column.name}');
            break;
          }
        }
      }
    }

    return sensitiveColumns;
  }

  /// Suggerisce ruoli per le tabelle basandosi su pattern comuni
  Map<String, TableRole> suggestTableRoles(List<TableModel> tables) {
    final suggestions = <String, TableRole>{};

    for (final table in tables) {
      final tableName = table.name.toLowerCase();

      // Pattern per tabelle reference/lookup
      if (tableName.contains('type') ||
          tableName.contains('status') ||
          tableName.contains('category') ||
          tableName.contains('categor') ||
          tableName.contains('config') ||
          tableName.contains('setting') ||
          tableName.endsWith('_types') ||
          tableName.endsWith('_stati')) {
        suggestions[table.name] = TableRole.reference;
        continue;
      }

      // Pattern per tabelle transazionali
      if (tableName.contains('order') ||
          tableName.contains('ordin') ||
          tableName.contains('transaction') ||
          tableName.contains('log') ||
          tableName.contains('event') ||
          tableName.contains('audit') ||
          tableName.contains('payment') ||
          tableName.contains('pagament')) {
        suggestions[table.name] = TableRole.transactional;
        continue;
      }

      // Pattern per tabelle master
      if (tableName.contains('customer') ||
          tableName.contains('client') ||
          tableName.contains('user') ||
          tableName.contains('utent') ||
          tableName.contains('product') ||
          tableName.contains('prodott') ||
          tableName.contains('employee') ||
          tableName.contains('dipendent')) {
        suggestions[table.name] = TableRole.master;
        continue;
      }

      // Pattern per tabelle sensibili
      if (tableName.contains('credential') ||
          tableName.contains('auth') ||
          tableName.contains('secret') ||
          tableName.contains('private')) {
        suggestions[table.name] = TableRole.sensitive;
        continue;
      }

      // Pattern per tabelle aggregate
      if (tableName.contains('summary') ||
          tableName.contains('report') ||
          tableName.contains('stat') ||
          tableName.contains('aggrega') ||
          tableName.endsWith('_agg') ||
          tableName.endsWith('_tot')) {
        suggestions[table.name] = TableRole.aggregate;
        continue;
      }

      // Default
      suggestions[table.name] = TableRole.other;
    }

    return suggestions;
  }

  /// Suggerisce pattern di masking per colonne sensibili
  String? suggestMaskingPattern(String columnName) {
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
    if (name.contains('credit_card') ||
        name.contains('carta') ||
        name.contains('card')) {
      return 'credit_card';
    }
    if (name.contains('ssn') ||
        name.contains('codice_fiscale') ||
        name.contains('cf') ||
        name.contains('tax')) {
      return 'ssn';
    }
    if (name.contains('password') ||
        name.contains('secret') ||
        name.contains('token') ||
        name.contains('api_key')) {
      return 'full';
    }

    return null;
  }
}

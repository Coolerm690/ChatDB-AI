import 'package:mysql_client/mysql_client.dart';
import 'package:logger/logger.dart';

import '../../models/connection_config.dart';
import '../../models/table_model.dart';
import '../../models/column_model.dart';

/// Servizio per la connessione e interrogazione MySQL
class MySQLService {
  static final Logger _logger = Logger();
  
  MySQLConnection? _connection;
  ConnectionConfig? _config;
  bool _isConnected = false;

  /// Stato connessione
  bool get isConnected => _isConnected;

  /// Configurazione corrente
  ConnectionConfig? get currentConfig => _config;

  /// Connette al database MySQL
  Future<bool> connect(ConnectionConfig config) async {
    try {
      _logger.i('Tentativo connessione a ${config.maskedConnectionString}');

      _connection = await MySQLConnection.createConnection(
        host: config.host,
        port: config.port,
        userName: config.username,
        password: config.password,
        databaseName: config.database,
        secure: config.useSSL,
      );

      await _connection!.connect(timeoutMs: config.timeout * 1000);

      _config = config;
      _isConnected = true;
      _logger.i('Connessione riuscita a ${config.database}');
      return true;
    } catch (e) {
      _logger.e('Errore connessione: $e');
      _isConnected = false;
      _connection = null;
      rethrow;
    }
  }

  /// Disconnette dal database
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
        _logger.i('Disconnessione completata');
      } catch (e) {
        _logger.e('Errore disconnessione: $e');
      } finally {
        _connection = null;
        _config = null;
        _isConnected = false;
      }
    }
  }

  /// Testa la connessione
  Future<bool> testConnection(ConnectionConfig config) async {
    MySQLConnection? testConn;
    try {
      testConn = await MySQLConnection.createConnection(
        host: config.host,
        port: config.port,
        userName: config.username,
        password: config.password,
        databaseName: config.database,
        secure: config.useSSL,
      );

      await testConn.connect(timeoutMs: config.timeout * 1000);
      await testConn.execute('SELECT 1');
      await testConn.close();
      return true;
    } catch (e) {
      _logger.e('Test connessione fallito: $e');
      testConn?.close();
      return false;
    }
  }

  /// Esegue una query SELECT (solo lettura)
  Future<List<Map<String, dynamic>>> executeQuery(String sql) async {
    _ensureConnected();
    
    // Valida che sia una query di sola lettura
    if (!_isReadOnlyQuery(sql)) {
      throw Exception('Solo query SELECT sono permesse');
    }

    try {
      _logger.d('Esecuzione query: $sql');
      final result = await _connection!.execute(sql);
      
      final rows = <Map<String, dynamic>>[];
      for (final row in result.rows) {
        rows.add(row.assoc());
      }
      
      _logger.d('Query completata: ${rows.length} righe');
      return rows;
    } catch (e) {
      _logger.e('Errore esecuzione query: $e');
      rethrow;
    }
  }

  /// Ottiene la lista delle tabelle
  Future<List<String>> getTables() async {
    _ensureConnected();

    final result = await _connection!.execute('SHOW TABLES');
    final tables = <String>[];
    
    for (final row in result.rows) {
      final values = row.assoc().values;
      if (values.isNotEmpty) {
        tables.add(values.first ?? '');
      }
    }
    
    return tables;
  }

  /// Ottiene lo schema di una tabella
  Future<TableModel> getTableSchema(String tableName) async {
    _ensureConnected();

    // Ottieni le colonne
    final columnsResult = await _connection!.execute('''
      SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        COLUMN_KEY,
        COLUMN_DEFAULT,
        EXTRA,
        COLUMN_COMMENT
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = '${_config!.database}'
        AND TABLE_NAME = '$tableName'
      ORDER BY ORDINAL_POSITION
    ''');

    final columns = <ColumnModel>[];
    for (final row in columnsResult.rows) {
      final data = row.assoc();
      columns.add(ColumnModel(
        name: data['COLUMN_NAME'] ?? '',
        dataType: data['DATA_TYPE']?.toUpperCase() ?? 'VARCHAR',
        isNullable: data['IS_NULLABLE'] == 'YES',
        isPrimaryKey: data['COLUMN_KEY'] == 'PRI',
        isForeignKey: data['COLUMN_KEY'] == 'MUL',
        defaultValue: data['COLUMN_DEFAULT'],
        description: data['COLUMN_COMMENT'],
      ));
    }

    // Ottieni relazioni FK
    final fkResult = await _connection!.execute('''
      SELECT 
        COLUMN_NAME,
        REFERENCED_TABLE_NAME,
        REFERENCED_COLUMN_NAME
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = '${_config!.database}'
        AND TABLE_NAME = '$tableName'
        AND REFERENCED_TABLE_NAME IS NOT NULL
    ''');

    final relationships = <TableRelation>[];
    for (final row in fkResult.rows) {
      final data = row.assoc();
      relationships.add(TableRelation(
        type: 'MANY_TO_ONE',
        targetTable: data['REFERENCED_TABLE_NAME'] ?? '',
        foreignKey: data['COLUMN_NAME'] ?? '',
        targetColumn: data['REFERENCED_COLUMN_NAME'],
      ));
    }

    // Ottieni conteggio righe
    final countResult = await _connection!.execute(
      'SELECT COUNT(*) as count FROM `$tableName`',
    );
    int? rowCount;
    if (countResult.rows.isNotEmpty) {
      final countStr = countResult.rows.first.assoc()['count'];
      rowCount = int.tryParse(countStr ?? '');
    }

    return TableModel(
      name: tableName,
      columns: columns,
      relationships: relationships,
      rowCount: rowCount,
    );
  }

  /// Ottiene un campione di dati dalla tabella
  Future<List<Map<String, dynamic>>> getSampleData(
    String tableName, {
    int limit = 5,
  }) async {
    _ensureConnected();

    final result = await _connection!.execute(
      'SELECT * FROM `$tableName` LIMIT $limit',
    );

    final rows = <Map<String, dynamic>>[];
    for (final row in result.rows) {
      rows.add(row.assoc());
    }

    return rows;
  }

  /// Verifica che la connessione sia attiva
  void _ensureConnected() {
    if (!_isConnected || _connection == null) {
      throw Exception('Non connesso al database');
    }
  }

  /// Verifica che la query sia di sola lettura
  bool _isReadOnlyQuery(String sql) {
    final normalized = sql.trim().toUpperCase();
    
    // Lista di keyword proibite
    const forbiddenKeywords = [
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
    ];

    for (final keyword in forbiddenKeywords) {
      if (normalized.startsWith(keyword) || normalized.contains(' $keyword ')) {
        return false;
      }
    }

    return normalized.startsWith('SELECT') ||
        normalized.startsWith('SHOW') ||
        normalized.startsWith('DESCRIBE') ||
        normalized.startsWith('EXPLAIN');
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../../config/app_config.dart';

/// Tipo di evento audit
enum AuditEventType {
  connectionAttempt,
  connectionSuccess,
  connectionFailed,
  queryExecuted,
  queryFailed,
  chatMessage,
  chatResponse,
  schemaLoaded,
  schemaModified,
  settingsChanged,
  error,
}

/// Livello di severità
enum AuditSeverity {
  info,
  warning,
  error,
  critical,
}

/// Voce del log di audit
class AuditLogEntry {
  final DateTime timestamp;
  final AuditEventType eventType;
  final AuditSeverity severity;
  final String message;
  final Map<String, dynamic>? details;
  final String? userId;
  final String? sessionId;

  AuditLogEntry({
    DateTime? timestamp,
    required this.eventType,
    this.severity = AuditSeverity.info,
    required this.message,
    this.details,
    this.userId,
    this.sessionId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.name,
      'severity': severity.name,
      'message': message,
      if (details != null) 'details': details,
      if (userId != null) 'userId': userId,
      if (sessionId != null) 'sessionId': sessionId,
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      eventType: AuditEventType.values.firstWhere(
        (e) => e.name == json['eventType'],
      ),
      severity: AuditSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => AuditSeverity.info,
      ),
      message: json['message'],
      details: json['details'],
      userId: json['userId'],
      sessionId: json['sessionId'],
    );
  }

  @override
  String toString() {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
    return '[$dateStr] [${severity.name.toUpperCase()}] [${eventType.name}] $message';
  }
}

/// Servizio per il logging di audit
class AuditLogger {
  static final Logger _logger = Logger();
  
  String? _logDirectory;
  String? _currentLogFile;
  final List<AuditLogEntry> _memoryBuffer = [];
  static const int _maxBufferSize = 100;

  /// Inizializza il logger
  Future<void> initialize() async {
    final appDir = await getApplicationSupportDirectory();
    _logDirectory = '${appDir.path}/${AppConfig.auditLogsFolderName}';
    
    final dir = Directory(_logDirectory!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _updateCurrentLogFile();
    _logger.i('AuditLogger inizializzato in: $_logDirectory');

    // Pulisci log vecchi
    await _cleanOldLogs();
  }

  /// Aggiorna il file di log corrente (rotazione giornaliera)
  void _updateCurrentLogFile() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _currentLogFile = '$_logDirectory/audit_$today.log';
  }

  /// Logga un evento
  Future<void> log(AuditLogEntry entry) async {
    // Aggiungi al buffer in memoria
    _memoryBuffer.add(entry);
    if (_memoryBuffer.length > _maxBufferSize) {
      _memoryBuffer.removeAt(0);
    }

    // Log sulla console in debug
    _logger.d(entry.toString());

    // Scrivi su file
    await _writeToFile(entry);
  }

  /// Scrive un'entry su file
  Future<void> _writeToFile(AuditLogEntry entry) async {
    if (_logDirectory == null) return;

    _updateCurrentLogFile();

    try {
      final file = File(_currentLogFile!);
      await file.writeAsString(
        '${jsonEncode(entry.toJson())}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      _logger.e('Errore scrittura audit log: $e');
    }
  }

  // ============ Metodi di convenienza ============

  /// Logga tentativo di connessione
  Future<void> logConnectionAttempt(String host, String database) async {
    await log(AuditLogEntry(
      eventType: AuditEventType.connectionAttempt,
      message: 'Tentativo connessione a $host/$database',
      details: {'host': host, 'database': database},
    ));
  }

  /// Logga connessione riuscita
  Future<void> logConnectionSuccess(String host, String database) async {
    await log(AuditLogEntry(
      eventType: AuditEventType.connectionSuccess,
      message: 'Connessione riuscita a $host/$database',
      details: {'host': host, 'database': database},
    ));
  }

  /// Logga connessione fallita
  Future<void> logConnectionFailed(String host, String database, String error) async {
    await log(AuditLogEntry(
      eventType: AuditEventType.connectionFailed,
      severity: AuditSeverity.warning,
      message: 'Connessione fallita a $host/$database',
      details: {'host': host, 'database': database, 'error': error},
    ));
  }

  /// Logga query eseguita
  Future<void> logQueryExecuted(
    String sql, {
    int? resultCount,
    Duration? executionTime,
    String? sessionId,
  }) async {
    await log(AuditLogEntry(
      eventType: AuditEventType.queryExecuted,
      message: 'Query eseguita',
      sessionId: sessionId,
      details: {
        'sql': sql,
        if (resultCount != null) 'resultCount': resultCount,
        if (executionTime != null) 'executionTimeMs': executionTime.inMilliseconds,
      },
    ));
  }

  /// Logga query fallita
  Future<void> logQueryFailed(String sql, String error, {String? sessionId}) async {
    await log(AuditLogEntry(
      eventType: AuditEventType.queryFailed,
      severity: AuditSeverity.warning,
      message: 'Query fallita',
      sessionId: sessionId,
      details: {'sql': sql, 'error': error},
    ));
  }

  /// Logga messaggio chat utente
  Future<void> logChatMessage(String message, {String? sessionId}) async {
    await log(AuditLogEntry(
      eventType: AuditEventType.chatMessage,
      message: 'Messaggio utente',
      sessionId: sessionId,
      details: {
        'preview': message.length > 100 ? '${message.substring(0, 100)}...' : message,
      },
    ));
  }

  /// Logga risposta chat
  Future<void> logChatResponse(
    String response, {
    String? sql,
    List<String>? maskedFields,
    String? sessionId,
  }) async {
    await log(AuditLogEntry(
      eventType: AuditEventType.chatResponse,
      message: 'Risposta assistente',
      sessionId: sessionId,
      details: {
        'preview': response.length > 100 ? '${response.substring(0, 100)}...' : response,
        if (sql != null) 'sqlGenerated': true,
        if (maskedFields != null && maskedFields.isNotEmpty) 'maskedFields': maskedFields,
      },
    ));
  }

  /// Logga errore generico
  Future<void> logError(String error, {Map<String, dynamic>? context}) async {
    await log(AuditLogEntry(
      eventType: AuditEventType.error,
      severity: AuditSeverity.error,
      message: error,
      details: context,
    ));
  }

  // ============ Lettura log ============

  /// Legge le entry del log di oggi
  Future<List<AuditLogEntry>> getTodayLogs() async {
    return _readLogFile(_currentLogFile);
  }

  /// Legge le entry di una data specifica
  Future<List<AuditLogEntry>> getLogsForDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final file = '$_logDirectory/audit_$dateStr.log';
    return _readLogFile(file);
  }

  /// Legge un file di log
  Future<List<AuditLogEntry>> _readLogFile(String? filePath) async {
    if (filePath == null) return [];

    final entries = <AuditLogEntry>[];
    final file = File(filePath);

    if (!await file.exists()) return entries;

    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.isNotEmpty) {
          try {
            entries.add(AuditLogEntry.fromJson(jsonDecode(line)));
          } catch (e) {
            // Ignora righe malformate
          }
        }
      }
    } catch (e) {
      _logger.e('Errore lettura log: $e');
    }

    return entries;
  }

  /// Ottiene le entry dal buffer in memoria
  List<AuditLogEntry> getRecentLogs() {
    return List.from(_memoryBuffer.reversed);
  }

  // ============ Manutenzione ============

  /// Pulisce i log più vecchi della retention
  Future<void> _cleanOldLogs() async {
    if (_logDirectory == null) return;

    final dir = Directory(_logDirectory!);
    if (!await dir.exists()) return;

    final retention = Duration(days: AppConfig.auditLogRetentionDays);
    final cutoff = DateTime.now().subtract(retention);

    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.log')) {
        final stat = await file.stat();
        if (stat.modified.isBefore(cutoff)) {
          await file.delete();
          _logger.d('Log eliminato: ${file.path}');
        }
      }
    }
  }

  /// Esporta i log in un file JSON
  Future<String> exportLogs(DateTime startDate, DateTime endDate) async {
    final allEntries = <AuditLogEntry>[];

    var current = startDate;
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      final entries = await getLogsForDate(current);
      allEntries.addAll(entries);
      current = current.add(const Duration(days: 1));
    }

    return jsonEncode(allEntries.map((e) => e.toJson()).toList());
  }
}

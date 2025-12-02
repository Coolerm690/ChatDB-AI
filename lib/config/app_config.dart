/// Configurazione globale dell'applicazione ChatDB-AI
class AppConfig {
  AppConfig._();

  /// Nome applicazione
  static const String appName = 'ChatDB-AI Desktop';

  /// Versione applicazione
  static const String appVersion = '1.0.0';

  /// Dimensioni minime finestra
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;

  /// Dimensioni default finestra
  static const double defaultWindowWidth = 1280;
  static const double defaultWindowHeight = 800;

  /// Timeout connessione database (secondi)
  static const int dbConnectionTimeout = 30;

  /// Numero massimo connessioni pool
  static const int maxPoolConnections = 5;

  /// Rate limit LLM (richieste al minuto)
  static const int llmRateLimitPerMinute = 60;

  /// Massimo messaggi in cronologia chat
  static const int maxChatHistoryMessages = 100;

  /// Massimo messaggi da inviare come contesto
  static const int maxContextMessages = 10;

  /// Giorni retention audit log
  static const int auditLogRetentionDays = 30;

  /// Limite righe sample dati
  static const int dataSampleLimit = 5;

  /// Percorso file schema model
  static const String schemaModelFileName = 'schema_model.json';

  /// Percorso cartella sessioni
  static const String sessionsFolderName = 'sessions';

  /// Percorso cartella audit logs
  static const String auditLogsFolderName = 'audit_logs';
}

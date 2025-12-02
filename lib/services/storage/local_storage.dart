import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';

import '../../config/app_config.dart';
import '../../models/schema_model.dart';
import '../../models/chat_session.dart';
import '../../models/connection_config.dart';

/// Servizio per lo storage locale dei dati
class LocalStorage {
  static final Logger _logger = Logger();
  
  String? _appDataPath;
  bool _initialized = false;

  /// Inizializza il servizio di storage (auto-chiamato se necessario)
  Future<void> initialize() async {
    if (_initialized) return;
    
    final appDir = await getApplicationSupportDirectory();
    _appDataPath = appDir.path;
    
    // Crea le directory necessarie
    await _ensureDirectories();
    
    _initialized = true;
    _logger.i('LocalStorage inizializzato in: $_appDataPath');
  }

  /// Assicura che lo storage sia inizializzato
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Percorso dati applicazione
  Future<String> get appDataPathAsync async {
    await _ensureInitialized();
    return _appDataPath!;
  }
  
  /// Percorso dati applicazione (sincrono, lancia eccezione se non inizializzato)
  String get appDataPath {
    if (_appDataPath == null) {
      throw Exception('LocalStorage non inizializzato');
    }
    return _appDataPath!;
  }

  /// Crea le directory necessarie
  Future<void> _ensureDirectories() async {
    final directories = [
      AppConfig.sessionsFolderName,
      AppConfig.auditLogsFolderName,
      'connections',
      'schemas',
    ];

    for (final dir in directories) {
      final path = '$_appDataPath/$dir';
      final directory = Directory(path);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }
  }

  // ============ Schema Model ============

  /// Salva lo schema model
  Future<void> saveSchemaModel(SchemaModel schema, String connectionId) async {
    await _ensureInitialized();
    final file = File('$appDataPath/schemas/$connectionId.json');
    final json = jsonEncode(schema.toJson());
    await file.writeAsString(json);
    _logger.d('Schema salvato per connessione: $connectionId');
  }

  /// Carica lo schema model
  Future<SchemaModel?> loadSchemaModel(String connectionId) async {
    await _ensureInitialized();
    try {
      final file = File('$appDataPath/schemas/$connectionId.json');
      if (await file.exists()) {
        final json = await file.readAsString();
        return SchemaModel.fromJson(jsonDecode(json));
      }
    } catch (e) {
      _logger.e('Errore caricamento schema: $e');
    }
    return null;
  }

  /// Elimina lo schema model
  Future<void> deleteSchemaModel(String connectionId) async {
    await _ensureInitialized();
    final file = File('$appDataPath/schemas/$connectionId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ============ Chat Sessions ============

  /// Salva una sessione chat
  Future<void> saveChatSession(ChatSession session) async {
    await _ensureInitialized();
    final file = File('$appDataPath/${AppConfig.sessionsFolderName}/${session.id}.json');
    final json = jsonEncode(session.toJson());
    await file.writeAsString(json);
    _logger.d('Sessione salvata: ${session.id}');
  }

  /// Carica una sessione chat
  Future<ChatSession?> loadChatSession(String sessionId) async {
    await _ensureInitialized();
    try {
      final file = File('$appDataPath/${AppConfig.sessionsFolderName}/$sessionId.json');
      if (await file.exists()) {
        final json = await file.readAsString();
        return ChatSession.fromJson(jsonDecode(json));
      }
    } catch (e) {
      _logger.e('Errore caricamento sessione: $e');
    }
    return null;
  }

  /// Carica tutte le sessioni chat
  Future<List<ChatSession>> loadAllChatSessions() async {
    await _ensureInitialized();
    final sessions = <ChatSession>[];
    final dir = Directory('$appDataPath/${AppConfig.sessionsFolderName}');
    
    if (!await dir.exists()) return sessions;

    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final json = await file.readAsString();
          sessions.add(ChatSession.fromJson(jsonDecode(json)));
        } catch (e) {
          _logger.w('Errore caricamento sessione ${file.path}: $e');
        }
      }
    }

    // Ordina per data ultimo aggiornamento
    sessions.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return sessions;
  }

  /// Elimina una sessione chat
  Future<void> deleteChatSession(String sessionId) async {
    await _ensureInitialized();
    final file = File('$appDataPath/${AppConfig.sessionsFolderName}/$sessionId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ============ Connections ============

  /// Salva la configurazione di connessione (senza password)
  Future<void> saveConnectionConfig(ConnectionConfig config, String connectionId) async {
    await _ensureInitialized();
    final file = File('$appDataPath/connections/$connectionId.json');
    
    // Non salvare la password nel file JSON
    final safeConfig = config.copyWith(password: '');
    final json = jsonEncode(safeConfig.toJson());
    await file.writeAsString(json);
    _logger.d('Configurazione connessione salvata: $connectionId');
  }

  /// Carica la configurazione di connessione
  Future<ConnectionConfig?> loadConnectionConfig(String connectionId) async {
    await _ensureInitialized();
    try {
      final file = File('$appDataPath/connections/$connectionId.json');
      if (await file.exists()) {
        final json = await file.readAsString();
        return ConnectionConfig.fromJson(jsonDecode(json));
      }
    } catch (e) {
      _logger.e('Errore caricamento connessione: $e');
    }
    return null;
  }

  /// Carica tutte le configurazioni di connessione
  Future<List<ConnectionConfig>> loadAllConnectionConfigs() async {
    await _ensureInitialized();
    final connections = <ConnectionConfig>[];
    final dir = Directory('$appDataPath/connections');
    
    if (!await dir.exists()) return connections;

    await for (final file in dir.list()) {
      if (file is File && file.path.endsWith('.json')) {
        try {
          final json = await file.readAsString();
          connections.add(ConnectionConfig.fromJson(jsonDecode(json)));
        } catch (e) {
          _logger.w('Errore caricamento connessione ${file.path}: $e');
        }
      }
    }

    return connections;
  }

  /// Elimina la configurazione di connessione
  Future<void> deleteConnectionConfig(String connectionId) async {
    await _ensureInitialized();
    final file = File('$appDataPath/connections/$connectionId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ============ Generic JSON Storage ============

  /// Salva un oggetto JSON generico
  Future<void> saveJson(String key, Map<String, dynamic> data) async {
    await _ensureInitialized();
    final file = File('$appDataPath/$key.json');
    await file.writeAsString(jsonEncode(data));
  }

  /// Carica un oggetto JSON generico
  Future<Map<String, dynamic>?> loadJson(String key) async {
    await _ensureInitialized();
    try {
      final file = File('$appDataPath/$key.json');
      if (await file.exists()) {
        return jsonDecode(await file.readAsString());
      }
    } catch (e) {
      _logger.e('Errore caricamento $key: $e');
    }
    return null;
  }

  /// Elimina un file JSON
  Future<void> deleteJson(String key) async {
    await _ensureInitialized();
    final file = File('$appDataPath/$key.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Salva una stringa semplice
  Future<void> saveString(String key, String value) async {
    await _ensureInitialized();
    final file = File('$appDataPath/$key.txt');
    await file.writeAsString(value);
  }

  /// Carica una stringa semplice
  Future<String?> getString(String key) async {
    await _ensureInitialized();
    try {
      final file = File('$appDataPath/$key.txt');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      _logger.e('Errore caricamento stringa $key: $e');
    }
    return null;
  }
}

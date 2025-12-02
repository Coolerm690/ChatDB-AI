import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';

/// Servizio per lo storage sicuro di dati sensibili (API keys, password)
class SecureStorage {
  static final Logger _logger = Logger();

  FlutterSecureStorage? _storageInstance;
  
  /// Getter che inizializza automaticamente lo storage
  FlutterSecureStorage get _storage {
    _storageInstance ??= const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      wOptions: WindowsOptions(),
    );
    return _storageInstance!;
  }

  // Chiavi per lo storage
  static const String _prefixApiKey = 'api_key_';
  static const String _prefixPassword = 'db_password_';
  static const String _prefixConnection = 'db_connection_';
  static const String _keyLastProvider = 'last_provider';
  static const String _keyLastConnection = 'last_connection';
  static const String _keySavedConnections = 'saved_connections_list';

  /// Inizializza lo storage sicuro (opzionale, per compatibilità)
  Future<void> initialize() async {
    // Lo storage si inizializza automaticamente al primo uso
    _logger.i('SecureStorage pronto');
  }

  // ============ API Keys ============

  /// Salva una API key per un provider
  Future<void> saveApiKey(String providerId, String apiKey) async {
    await _storage.write(key: '$_prefixApiKey$providerId', value: apiKey);
    _logger.d('API key salvata per provider: $providerId');
  }

  /// Recupera la API key per un provider
  Future<String?> getApiKey(String providerId) async {
    return await _storage.read(key: '$_prefixApiKey$providerId');
  }

  /// Elimina la API key di un provider
  Future<void> deleteApiKey(String providerId) async {
    await _storage.delete(key: '$_prefixApiKey$providerId');
    _logger.d('API key eliminata per provider: $providerId');
  }

  /// Verifica se esiste una API key per un provider
  Future<bool> hasApiKey(String providerId) async {
    final key = await getApiKey(providerId);
    return key != null && key.isNotEmpty;
  }

  // ============ Database Passwords ============

  /// Salva la password del database
  Future<void> saveDatabasePassword(String connectionId, String password) async {
    await _storage.write(key: '$_prefixPassword$connectionId', value: password);
    _logger.d('Password salvata per connessione: $connectionId');
  }

  /// Recupera la password del database
  Future<String?> getDatabasePassword(String connectionId) async {
    return await _storage.read(key: '$_prefixPassword$connectionId');
  }

  /// Elimina la password del database
  Future<void> deleteDatabasePassword(String connectionId) async {
    await _storage.delete(key: '$_prefixPassword$connectionId');
    _logger.d('Password eliminata per connessione: $connectionId');
  }

  // ============ Saved Database Connections ============

  /// Salva una configurazione di connessione completa
  Future<void> saveConnection(SavedConnection connection) async {
    // Salva i dati della connessione (senza password)
    final connectionData = connection.toJson();
    await _storage.write(
      key: '$_prefixConnection${connection.id}',
      value: jsonEncode(connectionData),
    );
    
    // Salva la password separatamente
    if (connection.password.isNotEmpty) {
      await saveDatabasePassword(connection.id, connection.password);
    }
    
    // Aggiorna la lista delle connessioni salvate
    final connectionIds = await _getSavedConnectionIds();
    if (!connectionIds.contains(connection.id)) {
      connectionIds.add(connection.id);
      await _storage.write(
        key: _keySavedConnections,
        value: jsonEncode(connectionIds),
      );
    }
    
    _logger.i('Connessione salvata: ${connection.name}');
  }

  /// Recupera tutte le connessioni salvate
  Future<List<SavedConnection>> getSavedConnections() async {
    final connectionIds = await _getSavedConnectionIds();
    final connections = <SavedConnection>[];
    
    for (final id in connectionIds) {
      try {
        final connectionJson = await _storage.read(key: '$_prefixConnection$id');
        if (connectionJson != null) {
          final data = jsonDecode(connectionJson) as Map<String, dynamic>;
          final password = await getDatabasePassword(id) ?? '';
          connections.add(SavedConnection.fromJson(data, password));
        }
      } catch (e) {
        _logger.w('Errore lettura connessione $id: $e');
      }
    }
    
    return connections;
  }

  /// Recupera una connessione specifica per ID
  Future<SavedConnection?> getConnection(String id) async {
    try {
      final connectionJson = await _storage.read(key: '$_prefixConnection$id');
      if (connectionJson != null) {
        final data = jsonDecode(connectionJson) as Map<String, dynamic>;
        final password = await getDatabasePassword(id) ?? '';
        return SavedConnection.fromJson(data, password);
      }
    } catch (e) {
      _logger.w('Errore lettura connessione $id: $e');
    }
    return null;
  }

  /// Elimina una connessione salvata
  Future<void> deleteConnection(String id) async {
    await _storage.delete(key: '$_prefixConnection$id');
    await deleteDatabasePassword(id);
    
    final connectionIds = await _getSavedConnectionIds();
    connectionIds.remove(id);
    await _storage.write(
      key: _keySavedConnections,
      value: jsonEncode(connectionIds),
    );
    
    _logger.i('Connessione eliminata: $id');
  }

  /// Ottiene la lista degli ID delle connessioni salvate
  Future<List<String>> _getSavedConnectionIds() async {
    final idsJson = await _storage.read(key: _keySavedConnections);
    if (idsJson != null) {
      return List<String>.from(jsonDecode(idsJson) as List);
    }
    return [];
  }

  // ============ Last Used Settings ============

  /// Salva l'ultimo provider usato
  Future<void> saveLastProvider(String providerId) async {
    await _storage.write(key: _keyLastProvider, value: providerId);
  }

  /// Recupera l'ultimo provider usato
  Future<String?> getLastProvider() async {
    return await _storage.read(key: _keyLastProvider);
  }

  /// Salva l'ultima connessione usata
  Future<void> saveLastConnection(String connectionId) async {
    await _storage.write(key: _keyLastConnection, value: connectionId);
  }

  /// Recupera l'ultima connessione usata
  Future<String?> getLastConnection() async {
    return await _storage.read(key: _keyLastConnection);
  }

  // ============ Generic Secure Storage ============

  /// Salva un valore sicuro generico
  Future<void> saveSecure(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Recupera un valore sicuro generico
  Future<String?> getSecure(String key) async {
    return await _storage.read(key: key);
  }

  /// Elimina un valore sicuro generico
  Future<void> deleteSecure(String key) async {
    await _storage.delete(key: key);
  }

  /// Elimina tutti i dati sicuri
  Future<void> deleteAll() async {
    await _storage.deleteAll();
    _logger.w('Tutti i dati sicuri sono stati eliminati');
  }

  /// Legge tutte le chiavi salvate
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}

/// Modello per una connessione database salvata
class SavedConnection {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final String database;
  final bool useSSL;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  SavedConnection({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.database,
    this.useSSL = false,
    DateTime? createdAt,
    this.lastUsedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Crea un nuovo ID univoco
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Converte in JSON (senza password per sicurezza)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'database': database,
      'useSSL': useSSL,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  /// Crea da JSON (la password viene passata separatamente)
  factory SavedConnection.fromJson(Map<String, dynamic> json, String password) {
    return SavedConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int,
      username: json['username'] as String,
      password: password,
      database: json['database'] as String,
      useSSL: json['useSSL'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null 
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  /// Crea una copia con valori modificati
  SavedConnection copyWith({
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? database,
    bool? useSSL,
    DateTime? lastUsedAt,
  }) {
    return SavedConnection(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      database: database ?? this.database,
      useSSL: useSSL ?? this.useSSL,
      createdAt: createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}

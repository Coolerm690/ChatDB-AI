import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_config.dart';
import '../services/database/mysql_service.dart';
import '../services/storage/secure_storage.dart';

/// Stato della connessione database
class ConnectionState {
  final ConnectionConfig? config;
  final bool isConnected;
  final bool isLoading;
  final String? error;

  const ConnectionState({
    this.config,
    this.isConnected = false,
    this.isLoading = false,
    this.error,
  });

  ConnectionState copyWith({
    ConnectionConfig? config,
    bool? isConnected,
    bool? isLoading,
    String? error,
  }) {
    return ConnectionState(
      config: config ?? this.config,
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier per la gestione della connessione database
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final MySQLService _mysqlService;
  final SecureStorage _secureStorage;

  ConnectionNotifier(this._mysqlService, this._secureStorage)
      : super(const ConnectionState());

  /// Testa la connessione senza salvarla
  Future<bool> testConnection(ConnectionConfig config) async {
    try {
      await _mysqlService.connect(config);
      await _mysqlService.disconnect();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Connette al database e salva la configurazione
  Future<void> connect(ConnectionConfig config) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _mysqlService.connect(config);

      state = state.copyWith(
        config: config,
        isConnected: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Errore connessione: $e',
      );
      rethrow;
    }
  }

  /// Disconnette dal database
  Future<void> disconnect() async {
    try {
      await _mysqlService.disconnect();
      state = state.copyWith(isConnected: false);
    } catch (e) {
      state = state.copyWith(error: 'Errore disconnessione: $e');
    }
  }

  /// Riconnette al database usando la configurazione salvata
  Future<void> reconnect() async {
    if (state.config != null) {
      await connect(state.config!);
    }
  }

  /// Pulisce l'errore
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider per il servizio MySQL
final mysqlServiceProvider = Provider<MySQLService>((ref) {
  return MySQLService();
});

/// Provider per lo storage sicuro
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Provider per lo stato della connessione
final connectionProvider =
    StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return ConnectionNotifier(mysqlService, secureStorage);
});

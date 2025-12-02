import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/table_model.dart';
import '../models/schema_model.dart';
import '../services/database/schema_reader.dart';
import '../services/storage/local_storage.dart';
import 'connection_provider.dart';

/// Stato dello schema database
class SchemaState {
  final List<TableModel> tables;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final String? connectionId;

  const SchemaState({
    this.tables = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
    this.connectionId,
  });

  SchemaState copyWith({
    List<TableModel>? tables,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    String? connectionId,
  }) {
    return SchemaState(
      tables: tables ?? this.tables,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      connectionId: connectionId ?? this.connectionId,
    );
  }

  /// Converte lo stato in un modello schema completo
  SchemaModel toSchemaModel() {
    return SchemaModel(
      tables: tables,
      createdAt: lastUpdated ?? DateTime.now(),
      database: DatabaseInfo(name: 'default'),
    );
  }
}

/// Notifier per la gestione dello schema database
class SchemaNotifier extends StateNotifier<SchemaState> {
  final SchemaReader _schemaReader;
  final LocalStorage _localStorage;
  final Ref _ref;

  SchemaNotifier(this._schemaReader, this._localStorage, this._ref)
      : super(const SchemaState());

  /// Genera ID connessione per salvare lo schema
  String _getConnectionId() {
    final connState = _ref.read(connectionProvider);
    final config = connState.config;
    if (config != null) {
      return '${config.host}_${config.port}_${config.database}';
    }
    return 'default';
  }

  /// Carica lo schema dal database
  Future<void> loadSchema() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final connectionId = _getConnectionId();

      // Legge lo schema dal database
      final dbSchema = await _schemaReader.readFullSchema();
      
      // Prova a caricare lo schema salvato con le descrizioni personalizzate
      final savedSchema = await _localStorage.loadSchemaModel(connectionId);
      
      List<TableModel> mergedTables;
      if (savedSchema != null) {
        // Unisce: struttura dal DB + descrizioni salvate
        mergedTables = _mergeSchemas(dbSchema.tables, savedSchema.tables);
      } else {
        mergedTables = dbSchema.tables;
      }

      state = state.copyWith(
        tables: mergedTables,
        isLoading: false,
        lastUpdated: DateTime.now(),
        connectionId: connectionId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Errore lettura schema: $e',
      );
    }
  }

  /// Unisce le tabelle dal DB con quelle salvate (mantiene descrizioni)
  List<TableModel> _mergeSchemas(
    List<TableModel> dbTables,
    List<TableModel> savedTables,
  ) {
    return dbTables.map((dbTable) {
      // Cerca la tabella salvata corrispondente
      final savedTable = savedTables.firstWhere(
        (t) => t.name == dbTable.name,
        orElse: () => dbTable,
      );
      
      // Unisce le colonne
      final mergedColumns = dbTable.columns.map((dbCol) {
        final savedCol = savedTable.columns.firstWhere(
          (c) => c.name == dbCol.name,
          orElse: () => dbCol,
        );
        // Mantiene struttura DB ma prende descrizione e flag sensibilità dalla versione salvata
        return dbCol.copyWith(
          description: savedCol.description,
          isSensitive: savedCol.isSensitive,
          maskingPattern: savedCol.maskingPattern,
        );
      }).toList();
      
      // Mantiene struttura DB ma prende descrizione e ruolo dalla versione salvata
      return dbTable.copyWith(
        description: savedTable.description,
        role: savedTable.role,
        columns: mergedColumns,
      );
    }).toList();
  }

  /// Salva lo schema configurato su disco
  Future<void> saveSchema(List<TableModel> tables) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final connectionId = state.connectionId ?? _getConnectionId();
      
      final schemaModel = SchemaModel(
        createdAt: state.lastUpdated ?? DateTime.now(),
        updatedAt: DateTime.now(),
        database: DatabaseInfo(name: connectionId),
        tables: tables,
      );
      
      // Salva su disco
      await _localStorage.saveSchemaModel(schemaModel, connectionId);

      state = state.copyWith(
        tables: tables,
        isLoading: false,
        lastUpdated: DateTime.now(),
        connectionId: connectionId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Errore salvataggio schema: $e',
      );
      rethrow;
    }
  }

  /// Aggiorna una singola tabella
  void updateTable(TableModel table) {
    final updatedTables = state.tables.map((t) {
      return t.name == table.name ? table : t;
    }).toList();

    state = state.copyWith(tables: updatedTables);
  }

  /// Ricarica lo schema dal database
  Future<void> refreshSchema() async {
    await loadSchema();
  }

  /// Pulisce l'errore
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider per il lettore schema
final schemaReaderProvider = Provider<SchemaReader>((ref) {
  final mysqlService = ref.watch(mysqlServiceProvider);
  return SchemaReader(mysqlService);
});

/// Provider per lo storage locale
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

/// Provider per lo stato dello schema
final schemaProvider =
    StateNotifierProvider<SchemaNotifier, SchemaState>((ref) {
  final schemaReader = ref.watch(schemaReaderProvider);
  final localStorage = ref.watch(localStorageProvider);
  return SchemaNotifier(schemaReader, localStorage, ref);
});

import 'package:equatable/equatable.dart';
import 'column_model.dart';

/// Ruoli possibili per una tabella
enum TableRole {
  /// Dati sensibili (clienti, pagamenti)
  sensitive,

  /// Tabella di riferimento/lookup
  reference,

  /// Tabella di aggregazione/report
  aggregate,

  /// Tabella transazionale (ordini, log)
  transactional,

  /// Entità master (prodotti, clienti)
  master,

  /// Altro/non specificato
  other,
}

/// Estensione per TableRole
extension TableRoleExtension on TableRole {
  String get displayName {
    switch (this) {
      case TableRole.sensitive:
        return 'Sensibile';
      case TableRole.reference:
        return 'Riferimento';
      case TableRole.aggregate:
        return 'Aggregato';
      case TableRole.transactional:
        return 'Transazionale';
      case TableRole.master:
        return 'Master';
      case TableRole.other:
        return 'Altro';
    }
  }

  String get description {
    switch (this) {
      case TableRole.sensitive:
        return 'Contiene dati personali, finanziari o sensibili';
      case TableRole.reference:
        return 'Tabella di lookup, configurazione o riferimento';
      case TableRole.aggregate:
        return 'Contiene dati aggregati o per report';
      case TableRole.transactional:
        return 'Registra transazioni, operazioni o eventi';
      case TableRole.master:
        return 'Entità principale del dominio';
      case TableRole.other:
        return 'Altro tipo di tabella';
    }
  }
}

/// Relazione tra tabelle
class TableRelation extends Equatable {
  final String type;
  final String targetTable;
  final String foreignKey;
  final String? targetColumn;

  const TableRelation({
    required this.type,
    required this.targetTable,
    required this.foreignKey,
    this.targetColumn,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'targetTable': targetTable,
      'foreignKey': foreignKey,
      if (targetColumn != null) 'targetColumn': targetColumn,
    };
  }

  factory TableRelation.fromJson(Map<String, dynamic> json) {
    return TableRelation(
      type: json['type'] as String,
      targetTable: json['targetTable'] as String? ?? json['target_table'] as String,
      foreignKey: json['foreignKey'] as String? ?? json['foreign_key'] as String,
      targetColumn: json['targetColumn'] as String? ?? json['target_column'] as String?,
    );
  }

  @override
  List<Object?> get props => [type, targetTable, foreignKey, targetColumn];
}

/// Modello di una tabella del database
class TableModel extends Equatable {
  final String name;
  final String? description;
  final TableRole role;
  final List<ColumnModel> columns;
  final List<TableRelation> relationships;
  final int? rowCount;

  const TableModel({
    required this.name,
    this.description,
    this.role = TableRole.other,
    this.columns = const [],
    this.relationships = const [],
    this.rowCount,
  });

  /// Colonne primarie
  List<ColumnModel> get primaryKeyColumns {
    return columns.where((c) => c.isPrimaryKey).toList();
  }

  /// Colonne foreign key
  List<ColumnModel> get foreignKeyColumns {
    return columns.where((c) => c.isForeignKey).toList();
  }

  /// Colonne sensibili
  List<ColumnModel> get sensitiveColumns {
    return columns.where((c) => c.isSensitive).toList();
  }

  /// Crea una copia con valori modificati
  TableModel copyWith({
    String? name,
    String? description,
    TableRole? role,
    List<ColumnModel>? columns,
    List<TableRelation>? relationships,
    int? rowCount,
  }) {
    return TableModel(
      name: name ?? this.name,
      description: description ?? this.description,
      role: role ?? this.role,
      columns: columns ?? this.columns,
      relationships: relationships ?? this.relationships,
      rowCount: rowCount ?? this.rowCount,
    );
  }

  /// Converte in Map per JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'role': role.name,
      'columns': columns.map((c) => c.toJson()).toList(),
      'relationships': relationships.map((r) => r.toJson()).toList(),
      if (rowCount != null) 'rowCount': rowCount,
    };
  }

  /// Crea da Map JSON
  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      name: json['name'] as String,
      description: json['description'] as String?,
      role: TableRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => TableRole.other,
      ),
      columns: (json['columns'] as List<dynamic>?)
              ?.map((c) => ColumnModel.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      relationships: (json['relationships'] as List<dynamic>?)
              ?.map((r) => TableRelation.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      rowCount: json['rowCount'] as int? ?? json['row_count'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        name,
        description,
        role,
        columns,
        relationships,
        rowCount,
      ];
}

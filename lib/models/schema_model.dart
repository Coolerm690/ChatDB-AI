import 'package:equatable/equatable.dart';
import 'table_model.dart';

/// Modello completo dello schema database
class SchemaModel extends Equatable {
  final String version;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DatabaseInfo database;
  final List<TableModel> tables;
  final Map<String, List<Map<String, dynamic>>>? sampleData;

  const SchemaModel({
    this.version = '1.0',
    required this.createdAt,
    this.updatedAt,
    required this.database,
    this.tables = const [],
    this.sampleData,
  });

  /// Tabelle sensibili
  List<TableModel> get sensitiveTables {
    return tables.where((t) => t.role == TableRole.sensitive).toList();
  }

  /// Tabelle master
  List<TableModel> get masterTables {
    return tables.where((t) => t.role == TableRole.master).toList();
  }

  /// Numero totale colonne
  int get totalColumns {
    return tables.fold(0, (sum, t) => sum + t.columns.length);
  }

  /// Numero colonne sensibili
  int get totalSensitiveColumns {
    return tables.fold(0, (sum, t) => sum + t.sensitiveColumns.length);
  }

  /// Crea una copia con valori modificati
  SchemaModel copyWith({
    String? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    DatabaseInfo? database,
    List<TableModel>? tables,
    Map<String, List<Map<String, dynamic>>>? sampleData,
  }) {
    return SchemaModel(
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      database: database ?? this.database,
      tables: tables ?? this.tables,
      sampleData: sampleData ?? this.sampleData,
    );
  }

  /// Converte in Map per JSON
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'database': database.toJson(),
      'tables': tables.map((t) => t.toJson()).toList(),
      if (sampleData != null) 'sampleData': sampleData,
    };
  }

  /// Crea da Map JSON
  factory SchemaModel.fromJson(Map<String, dynamic> json) {
    return SchemaModel(
      version: json['version'] as String? ?? '1.0',
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String)
              : null,
      database: DatabaseInfo.fromJson(json['database'] as Map<String, dynamic>),
      tables: (json['tables'] as List<dynamic>?)
              ?.map((t) => TableModel.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
      sampleData: json['sampleData'] != null || json['sample_data'] != null
          ? Map<String, List<Map<String, dynamic>>>.from(
              (json['sampleData'] ?? json['sample_data']) as Map,
            )
          : null,
    );
  }

  /// Schema vuoto
  factory SchemaModel.empty(String databaseName) {
    return SchemaModel(
      createdAt: DateTime.now(),
      database: DatabaseInfo(name: databaseName),
    );
  }

  @override
  List<Object?> get props => [
        version,
        createdAt,
        updatedAt,
        database,
        tables,
        sampleData,
      ];
}

/// Informazioni sul database
class DatabaseInfo extends Equatable {
  final String name;
  final String? description;
  final String? charset;
  final String? collation;

  const DatabaseInfo({
    required this.name,
    this.description,
    this.charset,
    this.collation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (charset != null) 'charset': charset,
      if (collation != null) 'collation': collation,
    };
  }

  factory DatabaseInfo.fromJson(Map<String, dynamic> json) {
    return DatabaseInfo(
      name: json['name'] as String,
      description: json['description'] as String?,
      charset: json['charset'] as String?,
      collation: json['collation'] as String?,
    );
  }

  @override
  List<Object?> get props => [name, description, charset, collation];
}

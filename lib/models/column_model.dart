import 'package:equatable/equatable.dart';

/// Modello di una colonna del database
class ColumnModel extends Equatable {
  final String name;
  final String dataType;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isForeignKey;
  final String? foreignKeyReference;
  final String? defaultValue;
  final String? description;
  final bool isSensitive;
  final String? maskingPattern;

  const ColumnModel({
    required this.name,
    required this.dataType,
    this.isNullable = true,
    this.isPrimaryKey = false,
    this.isForeignKey = false,
    this.foreignKeyReference,
    this.defaultValue,
    this.description,
    this.isSensitive = false,
    this.maskingPattern,
  });

  /// Crea una copia con valori modificati
  ColumnModel copyWith({
    String? name,
    String? dataType,
    bool? isNullable,
    bool? isPrimaryKey,
    bool? isForeignKey,
    String? foreignKeyReference,
    String? defaultValue,
    String? description,
    bool? isSensitive,
    String? maskingPattern,
  }) {
    return ColumnModel(
      name: name ?? this.name,
      dataType: dataType ?? this.dataType,
      isNullable: isNullable ?? this.isNullable,
      isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
      isForeignKey: isForeignKey ?? this.isForeignKey,
      foreignKeyReference: foreignKeyReference ?? this.foreignKeyReference,
      defaultValue: defaultValue ?? this.defaultValue,
      description: description ?? this.description,
      isSensitive: isSensitive ?? this.isSensitive,
      maskingPattern: maskingPattern ?? this.maskingPattern,
    );
  }

  /// Converte in Map per JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dataType': dataType,
      'isNullable': isNullable,
      'isPrimaryKey': isPrimaryKey,
      'isForeignKey': isForeignKey,
      if (foreignKeyReference != null) 'foreignKeyReference': foreignKeyReference,
      if (defaultValue != null) 'defaultValue': defaultValue,
      if (description != null) 'description': description,
      'isSensitive': isSensitive,
      if (maskingPattern != null) 'maskingPattern': maskingPattern,
    };
  }

  /// Crea da Map JSON
  factory ColumnModel.fromJson(Map<String, dynamic> json) {
    return ColumnModel(
      name: json['name'] as String,
      dataType: json['dataType'] as String? ?? json['data_type'] as String? ?? 'VARCHAR',
      isNullable: json['isNullable'] as bool? ?? json['is_nullable'] as bool? ?? true,
      isPrimaryKey: json['isPrimaryKey'] as bool? ?? json['is_primary_key'] as bool? ?? false,
      isForeignKey: json['isForeignKey'] as bool? ?? json['is_foreign_key'] as bool? ?? false,
      foreignKeyReference: json['foreignKeyReference'] as String? ?? json['foreign_key_reference'] as String?,
      defaultValue: json['defaultValue'] as String? ?? json['default_value'] as String?,
      description: json['description'] as String?,
      isSensitive: json['isSensitive'] as bool? ?? json['is_sensitive'] as bool? ?? false,
      maskingPattern: json['maskingPattern'] as String? ?? json['masking_pattern'] as String?,
    );
  }

  /// Pattern di masking predefiniti
  static const Map<String, String> defaultMaskingPatterns = {
    'email': r'^(.{2})(.*)(@.*)$', // j***@example.com
    'phone': r'^(.{3})(.*)(.{4})$', // +39***1234
    'credit_card': r'^(.{4})(.*)(.{4})$', // 4111****1111
    'ssn': r'^(.*)(.{3})$', // ******789
    'full': r'.*', // [HIDDEN]
  };

  @override
  List<Object?> get props => [
        name,
        dataType,
        isNullable,
        isPrimaryKey,
        isForeignKey,
        foreignKeyReference,
        defaultValue,
        description,
        isSensitive,
        maskingPattern,
      ];
}

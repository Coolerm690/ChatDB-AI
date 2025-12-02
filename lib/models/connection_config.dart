import 'package:equatable/equatable.dart';

/// Configurazione connessione database MySQL
class ConnectionConfig extends Equatable {
  final String host;
  final int port;
  final String username;
  final String password;
  final String database;
  final bool useSSL;
  final int timeout;

  const ConnectionConfig({
    required this.host,
    this.port = 3306,
    required this.username,
    required this.password,
    required this.database,
    this.useSSL = false,
    this.timeout = 30,
  });

  /// Crea una copia con valori modificati
  ConnectionConfig copyWith({
    String? host,
    int? port,
    String? username,
    String? password,
    String? database,
    bool? useSSL,
    int? timeout,
  }) {
    return ConnectionConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      database: database ?? this.database,
      useSSL: useSSL ?? this.useSSL,
      timeout: timeout ?? this.timeout,
    );
  }

  /// Converte in Map per JSON
  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'database': database,
      'useSSL': useSSL,
      'timeout': timeout,
    };
  }

  /// Crea da Map JSON (senza password per sicurezza)
  factory ConnectionConfig.fromJson(Map<String, dynamic> json) {
    return ConnectionConfig(
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? 3306,
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      database: json['database'] as String? ?? '',
      useSSL: json['useSSL'] as bool? ?? false,
      timeout: json['timeout'] as int? ?? 30,
    );
  }

  /// Configurazione vuota
  factory ConnectionConfig.empty() {
    return const ConnectionConfig(
      host: '',
      username: '',
      password: '',
      database: '',
    );
  }

  /// Verifica se la configurazione è valida
  bool get isValid {
    return host.isNotEmpty &&
        username.isNotEmpty &&
        password.isNotEmpty &&
        database.isNotEmpty &&
        port > 0 &&
        port <= 65535;
  }

  /// Stringa di connessione mascherata per log
  String get maskedConnectionString {
    return 'mysql://$username:****@$host:$port/$database';
  }

  @override
  List<Object?> get props => [
        host,
        port,
        username,
        password,
        database,
        useSSL,
        timeout,
      ];
}

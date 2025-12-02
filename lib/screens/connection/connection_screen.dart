import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/routes.dart';
import '../../models/connection_config.dart';
import '../../providers/connection_provider.dart';
import '../../services/storage/secure_storage.dart';

/// Schermata di configurazione connessione database
class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '3306');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _databaseController = TextEditingController();
  final _connectionNameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _useSSL = false;
  bool _isTesting = false;
  bool _isConnecting = false;
  bool _saveConnection = true;
  String? _testResult;
  
  List<SavedConnection> _savedConnections = [];
  SavedConnection? _selectedConnection;
  final SecureStorage _secureStorage = SecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedConnections();
  }

  Future<void> _loadSavedConnections() async {
    await _secureStorage.initialize();
    final connections = await _secureStorage.getSavedConnections();
    setState(() {
      _savedConnections = connections;
    });
    
    // Carica l'ultima connessione usata se esiste
    final lastConnectionId = await _secureStorage.getLastConnection();
    if (lastConnectionId != null) {
      final lastConnection = connections.where((c) => c.id == lastConnectionId).firstOrNull;
      if (lastConnection != null) {
        _loadConnectionToForm(lastConnection);
      }
    }
  }

  void _loadConnectionToForm(SavedConnection connection) {
    setState(() {
      _selectedConnection = connection;
      _hostController.text = connection.host;
      _portController.text = connection.port.toString();
      _usernameController.text = connection.username;
      _passwordController.text = connection.password;
      _databaseController.text = connection.database;
      _connectionNameController.text = connection.name;
      _useSSL = connection.useSSL;
    });
  }

  void _clearForm() {
    setState(() {
      _selectedConnection = null;
      _hostController.text = 'localhost';
      _portController.text = '3306';
      _usernameController.clear();
      _passwordController.clear();
      _databaseController.clear();
      _connectionNameController.clear();
      _useSSL = false;
      _testResult = null;
    });
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _databaseController.dispose();
    _connectionNameController.dispose();
    super.dispose();
  }

  ConnectionConfig _buildConfig() {
    return ConnectionConfig(
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? 3306,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      database: _databaseController.text.trim(),
      useSSL: _useSSL,
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      final config = _buildConfig();
      final success = await ref.read(connectionProvider.notifier).testConnection(config);

      setState(() {
        _testResult = success
            ? '✓ Connessione riuscita!'
            : '✗ Connessione fallita';
      });
    } catch (e) {
      setState(() {
        _testResult = '✗ Errore: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final config = _buildConfig();
      await ref.read(connectionProvider.notifier).connect(config);

      // Salva la connessione se richiesto
      if (_saveConnection) {
        await _saveCurrentConnection();
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.wizard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore connessione: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _saveCurrentConnection() async {
    final connectionName = _connectionNameController.text.trim().isNotEmpty
        ? _connectionNameController.text.trim()
        : '${_databaseController.text}@${_hostController.text}';
    
    final connection = SavedConnection(
      id: _selectedConnection?.id ?? SavedConnection.generateId(),
      name: connectionName,
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? 3306,
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      database: _databaseController.text.trim(),
      useSSL: _useSSL,
      createdAt: _selectedConnection?.createdAt ?? DateTime.now(),
      lastUsedAt: DateTime.now(),
    );
    
    await _secureStorage.saveConnection(connection);
    await _secureStorage.saveLastConnection(connection.id);
    await _loadSavedConnections();
  }

  Future<void> _deleteConnection(SavedConnection connection) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina connessione'),
        content: Text('Vuoi eliminare la connessione "${connection.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _secureStorage.deleteConnection(connection.id);
      await _loadSavedConnections();
      if (_selectedConnection?.id == connection.id) {
        _clearForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Pannello sinistro con illustrazione
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storage_rounded,
                        size: 100,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'ChatDB-AI',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Interroga il tuo database\ncon il linguaggio naturale',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      _buildFeatureItem(Icons.security, 'Connessione sicura'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.visibility_off, 'Solo lettura'),
                      const SizedBox(height: 16),
                      _buildFeatureItem(Icons.psychology, 'AI multi-provider'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Pannello destro con form
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Connetti al Database',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Inserisci i dati di connessione MySQL',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),

                        // Connessioni salvate
                        if (_savedConnections.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.bookmark, size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Connessioni salvate',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: _clearForm,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Nuova'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _savedConnections.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final conn = _savedConnections[index];
                                final isSelected = _selectedConnection?.id == conn.id;
                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  leading: Icon(
                                    Icons.storage,
                                    color: isSelected ? theme.colorScheme.primary : null,
                                  ),
                                  title: Text(conn.name),
                                  subtitle: Text(
                                    '${conn.username}@${conn.host}:${conn.port}/${conn.database}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () => _deleteConnection(conn),
                                    tooltip: 'Elimina',
                                  ),
                                  onTap: () => _loadConnectionToForm(conn),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                        ],

                        // Nome connessione (opzionale)
                        TextFormField(
                          controller: _connectionNameController,
                          decoration: InputDecoration(
                            labelText: 'Nome connessione (opzionale)',
                            hintText: 'es. Server Produzione',
                            prefixIcon: const Icon(Icons.label_outline),
                            suffixIcon: Tooltip(
                              message: 'Un nome per identificare questa connessione',
                              child: Icon(Icons.info_outline, 
                                size: 18, 
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Host e Porta
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _hostController,
                                decoration: const InputDecoration(
                                  labelText: 'Host',
                                  prefixIcon: Icon(Icons.dns),
                                  hintText: 'localhost',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Inserisci l\'host';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _portController,
                                decoration: const InputDecoration(
                                  labelText: 'Porta',
                                  hintText: '3306',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Richiesto';
                                  }
                                  final port = int.tryParse(value);
                                  if (port == null || port < 1 || port > 65535) {
                                    return 'Non valida';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Username
                        TextFormField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci lo username';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci la password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Database
                        TextFormField(
                          controller: _databaseController,
                          decoration: const InputDecoration(
                            labelText: 'Database',
                            prefixIcon: Icon(Icons.folder),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Inserisci il nome del database';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // SSL Switch
                        SwitchListTile(
                          value: _useSSL,
                          onChanged: (value) {
                            setState(() {
                              _useSSL = value;
                            });
                          },
                          title: const Text('Usa SSL'),
                          subtitle: const Text('Connessione crittografata'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),

                        // Risultato test
                        if (_testResult != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _testResult!.startsWith('✓')
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _testResult!.startsWith('✓')
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            child: Text(
                              _testResult!,
                              style: TextStyle(
                                color: _testResult!.startsWith('✓')
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Checkbox salva connessione
                        CheckboxListTile(
                          value: _saveConnection,
                          onChanged: (value) {
                            setState(() {
                              _saveConnection = value ?? true;
                            });
                          },
                          title: const Text('Salva questa connessione'),
                          subtitle: const Text('I dati verranno salvati in modo sicuro'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),

                        // Pulsanti
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isTesting ? null : _testConnection,
                                icon: _isTesting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.wifi_tethering),
                                label: const Text('Test Connessione'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isConnecting ? null : _connect,
                                icon: _isConnecting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login),
                                label: const Text('Connetti'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

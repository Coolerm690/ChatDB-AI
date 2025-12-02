import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/routes.dart';
import '../../models/llm_config.dart';
import '../../providers/chat_provider.dart';
import '../../providers/settings_provider.dart';

/// Schermata impostazioni applicazione e configurazione LLM
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controller per i vari provider
  final Map<LLMProvider, TextEditingController> _apiKeyControllers = {};
  final Map<LLMProvider, TextEditingController> _endpointControllers = {};
  final Map<LLMProvider, TextEditingController> _modelControllers = {};

  LLMProvider _selectedProvider = LLMProvider.openai;
  bool _obscureApiKeys = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Inizializza i controller per ogni provider
    for (final provider in LLMProvider.values) {
      _apiKeyControllers[provider] = TextEditingController();
      _endpointControllers[provider] =
          TextEditingController(text: provider.defaultEndpoint);
      _modelControllers[provider] = TextEditingController(
        text: provider.defaultModels.isNotEmpty
            ? provider.defaultModels.first
            : '',
      );
    }

    // Carica le impostazioni salvate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final settings = ref.read(settingsProvider);
    
    if (settings.llmConfig != null) {
      final config = settings.llmConfig!;
      setState(() {
        _selectedProvider = config.provider;
      });
      
      _apiKeyControllers[config.provider]?.text = config.apiKey ?? '';
      _endpointControllers[config.provider]?.text = config.endpoint ?? '';
      _modelControllers[config.provider]?.text = config.model;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _apiKeyControllers.values) {
      controller.dispose();
    }
    for (final controller in _endpointControllers.values) {
      controller.dispose();
    }
    for (final controller in _modelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final config = LLMConfig(
      provider: _selectedProvider,
      apiKey: _apiKeyControllers[_selectedProvider]?.text,
      endpoint: _endpointControllers[_selectedProvider]?.text ??
          _selectedProvider.defaultEndpoint,
      model: _modelControllers[_selectedProvider]?.text ??
          _selectedProvider.defaultModels.first,
    );

    try {
      await ref.read(settingsProvider.notifier).saveLLMConfig(config);
      
      // Aggiorna il badge nella chat
      ref.read(chatProvider.notifier).refreshLLMProvider();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impostazioni salvate'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore salvataggio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    final config = LLMConfig(
      provider: _selectedProvider,
      apiKey: _apiKeyControllers[_selectedProvider]?.text,
      endpoint: _endpointControllers[_selectedProvider]?.text ??
          _selectedProvider.defaultEndpoint,
      model: _modelControllers[_selectedProvider]?.text ??
          _selectedProvider.defaultModels.first,
    );

    try {
      final success =
          await ref.read(settingsProvider.notifier).testLLMConnection(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Connessione riuscita!'
                : 'Connessione fallita'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed(AppRoutes.chat);
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.psychology), text: 'LLM Provider'),
            Tab(icon: Icon(Icons.storage), text: 'Database'),
            Tab(icon: Icon(Icons.info), text: 'Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLLMTab(theme),
          _buildDatabaseTab(theme, settings),
          _buildInfoTab(theme),
        ],
      ),
    );
  }

  Widget _buildLLMTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurazione Provider LLM',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Seleziona e configura il provider AI per le query in linguaggio naturale',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Selezione provider
          Text(
            'Provider',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: LLMProvider.values.map((provider) {
              final isSelected = _selectedProvider == provider;
              return ChoiceChip(
                label: Text(provider.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedProvider = provider;
                    });
                  }
                },
                avatar: Icon(
                  _getProviderIcon(provider),
                  size: 18,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Configurazione provider selezionato
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getProviderIcon(_selectedProvider),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedProvider.displayName,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // API Key (se richiesta)
                  if (_selectedProvider.requiresApiKey) ...[
                    TextField(
                      controller: _apiKeyControllers[_selectedProvider],
                      obscureText: _obscureApiKeys,
                      decoration: InputDecoration(
                        labelText: 'API Key',
                        helperText: 'La chiave verrà salvata in modo sicuro',
                        prefixIcon: const Icon(Icons.key),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureApiKeys
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureApiKeys = !_obscureApiKeys;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Endpoint
                  TextField(
                    controller: _endpointControllers[_selectedProvider],
                    decoration: InputDecoration(
                      labelText: 'Endpoint',
                      helperText: _selectedProvider.requiresApiKey
                          ? 'URL dell\'API del provider'
                          : 'URL del server locale (es: http://localhost:11434)',
                      prefixIcon: const Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Modello
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _modelControllers[_selectedProvider],
                          decoration: const InputDecoration(
                            labelText: 'Modello',
                            helperText: 'Nome del modello da utilizzare',
                            prefixIcon: Icon(Icons.smart_toy),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down),
                        tooltip: 'Modelli disponibili',
                        onSelected: (model) {
                          _modelControllers[_selectedProvider]?.text = model;
                        },
                        itemBuilder: (context) {
                          return _selectedProvider.defaultModels.map((model) {
                            return PopupMenuItem(
                              value: model,
                              child: Text(model),
                            );
                          }).toList();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info provider
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Informazioni',
                              style: theme.textTheme.labelLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          'Max Token',
                          '${_selectedProvider.maxContextTokens}',
                        ),
                        if (_selectedProvider.supportsReasoning)
                          _buildInfoRow('Reasoning', 'Supportato'),
                        _buildInfoRow(
                          'Autenticazione',
                          _selectedProvider.requiresApiKey
                              ? 'Richiesta'
                              : 'Non richiesta',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pulsanti azioni
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _testConnection,
                icon: const Icon(Icons.wifi_tethering),
                label: const Text('Test Connessione'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save),
                label: const Text('Salva'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatabaseTab(ThemeData theme, SettingsState settings) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configurazione Database',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.storage,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Connessione Attuale',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  if (settings.connectionConfig != null) ...[
                    _buildInfoRow('Host', settings.connectionConfig!.host),
                    _buildInfoRow(
                        'Porta', '${settings.connectionConfig!.port}'),
                    _buildInfoRow(
                        'Database', settings.connectionConfig!.database),
                    _buildInfoRow(
                        'Username', settings.connectionConfig!.username),
                    _buildInfoRow(
                      'SSL',
                      settings.connectionConfig!.useSSL ? 'Attivo' : 'Disattivo',
                    ),
                  ] else
                    const Text('Nessuna connessione configurata'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed(AppRoutes.connection);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifica Connessione'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Opzioni sicurezza
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sicurezza',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  SwitchListTile(
                    value: settings.enableDataMasking,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setDataMasking(value);
                    },
                    title: const Text('Mascheramento Dati'),
                    subtitle: const Text(
                      'Maschera automaticamente dati sensibili nelle risposte',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: settings.enableAuditLog,
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setAuditLog(value);
                    },
                    title: const Text('Audit Logging'),
                    subtitle: const Text(
                      'Registra tutte le query e operazioni',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informazioni',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.storage,
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ChatDB-AI Desktop',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            'Versione 1.0.0',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    'Piattaforma desktop per interrogare database MySQL '
                    'tramite linguaggio naturale utilizzando LLM multipli.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Piattaforma', 'Windows / macOS'),
                  _buildInfoRow('Framework', 'Flutter'),
                  _buildInfoRow('Database', 'MySQL (solo lettura)'),
                  _buildInfoRow(
                    'LLM Supportati',
                    'OpenAI, Anthropic, Perplexity, Ollama, LM Studio',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Licenze e crediti
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Licenze',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Questo software utilizza le seguenti librerie open source:\n'
                    '• flutter_riverpod (MIT)\n'
                    '• mysql_client (MIT)\n'
                    '• flutter_secure_storage (BSD)\n'
                    '• dio (MIT)\n'
                    '• window_manager (MIT)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getProviderIcon(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.openai:
        return Icons.auto_awesome;
      case LLMProvider.anthropic:
        return Icons.psychology;
      case LLMProvider.perplexity:
        return Icons.search;
      case LLMProvider.ollama:
        return Icons.computer;
      case LLMProvider.lmstudio:
        return Icons.science;
      case LLMProvider.llamacpp:
        return Icons.memory;
    }
  }
}

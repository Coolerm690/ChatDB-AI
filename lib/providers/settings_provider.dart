import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/connection_config.dart';
import '../models/llm_config.dart';
import '../services/storage/secure_storage.dart';
import '../services/storage/local_storage.dart';
import '../services/llm/llm_adapter_interface.dart';
import '../services/llm/openai_adapter.dart';
import '../services/llm/anthropic_adapter.dart';
import '../services/llm/perplexity_adapter.dart';
import '../services/llm/local_adapter.dart';

/// Stato delle impostazioni
class SettingsState {
  final LLMConfig? llmConfig;
  final ConnectionConfig? connectionConfig;
  final bool enableDataMasking;
  final bool enableAuditLog;
  final String theme;
  final bool isLoading;
  final String? error;

  const SettingsState({
    this.llmConfig,
    this.connectionConfig,
    this.enableDataMasking = true,
    this.enableAuditLog = true,
    this.theme = 'system',
    this.isLoading = false,
    this.error,
  });

  SettingsState copyWith({
    LLMConfig? llmConfig,
    ConnectionConfig? connectionConfig,
    bool? enableDataMasking,
    bool? enableAuditLog,
    String? theme,
    bool? isLoading,
    String? error,
  }) {
    return SettingsState(
      llmConfig: llmConfig ?? this.llmConfig,
      connectionConfig: connectionConfig ?? this.connectionConfig,
      enableDataMasking: enableDataMasking ?? this.enableDataMasking,
      enableAuditLog: enableAuditLog ?? this.enableAuditLog,
      theme: theme ?? this.theme,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier per la gestione delle impostazioni
class SettingsNotifier extends StateNotifier<SettingsState> {
  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;

  SettingsNotifier(this._secureStorage, this._localStorage)
      : super(const SettingsState()) {
    _loadSettings();
  }

  /// Carica le impostazioni salvate
  Future<void> _loadSettings() async {
    try {
      state = state.copyWith(isLoading: true);

      // Carica impostazioni generali da file JSON
      final settings = await _localStorage.loadJson('settings');

      // Carica ultimo provider LLM usato
      final lastProviderName = await _secureStorage.getLastProvider();
      LLMConfig? llmConfig;
      
      if (lastProviderName != null) {
        final provider = LLMProvider.values.firstWhere(
          (p) => p.name == lastProviderName,
          orElse: () => LLMProvider.openai,
        );
        
        // Carica API key per questo provider
        final apiKey = await _secureStorage.getApiKey(provider.name);
        
        // Carica modello salvato o usa default
        final savedModel = await _localStorage.getString('llm_model_${provider.name}');
        
        llmConfig = LLMConfig(
          provider: provider,
          apiKey: apiKey,
          model: savedModel ?? provider.defaultModels.first,
        );
      }

      state = state.copyWith(
        enableDataMasking: settings?['enableDataMasking'] ?? true,
        enableAuditLog: settings?['enableAuditLog'] ?? true,
        theme: settings?['theme'] ?? 'system',
        llmConfig: llmConfig,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Errore caricamento impostazioni: $e',
      );
    }
  }

  /// Salva la configurazione LLM
  Future<void> saveLLMConfig(LLMConfig config) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Salva API key in modo sicuro
      final apiKey = config.apiKey;
      if (apiKey != null && apiKey.isNotEmpty) {
        await _secureStorage.saveApiKey(config.provider.name, apiKey);
      }

      // Salva ultimo provider usato
      await _secureStorage.saveLastProvider(config.provider.name);
      
      // Salva modello selezionato
      await _localStorage.saveString('llm_model_${config.provider.name}', config.model);

      state = state.copyWith(
        llmConfig: config,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Errore salvataggio configurazione LLM: $e',
      );
      rethrow;
    }
  }

  /// Testa la connessione LLM
  Future<bool> testLLMConnection(LLMConfig config) async {
    try {
      final adapter = _getAdapter(config.provider);
      await adapter.initialize(config);
      final apiKey = config.apiKey;
      if (apiKey == null || apiKey.isEmpty) {
        return false;
      }
      return await adapter.validateApiKey(apiKey);
    } catch (e) {
      return false;
    }
  }

  /// Ottiene l'adapter appropriato per il provider
  LLMAdapterInterface _getAdapter(LLMProvider provider) {
    switch (provider) {
      case LLMProvider.openai:
        return OpenAIAdapter();
      case LLMProvider.anthropic:
        return AnthropicAdapter();
      case LLMProvider.perplexity:
        return PerplexityAdapter();
      case LLMProvider.ollama:
      case LLMProvider.lmstudio:
      case LLMProvider.llamacpp:
        return LocalAdapter();
    }
  }

  /// Abilita/disabilita il mascheramento dati
  Future<void> setDataMasking(bool enabled) async {
    state = state.copyWith(enableDataMasking: enabled);
    await _saveSettings();
  }

  /// Abilita/disabilita l'audit log
  Future<void> setAuditLog(bool enabled) async {
    state = state.copyWith(enableAuditLog: enabled);
    await _saveSettings();
  }

  /// Imposta il tema
  Future<void> setTheme(String theme) async {
    state = state.copyWith(theme: theme);
    await _saveSettings();
  }

  /// Salva le impostazioni generali
  Future<void> _saveSettings() async {
    try {
      await _localStorage.saveJson('settings', {
        'enableDataMasking': state.enableDataMasking,
        'enableAuditLog': state.enableAuditLog,
        'theme': state.theme,
      });
    } catch (e) {
      state = state.copyWith(error: 'Errore salvataggio impostazioni: $e');
    }
  }

  /// Esporta tutte le impostazioni
  Future<Map<String, dynamic>> exportSettings() async {
    return {
      'llmProvider': state.llmConfig?.provider.name,
      'llmModel': state.llmConfig?.model,
      'llmEndpoint': state.llmConfig?.endpoint,
      'enableDataMasking': state.enableDataMasking,
      'enableAuditLog': state.enableAuditLog,
      'theme': state.theme,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  /// Ripristina le impostazioni di default
  Future<void> resetToDefaults() async {
    try {
      await _secureStorage.deleteAll();
      await _localStorage.deleteJson('settings');

      state = const SettingsState();
    } catch (e) {
      state = state.copyWith(error: 'Errore reset impostazioni: $e');
    }
  }

  /// Pulisce l'errore
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider per lo storage sicuro (impostazioni)
final settingsSecureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Provider per lo storage locale (impostazioni)
final settingsLocalStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

/// Provider per lo stato delle impostazioni
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final secureStorage = ref.watch(settingsSecureStorageProvider);
  final localStorage = ref.watch(settingsLocalStorageProvider);
  return SettingsNotifier(secureStorage, localStorage);
});

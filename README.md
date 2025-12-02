# ChatDB-AI Desktop

Piattaforma desktop multipiattaforma (Windows + macOS) per interrogare database MySQL tramite linguaggio naturale utilizzando LLM multipli.

## 🚀 Caratteristiche

- **Connessione MySQL sicura** - Solo lettura, con crittografia SSL opzionale
- **Schema Wizard** - Modellazione semantica di tabelle e colonne
- **Chat AI** - Interroga il database con linguaggio naturale
- **Multi-LLM** - Supporto per OpenAI, Anthropic, Perplexity, Ollama, LM Studio, llama.cpp
- **Sicurezza** - Mascheramento dati sensibili, audit logging, storage crittografato

## 📋 Prerequisiti

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Per Windows: Visual Studio con "Desktop development with C++"
- Per macOS: Xcode con Command Line Tools

## 🛠️ Installazione

1. **Clona il repository**
```bash
git clone <repository-url>
cd ChatDB-AI
```

2. **Installa le dipendenze**
```bash
flutter pub get
```

3. **Esegui l'applicazione**
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

4. **Build per produzione**
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## 📁 Struttura Progetto

```
lib/
├── main.dart                 # Entry point
├── config/                   # Configurazioni app
│   ├── app_config.dart
│   ├── theme_config.dart
│   └── routes.dart
├── models/                   # Modelli dati
│   ├── connection_config.dart
│   ├── table_model.dart
│   ├── column_model.dart
│   ├── schema_model.dart
│   ├── chat_message.dart
│   ├── chat_session.dart
│   └── llm_config.dart
├── providers/                # State management (Riverpod)
│   ├── connection_provider.dart
│   ├── schema_provider.dart
│   ├── chat_provider.dart
│   └── settings_provider.dart
├── services/                 # Business logic
│   ├── database/
│   ├── llm/
│   ├── storage/
│   ├── chat/
│   └── security/
├── screens/                  # UI Screens
│   ├── splash_screen.dart
│   ├── connection/
│   ├── wizard/
│   ├── chat/
│   └── settings/
└── widgets/                  # Componenti riutilizzabili
    └── chat/
```

## 🔧 Configurazione

### Provider LLM

Vai in **Impostazioni > LLM Provider** e configura:

| Provider | API Key | Endpoint |
|----------|---------|----------|
| OpenAI | Richiesta | https://api.openai.com/v1 |
| Anthropic | Richiesta | https://api.anthropic.com/v1 |
| Perplexity | Richiesta | https://api.perplexity.ai |
| Ollama | Non richiesta | http://localhost:11434 |
| LM Studio | Non richiesta | http://localhost:1234 |
| llama.cpp | Non richiesta | http://localhost:8080 |

### Connessione Database

- Inserisci host, porta, username, password e nome database
- Abilita SSL per connessioni sicure
- L'applicazione usa **solo query SELECT** (read-only)

## 🔒 Sicurezza

- **Credenziali crittografate** - API keys e password salvate con:
  - Windows: DPAPI
  - macOS: Keychain
- **Query validation** - Solo SELECT, no modifiche
- **Data masking** - Mascheramento automatico dati sensibili
- **Audit logging** - Log completo delle operazioni

## 📱 Workflow

1. **Connessione** - Configura la connessione MySQL
2. **Wizard** - Seleziona e descrivi tabelle/colonne
3. **Chat** - Fai domande in linguaggio naturale
4. **Risultati** - Visualizza query SQL e risultati

## 🧩 Provider LLM Locali

### Ollama
```bash
# Installa Ollama
# Scarica un modello
ollama pull llama3.1

# Avvia il server
ollama serve
```

### LM Studio
1. Scarica LM Studio
2. Scarica un modello (es: CodeLlama, Mistral)
3. Avvia il server locale

## 📝 Note

- Le connessioni database sono **solo in lettura**
- Le query vengono validate prima dell'esecuzione
- I dati sensibili vengono mascherati nelle risposte
- Tutte le operazioni vengono loggate per audit

## 📄 Licenza

MIT License - Vedi [LICENSE](LICENSE) per dettagli.

## 🤝 Contributi

Pull request benvenute! Per modifiche importanti, apri prima un issue.

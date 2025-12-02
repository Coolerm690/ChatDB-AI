# ChatDB-AI Desktop - Copilot Instructions

## Project Overview
ChatDB-AI Desktop è una piattaforma desktop multipiattaforma (Windows + macOS) sviluppata in Flutter per interrogare database MySQL tramite linguaggio naturale utilizzando LLM multipli.

## Architecture
- **Frontend**: Flutter Desktop (Windows/macOS)
- **Backend**: Dart services integrati
- **State Management**: Riverpod
- **Database**: MySQL (read-only)
- **LLM Providers**: OpenAI, Anthropic, Perplexity, Ollama (local)

## Key Features
1. Connessione database MySQL (solo lettura)
2. Wizard modellazione schema con descrizioni semantiche
3. Chatbot per query in linguaggio naturale
4. Supporto multipli provider LLM
5. Storage sicuro per API keys e credenziali
6. Masking dati sensibili
7. Audit logging

## Project Structure
```
lib/
├── main.dart
├── config/
│   ├── app_config.dart
│   ├── theme_config.dart
│   └── routes.dart
├── models/
│   ├── connection_config.dart
│   ├── table_model.dart
│   ├── column_model.dart
│   ├── schema_model.dart
│   ├── chat_message.dart
│   ├── chat_session.dart
│   └── llm_config.dart
├── providers/
│   ├── connection_provider.dart
│   ├── schema_provider.dart
│   ├── chat_provider.dart
│   └── settings_provider.dart
├── services/
│   ├── database/
│   │   ├── mysql_service.dart
│   │   └── schema_reader.dart
│   ├── llm/
│   │   ├── llm_adapter_interface.dart
│   │   ├── openai_adapter.dart
│   │   ├── anthropic_adapter.dart
│   │   ├── perplexity_adapter.dart
│   │   └── local_adapter.dart
│   ├── storage/
│   │   ├── local_storage.dart
│   │   └── secure_storage.dart
│   ├── chat/
│   │   ├── chat_engine.dart
│   │   └── prompt_builder.dart
│   └── security/
│       ├── audit_logger.dart
│       ├── data_masking.dart
│       └── query_validator.dart
├── screens/
│   ├── splash_screen.dart
│   ├── connection/
│   │   └── connection_screen.dart
│   ├── wizard/
│   │   ├── wizard_screen.dart
│   │   └── steps/
│   ├── chat/
│   │   └── chat_screen.dart
│   └── settings/
│       └── settings_screen.dart
└── widgets/
    ├── common/
    ├── connection/
    ├── wizard/
    └── chat/
```

## Development Rules
- Usa connessioni MySQL read-only
- Non generare query INSERT, UPDATE, DELETE
- Maschera i dati sensibili nelle risposte
- Salva le API keys in modo sicuro
- Logga tutte le operazioni per audit

## Coding Standards
- Usa Riverpod per state management
- Segui le convenzioni Dart/Flutter
- Documenta le funzioni pubbliche
- Gestisci gli errori appropriatamente

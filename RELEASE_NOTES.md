# ChatDB-AI Desktop v1.0.0

## 🚀 Prima Release Ufficiale

**Data rilascio:** 2 Dicembre 2025

ChatDB-AI Desktop è una piattaforma desktop per Windows che permette di interrogare database MySQL utilizzando il linguaggio naturale tramite LLM multipli.

---

## ✨ Funzionalità Principali

### 🔌 Connessione Database
- Connessione sicura a database MySQL
- Supporto SSL opzionale
- Salvataggio credenziali crittografato
- Gestione connessioni multiple salvate

### 🧙 Wizard Modellazione Schema
- Lettura automatica dello schema database
- Configurazione descrizioni semantiche per tabelle e colonne
- Marcatura campi sensibili per data masking
- Persistenza configurazione schema

### 💬 Chat AI per Query
- Interfaccia chat intuitiva
- Conversione linguaggio naturale → SQL
- Esecuzione query in tempo reale
- Visualizzazione risultati in tabella
- Cronologia conversazioni

### 🤖 Provider LLM Supportati
- **Perplexity AI** (sonar, sonar-pro, sonar-reasoning)
- **OpenAI** (GPT-4, GPT-4 Turbo, GPT-3.5)
- **Anthropic** (Claude 3 Opus, Sonnet, Haiku)
- **Ollama** (modelli locali)
- **LM Studio** (modelli locali)
- **llama.cpp** (modelli locali)

### 🔒 Sicurezza
- Solo query SELECT (read-only)
- Validazione query SQL
- Data masking per campi sensibili
- Storage sicuro per API keys e password
- Audit logging

---

## 📦 Installazione

1. Scarica `ChatDB-AI-Windows-v1.0.0.zip`
2. Estrai il contenuto in una cartella a piacere
3. Esegui `chatdb_ai.exe`

### Requisiti di Sistema
- Windows 10/11 (64-bit)
- Connessione internet (per LLM cloud)
- Accesso a un database MySQL

---

## 🛠️ Configurazione Rapida

1. **Connessione Database**: Inserisci host, porta, username, password e database MySQL
2. **Wizard Schema**: Configura le descrizioni delle tabelle per migliorare le risposte AI
3. **Configura LLM**: Clicca sul badge "Non configurato" e inserisci la tua API key
4. **Inizia a chattare**: Fai domande in italiano sul tuo database!

---

## 📝 Note Tecniche

- **Framework**: Flutter Desktop
- **Linguaggio**: Dart
- **State Management**: Riverpod
- **Database Client**: mysql_client
- **Storage Sicuro**: flutter_secure_storage

---

## ⚠️ Limitazioni Nota

- Solo database MySQL supportato (PostgreSQL in roadmap)
- Solo piattaforma Windows in questa release (macOS in roadmap)
- Richiede API key per provider cloud (Perplexity, OpenAI, Anthropic)

---

## 🐛 Segnalazione Bug

Segnala eventuali bug su: https://github.com/Coolerm690/ChatDB-AI/issues

---

## 📄 Licenza

MIT License

---

**Buon utilizzo di ChatDB-AI!** 🎉

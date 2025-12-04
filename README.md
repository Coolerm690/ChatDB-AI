# ChatDB-AI Desktop

A cross-platform desktop application (Windows + macOS) for querying MySQL databases using natural language powered by multiple LLM providers.

## 🚀 Features

- **Secure MySQL Connection** - Read-only access with optional SSL encryption
- **Schema Wizard** - Semantic modeling of tables and columns
- **AI Chat** - Query your database using natural language
- **Multi-LLM Support** - OpenAI, Anthropic, Perplexity, Ollama, LM Studio, llama.cpp
- **Security First** - Sensitive data masking, audit logging, encrypted storage

## 📋 Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- For Windows: Visual Studio with "Desktop development with C++"
- For macOS: Xcode with Command Line Tools

## 🛠️ Installation

1. **Clone the repository**
```bash
git clone https://github.com/Coolerm690/ChatDB-AI.git
cd ChatDB-AI
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the application**
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

4. **Build for production**
```bash
# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## 📁 Project Structure

```
lib/
├── main.dart                 # Entry point
├── config/                   # App configurations
│   ├── app_config.dart
│   ├── theme_config.dart
│   └── routes.dart
├── models/                   # Data models
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
└── widgets/                  # Reusable components
    └── chat/
```

## 🔧 Configuration

### LLM Providers

Go to **Settings > LLM Provider** and configure:

| Provider | API Key | Endpoint |
|----------|---------|----------|
| OpenAI | Required | https://api.openai.com/v1 |
| Anthropic | Required | https://api.anthropic.com/v1 |
| Perplexity | Required | https://api.perplexity.ai |
| Ollama | Not required | http://localhost:11434 |
| LM Studio | Not required | http://localhost:1234 |
| llama.cpp | Not required | http://localhost:8080 |

### Database Connection

- Enter host, port, username, password, and database name
- Enable SSL for secure connections
- The application uses **only SELECT queries** (read-only)

## 🔒 Security

- **Encrypted Credentials** - API keys and passwords stored securely:
  - Windows: DPAPI
  - macOS: Keychain
- **Query Validation** - Only SELECT statements, no modifications
- **Data Masking** - Automatic masking of sensitive data
- **Audit Logging** - Complete operation logging

## 📱 Workflow

1. **Connection** - Configure MySQL database connection
2. **Wizard** - Select and describe tables/columns
3. **Chat** - Ask questions in natural language
4. **Results** - View SQL queries and results

## 🧩 Local LLM Providers

### Ollama
```bash
# Install Ollama
# Download a model
ollama pull llama3.1

# Start the server
ollama serve
```

### LM Studio
1. Download LM Studio
2. Download a model (e.g., CodeLlama, Mistral)
3. Start the local server

## 📝 Notes

- Database connections are **read-only**
- Queries are validated before execution
- Sensitive data is masked in responses
- All operations are logged for audit purposes

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Ways to Contribute

- 🐛 **Report bugs** - Open an issue with detailed information
- 💡 **Suggest features** - Share your ideas for improvements
- 📖 **Improve documentation** - Help make our docs better
- 🔧 **Submit pull requests** - Fix bugs or implement new features

### Development Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the project's coding standards
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Standards

- Follow Dart/Flutter conventions
- Document public functions
- Handle errors appropriately
- Use Riverpod for state management
- Write clean, maintainable code

### Questions?

Feel free to open an issue for any questions or discussions about contributing.

## ☕ Support the Project

If you find ChatDB-AI useful and want to support its development, consider buying me a coffee!

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Support-yellow?style=for-the-badge&logo=buy-me-a-coffee)](https://www.paypal.com/paypalme/giuseppeitaliano1?country.x=IT&locale.x=it_IT)

Your support helps maintain and improve ChatDB-AI. Thank you! 💙

---

Made with ❤️ by [Giuseppe Italiano](https://github.com/Coolerm690)
## 📄 License

[MIT License](LICENSE) - Free to use, modify, and distribute.

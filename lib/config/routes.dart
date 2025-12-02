import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/connection/connection_screen.dart';
import '../screens/wizard/wizard_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/settings/settings_screen.dart';

/// Definizione delle routes dell'applicazione
class AppRoutes {
  AppRoutes._();

  // Route names
  static const String splash = '/';
  static const String connection = '/connection';
  static const String wizard = '/wizard';
  static const String chat = '/chat';
  static const String settings = '/settings';

  /// Genera la route basata sul nome
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case connection:
        return _buildRoute(const ConnectionScreen(), settings);

      case wizard:
        return _buildRoute(const WizardScreen(), settings);

      case chat:
        return _buildRoute(const ChatScreen(), settings);

      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);

      default:
        return _buildRoute(
          Scaffold(
            body: Center(
              child: Text('Route non trovata: ${settings.name}'),
            ),
          ),
          settings,
        );
    }
  }

  /// Costruisce una route con transizione
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        final tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/session_store.dart';
import '../main_shell/main_shell.dart';
import '../welcome_screen/welcome_screen.dart';

class AppStartupScreen extends StatefulWidget {
  const AppStartupScreen({super.key});

  @override
  State<AppStartupScreen> createState() => _AppStartupScreenState();
}

class _AppStartupScreenState extends State<AppStartupScreen> {
  Widget? _destination;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final sessionId = await SessionStore.getSessionId();
    if (sessionId == null || sessionId.isEmpty) {
      _show(const WelcomeScreen());
      return;
    }

    try {
      final isValid = await AuthService().verifySession(sessionId);
      if (isValid) {
        AuthSession.accessToken = await SessionStore.getAccessToken();
        _show(const MainShell());
        return;
      }
    } catch (_) {
      // A session that cannot be verified must not bypass authentication.
    }

    await SessionStore.clear();
    AuthSession.accessToken = null;
    _show(const WelcomeScreen());
  }

  void _show(Widget destination) {
    if (mounted) setState(() => _destination = destination);
  }

  @override
  Widget build(BuildContext context) {
    return _destination ??
        const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFB8490C)),
          ),
        );
  }
}

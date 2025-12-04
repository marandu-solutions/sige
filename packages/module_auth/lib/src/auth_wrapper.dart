import 'package:flutter/material.dart';
import 'package:module_auth/login_screen.dart';
import 'package:module_auth/src/auth_service.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  AuthStatus? _lastStatus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = context.watch<AuthService>();
    print(
        'AuthWrapper: Reconstruído com status: ${authService.status}, userData: ${authService.userData != null}');
    if (authService.status == AuthStatus.authenticated &&
        authService.userData != null &&
        _lastStatus != AuthStatus.authenticated) {
      _lastStatus = AuthStatus.authenticated;
      print('AuthWrapper: Navegando para /homepage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/homepage', arguments: {
          'userData': authService.userData,
          'tenantData': authService.tenantData,
        });
      });
    } else {
      _lastStatus = authService.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    if (authService.status != AuthStatus.authenticated) {
      return const LoginScreen();
    }
    // Enquanto navega, retorna um widget vazio
    return const SizedBox.shrink();
  }
}

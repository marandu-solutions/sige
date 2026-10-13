import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import 'auth_service.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    ref.listen(authServiceProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated && next.userData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/homepage', arguments: {
            'userData': next.userData,
            'tenantData': next.tenantData,
          });
        });
      }
    });

    if (authService.status == AuthStatus.authenticated) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return const LoginScreen();
    }
  }
}

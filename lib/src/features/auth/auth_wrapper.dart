import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import 'auth_service.dart';
import '../../shell/home_page/home_page.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);

    if (authService.status == AuthStatus.authenticated && authService.userData != null) {
      return HomePage(
        userData: authService.userData,
        tenantData: authService.tenantData,
      );
    } else if (authService.status == AuthStatus.authenticating ||
               authService.status == AuthStatus.uninitialized) {
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

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/core/routes/app_routes.dart';
import 'package:sige/src/core/core.dart';
import 'package:sige/src/features/auth/auth_service.dart';
import 'package:sige/src/features/auth/auth_wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final corHex = authService.tenantData?['branding']?['cor_primaria'] as String?;
    final seedColor = corHex != null ? SigeColors.fromHex(corHex) : null;

    return MaterialApp(
      title: 'SIGE - Sistema Integrado de Gestão Empresarial',
      debugShowCheckedModeBanner: false,
      theme: SigeTheme.light(seedColor: seedColor),
      darkTheme: SigeTheme.dark(seedColor: seedColor),
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

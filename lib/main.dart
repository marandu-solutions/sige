import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:sige/src/core/routes/app_routes.dart';
import 'package:sige/src/core/theme/app_theme.dart';
import 'package:module_auth/src/auth_service.dart';
import 'package:module_auth/src/auth_wrapper.dart';
import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final auth = FirebaseAuth.instance;
  final initialRoute = auth.currentUser == null
      ? AppRoutes.login
      : AppRoutes.homepage;

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: initialRoute,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

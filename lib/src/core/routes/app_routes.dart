import 'package:flutter/material.dart';
import 'package:sige/src/shell/home_page/home_page.dart';

import 'package:module_auth/login_screen.dart';
import 'package:module_basic_dashboard/module_basic_dashboard.dart';
import 'package:module_estoque/module_estoque.dart';
import 'package:module_kanban/module_kanban.dart';
import 'package:module_atendimento/module_atendimento.dart';

class AppRoutes {
  static const String homepage = '/homepage';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String estoque = '/estoque';
  static const String kanban = '/kanban';
  static const String atendimento = '/atendimento';

  // Mapa de módulos disponíveis
  // Mapa de módulos disponíveis
  static Map<String, Widget> modulosDisponiveis(String tenantId) => {
    'module_basic_dashboard': const DashboardScreen(),
    'module_estoque': EstoqueScreen(tenantId: tenantId),
    'module_kanban': KanbanScreen(tenantId: tenantId),
    'module_atendimento': AtendimentoScreen(tenantId: tenantId),
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case homepage:
        return MaterialPageRoute(
          builder: (_) => HomePage(
            userData: args?['userData'],
            tenantData: args?['tenantData'],
          ),
        );
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case estoque:
        if (args != null && args.containsKey('tenantId')) {
          return MaterialPageRoute(
            builder: (_) => EstoqueScreen(tenantId: args['tenantId']),
          );
        }
        return _errorRoute(settings.name);
      case atendimento:
        if (args != null && args.containsKey('tenantId')) {
          return MaterialPageRoute(
            builder: (_) => AtendimentoScreen(tenantId: args['tenantId']),
          );
        }
        return _errorRoute(settings.name);
      case kanban:
        if (args != null && args.containsKey('tenantId')) {
          return MaterialPageRoute(
            builder: (_) => KanbanScreen(tenantId: args['tenantId']),
          );
        }
        return _errorRoute(settings.name);
      default:
        return _errorRoute(settings.name);
    }
  }

  static Route<dynamic> _errorRoute(String? routeName) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text(
            'Nenhuma rota definida para $routeName ou argumentos faltando',
          ),
        ),
      ),
    );
  }
}

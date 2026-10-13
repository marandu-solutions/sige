import 'package:flutter/material.dart';
import 'package:sige/src/shell/home_page/home_page.dart';

import 'package:sige/src/features/auth/login_screen.dart';
import 'package:sige/src/features/auth/auth_wrapper.dart';
import 'package:sige/src/features/dashboard/atendimento_dashboard_screen.dart';
import 'package:sige/src/features/dashboard/dashboard_screen.dart';
import 'package:sige/src/features/estoque/screens/estoque_screen.dart';
import 'package:sige/src/features/atendimento/screens/atendimento_screen.dart';
import 'package:sige/src/features/atendimento/screens/gerente_atendimento_screen.dart';
import 'package:sige/src/features/admin_empresa/src/screens/admin_dashboard_screen.dart';
import 'package:sige/src/features/leads/src/screens/leads_screen.dart';

class AppRoutes {
  static const String root = '/';
  static const String homepage = '/homepage';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String estoque = '/estoque';
  static const String kanban = '/kanban';
  static const String atendimento = '/atendimento';
  static const String adminEmpresa = '/admin_empresa';
  static const String gerenteAtendimento = '/gerente_atendimento';
  static const String leads = '/leads';

  // Mapa de módulos disponíveis - suporta nomes curtos (MD02) e prefixados (legado)
  static Map<String, Widget> modulosDisponiveis(String tenantId) => {
    'atendimento': AtendimentoScreen(tenantId: tenantId),
    'module_atendimento': AtendimentoScreen(tenantId: tenantId),
    'gerente_atendimento': GerenteAtendimentoScreen(tenantId: tenantId),
    'module_gerente_atendimento': GerenteAtendimentoScreen(tenantId: tenantId),
    'estoque': EstoqueScreen(tenantId: tenantId),
    'module_estoque': EstoqueScreen(tenantId: tenantId),
    'leads': LeadsScreen(tenantId: tenantId),
    'module_leads': LeadsScreen(tenantId: tenantId),
    'admin_empresa': AdminDashboardScreen(tenantId: tenantId),
    'module_admin_empresa': AdminDashboardScreen(tenantId: tenantId),
    'dashboard': const AtendimentoDashboardScreen(),
    'module_basic_dashboard': const AtendimentoDashboardScreen(),
  };

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments as Map<String, dynamic>?;

    switch (settings.name) {
      case root:
        return MaterialPageRoute(builder: (_) => const AuthWrapper());
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
      case kanban:
        if (args != null && args.containsKey('tenantId')) {
          return MaterialPageRoute(
            builder: (_) => AtendimentoScreen(tenantId: args['tenantId']),
          );
        }
        return _errorRoute(settings.name);
      case gerenteAtendimento:
        if (args != null && args.containsKey('tenantId')) {
          return MaterialPageRoute(
            builder: (_) =>
                GerenteAtendimentoScreen(tenantId: args['tenantId']),
          );
        }
        return _errorRoute(settings.name);
      case adminEmpresa:
        if (args != null && args.containsKey('tenantId')) {
          return MaterialPageRoute(
            builder: (_) => AdminDashboardScreen(tenantId: args['tenantId']),
          );
        }
        return _errorRoute(settings.name);
      case leads:
        if (args != null && args.containsKey('tenantId')) {
          return MaterialPageRoute(
            builder: (_) => LeadsScreen(tenantId: args['tenantId']),
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

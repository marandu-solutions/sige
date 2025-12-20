import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:module_auth/src/auth_service.dart';
import '../../shell/home_page/components/bottom_nav_bar.dart';
import '../../shell/home_page/components/sidebar.dart';
import 'package:sige/src/core/routes/app_routes.dart';
import 'package:module_basic_dashboard/module_basic_dashboard.dart';
import 'package:module_estoque/module_estoque.dart';
import 'package:module_kanban/module_kanban.dart';

class HomePage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? tenantData;

  const HomePage({super.key, this.userData, this.tenantData});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  ({List<Widget> widgets, List<Map<String, dynamic>> infos}) _calcularModulos(
    AuthService authService,
  ) {
    final tenantId = widget.userData?['tenant_id'] as String? ?? '';
    final mapaModulos = AppRoutes.modulosDisponiveis(tenantId);

    // Lista base: o que a empresa contratou
    List<String> modulosPermitidos = List<String>.from(
      widget.tenantData?['modulos_ativos'] ?? [],
    );
    // Force include module_map for testing
    if (!modulosPermitidos.contains('module_map')) {
      modulosPermitidos.add('module_map');
    }

    // Filtragem por permissão do funcionário
    final role =
        authService.userData?['role']?.toString().toLowerCase() ??
        'funcionario';

    // Se não for admin/dono, filtra pelo acesso delegado
    if (role != 'admin' && role != 'dono') {
      final employeeModules = List<String>.from(
        authService.employeeData?['modulos_acesso'] ?? [],
      );

      // Intersecção: Só mostra o que a empresa tem E o funcionário pode ver
      modulosPermitidos = modulosPermitidos
          .where((m) => employeeModules.contains(m))
          .toList();
    }

    final List<Widget> widgets = [];
    final List<Map<String, dynamic>> infos = [];

    for (final moduloNome in modulosPermitidos) {
      if (mapaModulos.containsKey(moduloNome)) {
        final moduloWidget = mapaModulos[moduloNome]!;
        widgets.add(moduloWidget);

        final metadata = _getModuloMetadata(moduloNome);
        infos.add({
          'titulo': metadata['titulo'] as String,
          'icone': metadata['icone'] as IconData,
        });
      }
    }

    return (widgets: widgets, infos: infos);
  }

  Map<String, dynamic> _getModuloMetadata(String moduloNome) {
    final metadataMap = {
      'module_basic_dashboard': {
        'rota': AppRoutes.dashboard,
        'titulo': 'Dashboard',
        'icone': Icons.dashboard,
      },
      'module_estoque': {
        'rota': AppRoutes.estoque,
        'titulo': 'Estoque',
        'icone': Icons.inventory,
      },
      'module_kanban': {
        'rota': AppRoutes.kanban,
        'titulo': 'Kanban',
        'icone': Icons.view_kanban,
      },
      'module_atendimento': {
        'rota': AppRoutes.atendimento,
        'titulo': 'Atendimento',
        'icone': Icons.chat,
      },
      'module_admin_empresa': {
        'rota': AppRoutes.adminEmpresa,
        'titulo': 'Admin',
        'icone': Icons.admin_panel_settings,
      },
      'module_gerente_atendimento': {
        'rota': AppRoutes.gerenteAtendimento,
        'titulo': 'Gerente',
        'icone': Icons.supervisor_account,
      },
      'module_leads': {
        'rota': AppRoutes.leads,
        'titulo': 'Leads',
        'icone': Icons.contacts,
      },
      'module_map': {
        'rota': AppRoutes.map,
        'titulo': 'Mapa',
        'icone': Icons.map,
      },
    };
    return metadataMap[moduloNome] ?? {};
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _performLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Sistema'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Fecha o diálogo
              await ref.read(authServiceProvider).signOut();
              if (mounted) {
                // Navega para a raiz (AuthWrapper) removendo todas as rotas anteriores
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.root, (route) => false);
              }
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);

    // Se os dados da empresa ainda não chegaram, exibe a tela de carregamento.
    if (widget.tenantData == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando dados...'),
            ],
          ),
        ),
      );
    }

    // Enquanto os dados do usuário não carregam, exibe um placeholder.
    if (authService.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Calcula os módulos permitidos
    final modulosData = _calcularModulos(authService);
    final modulosAtivos = modulosData.widgets;
    final modulosInfo = modulosData.infos;

    // Garante que o índice selecionado seja válido
    if (_selectedIndex >= modulosAtivos.length) {
      _selectedIndex = 0;
    }

    final userName =
        authService.userData?['nome'] ??
        authService.user?.displayName ??
        'Usuário';
    final userEmail =
        authService.userData?['email'] ??
        authService.user?.email ??
        'E-mail não disponível';

    // Se não houver módulos ativos, mostra mensagem
    if (modulosAtivos.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum módulo ativo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Entre em contato com o administrador',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;

        if (isMobile) {
          // --- LAYOUT MOBILE ---
          return Scaffold(
            extendBody: true,
            body: modulosAtivos[_selectedIndex],
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: BottomNavBar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemTapped,
                modulosInfo: modulosInfo,
              ),
            ),
          );
        } else {
          // --- LAYOUT DESKTOP ---
          return Scaffold(
            body: Row(
              children: [
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemTapped,
                  userName: userName,
                  userEmail: userEmail,
                  onLogout: _performLogout,
                  modulosInfo: modulosInfo,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                    child: Card(
                      elevation: 4.0,
                      shadowColor: Colors.black.withOpacity(0.1),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: modulosAtivos[_selectedIndex],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

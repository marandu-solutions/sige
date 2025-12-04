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
  List<Widget> _modulosAtivos = [];
  List<String> _rotasModulos = [];
  List<Map<String, dynamic>> _modulosInfo = [];

  @override
  void initState() {
    super.initState();
    _carregarModulosAtivos();
  }

  void _carregarModulosAtivos() {
    final tenantId = widget.userData?['tenant_id'] as String? ?? '';
    final mapaModulos = AppRoutes.modulosDisponiveis(tenantId);

    final modulosAtivosNomes =
        widget.tenantData?['modulos_ativos'] as List<dynamic>? ?? [];

    _modulosAtivos = [];
    _rotasModulos = [];
    _modulosInfo = [];

    for (final moduloNome in modulosAtivosNomes) {
      if (mapaModulos.containsKey(moduloNome)) {
        final moduloWidget = mapaModulos[moduloNome]!;
        _modulosAtivos.add(moduloWidget);

        // A informação de rota, título e ícone precisa ser gerenciada de outra forma
        // ou o mapa em AppRoutes precisa ser mais complexo.
        // Por simplicidade, vamos manter um mapa local para metadados.
        final metadata = _getModuloMetadata(moduloNome);
        _rotasModulos.add(metadata['rota'] as String);
        _modulosInfo.add({
          'titulo': metadata['titulo'] as String,
          'icone': metadata['icone'] as IconData,
        });
      }
    }
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
    };
    return metadataMap[moduloNome] ?? {};
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _performLogout() {
    ref.read(authServiceProvider).signOut();
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

    // Recarrega os módulos se os dados da empresa chegaram após o initState.
    if (_modulosAtivos.isEmpty && widget.tenantData != null) {
      _carregarModulosAtivos();
    }

    // Enquanto os dados do usuário não carregam, exibe um placeholder.
    if (authService.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
    if (_modulosAtivos.isEmpty) {
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
            body: _modulosAtivos[_selectedIndex],
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              child: BottomNavBar(
                selectedIndex: _selectedIndex,
                onItemSelected: _onItemTapped,
                modulosInfo: _modulosInfo,
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
                  modulosInfo: _modulosInfo,
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
                      child: _modulosAtivos[_selectedIndex],
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

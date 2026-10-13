import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sige/src/features/auth/auth_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../shell/home_page/components/bottom_nav_bar.dart';
import '../../shell/home_page/components/sidebar.dart';
import 'package:sige/src/core/routes/app_routes.dart';

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

    // Filtragem por permissão do usuário
    final role =
        authService.userData?['role']?.toString().toLowerCase() ??
        'funcionario';
    final isManager = role == 'admin' || role == 'dono' || role == 'gerente';

    if (!isManager) {
      final employeeModules = List<String>.from(
        authService.employeeData?['modulos_acesso'] ?? [],
      );

      // Intersecção: Só mostra o que a empresa tem E o funcionário pode ver
      modulosPermitidos = modulosPermitidos
          .where((m) =>
              employeeModules.contains(m) ||
              employeeModules.contains('module_$m') ||
              employeeModules.contains(m.replaceFirst('module_', '')))
          .toList();
    } else {
      // Para gestores (admin/dono/gerente): se a empresa tem atendimento,
      // habilita a tela de Supervisão da Equipe além da tela pessoal de atendimento
      final hasAtendimento = modulosPermitidos
          .any((m) => m.contains('atendimento') || m.contains('kanban'));
      if (hasAtendimento &&
          !modulosPermitidos.contains('gerente_atendimento') &&
          !modulosPermitidos.contains('module_gerente_atendimento')) {
        modulosPermitidos.add('gerente_atendimento');
      }
    }

    final List<Widget> widgets = [];
    final List<Map<String, dynamic>> infos = [];

    for (final moduloNome in modulosPermitidos) {
      final normalized = moduloNome.replaceFirst('module_', '');
      // Remove kanban avulso (já incorporado dentro de Atendimento e Supervisão)
      if (normalized == 'kanban') continue;
      // Funcionário comum não tem acesso à tela de supervisão
      if (!isManager && normalized == 'gerente_atendimento') continue;

      if (mapaModulos.containsKey(moduloNome) || mapaModulos.containsKey(normalized)) {
        final moduloWidget =
            mapaModulos[moduloNome] ?? mapaModulos[normalized]!;
        widgets.add(moduloWidget);

        final metadata = _getModuloMetadata(moduloNome);
        infos.add({
          'titulo': (metadata['titulo'] as String?) ?? moduloNome,
          'icone': (metadata['icone'] as IconData?) ?? Icons.folder,
        });
      }
    }

    return (widgets: widgets, infos: infos);
  }

  Map<String, dynamic> _getModuloMetadata(String moduloNome) {
    final normalized = moduloNome.replaceFirst('module_', '');
    final metadataMap = {
      'dashboard': {
        'rota': AppRoutes.dashboard,
        'titulo': 'Dashboard',
        'icone': LucideIcons.layoutDashboard,
      },
      'basic_dashboard': {
        'rota': AppRoutes.dashboard,
        'titulo': 'Dashboard',
        'icone': LucideIcons.layoutDashboard,
      },
      'estoque': {
        'rota': AppRoutes.estoque,
        'titulo': 'Estoque',
        'icone': LucideIcons.package,
      },
      'atendimento': {
        'rota': AppRoutes.atendimento,
        'titulo': 'Atendimento',
        'icone': LucideIcons.messageSquareQuote,
      },
      'gerente_atendimento': {
        'rota': AppRoutes.gerenteAtendimento,
        'titulo': 'Supervisão',
        'icone': LucideIcons.usersRound,
      },
      'admin_empresa': {
        'rota': AppRoutes.adminEmpresa,
        'titulo': 'Admin',
        'icone': LucideIcons.shieldCheck,
      },
      'leads': {
        'rota': AppRoutes.leads,
        'titulo': 'Leads',
        'icone': LucideIcons.contact2,
      },
    };
    return metadataMap[normalized] ?? metadataMap[moduloNome] ?? {};
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
          final tenantNome = widget.tenantData?['nome_fantasia'] as String? ??
              widget.tenantData?['nome'] as String? ??
              'SIGE Gestão';
          final tenantLogoUrl =
              widget.tenantData?['branding']?['logo_url'] as String?;

          return Scaffold(
            body: Row(
              children: [
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemTapped,
                  userName: userName,
                  userEmail: userEmail,
                  tenantNome: tenantNome,
                  tenantLogoUrl: tenantLogoUrl,
                  onLogout: _performLogout,
                  modulosInfo: modulosInfo,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Theme.of(context).cardColor,
                        child: modulosAtivos[_selectedIndex],
                      ),
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

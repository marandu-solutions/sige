// lib/Pages/HomePage/Components/sidebar.dart
/*
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

// O caminho para o seu AuthService pode precisar de ajuste
import '../../../Service/auth_service.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  // CORREÇÃO: A lista agora reflete a nossa arquitetura final de 5 seções,
  // espelhando perfeitamente a BottomNavBar.
  static const List<Map<String, dynamic>> _navItems = [
    {'icon': LucideIcons.home, 'label': 'Início'},
    {'icon': LucideIcons.receipt, 'label': 'Pedidos'},
    {'icon': LucideIcons.messageSquare, 'label': 'Atendimento'},
    {'icon': LucideIcons.barChart3, 'label': 'Gestão'},
    {'icon': LucideIcons.settings, 'label': 'Configurações'},
  ];

  // A sua lógica de logout já é excelente e foi mantida.
  void _performLogout(BuildContext context) {
    context.read<AuthService>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // O Consumer garante que a UI será reconstruída quando o usuário logar/deslogar.
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Enquanto os dados do funcionário não carregam, exibe um placeholder.
        if (authService.funcionarioLogado == null) {
          return const Drawer(child: Center(child: CircularProgressIndicator()));
        }

        final userName = authService.funcionarioLogado!.nome;
        final userEmail = authService.funcionarioLogado!.email;
        final tt = theme.textTheme;

        return Drawer(
          backgroundColor: cs.surface,
          elevation: 2,
          width: 280, // Largura fixa para a sidebar
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(userName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onPrimary)),
                accountEmail: Text(userEmail, style: tt.bodyMedium?.copyWith(color: cs.onPrimary.withOpacity(0.8))),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: cs.onPrimary,
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: tt.headlineMedium?.copyWith(color: cs.primary),
                  ),
                ),
                decoration: BoxDecoration(color: cs.primary),
              ),

              // Loop para criar os itens de navegação
              for (int i = 0; i < _navItems.length; i++)
                _buildNavItem(
                  context: context,
                  icon: _navItems[i]['icon'],
                  title: _navItems[i]['label'],
                  index: i,
                ),

              const Spacer(),

              // Botão de Sair
              const Divider(thickness: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: Icon(LucideIcons.logOut, color: cs.error),
                  title: Text('Sair', style: tt.labelLarge?.copyWith(color: cs.error, fontWeight: FontWeight.bold)),
                  hoverColor: cs.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => _performLogout(context),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Constrói cada item da lista de navegação.
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: cs.primary.withOpacity(0.1),
        selectedColor: cs.primary,
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () => onItemSelected(index),
      ),
    );
  }
}
*/
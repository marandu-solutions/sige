import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:module_auth/src/auth_service.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/sidebar.dart';

// TODO: Importar a lista de módulos contratados.
// For now, we'll use a placeholder list of widgets.
final List<Widget> _pages = <Widget>[
  Container(
    color: Colors.red,
    child: const Center(child: Text('Módulo 1')),
  ),
  Container(
    color: Colors.green,
    child: const Center(child: Text('Módulo 2')),
  ),
  Container(
    color: Colors.blue,
    child: const Center(child: Text('Módulo 3')),
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _performLogout(BuildContext context) {
    context.read<AuthService>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos o Consumer para obter os dados do usuário do AuthService.
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Enquanto os dados do usuário não carregam, exibe um placeholder.
        if (authService.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userName = authService.user?.displayName ?? 'Usuário';
        final userEmail = authService.user?.email ?? 'E-mail não disponível';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 750;

            if (isMobile) {
              // --- LAYOUT MOBILE ---
              return Scaffold(
                extendBody: true,
                body: _pages[_selectedIndex],
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: BottomNavBar(
                    selectedIndex: _selectedIndex,
                    onItemSelected: _onItemTapped,
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
                      onLogout: () => _performLogout(context),
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
                          child: _pages[_selectedIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}

/*
import 'package:flutter/material.dart';
import '../ConfiguracoesPage/configuracoes_page.dart';
import '../DashboardPage/dashboard_page.dart';
import '../GestaoPage/gestao_page.dart';
import '../PedidosPage/pedidos_page.dart';
import '../AtendimentoPage/atendimento_page.dart';
import 'Components/bottom_nav_bar.dart';
import 'Components/sidebar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // CORREÇÃO: A lista agora reflete a nossa arquitetura final de 5 seções.
  static const List<Widget> _pages = <Widget>[
    DashboardPage(),      // 0: A nova tela de Início/Dashboard
    PedidosPage(),        // 1: Sua página de Pedidos existente
    AtendimentoPage(),    // 2: Sua página de Atendimento existente
    GestaoPage(),         // 3: A nova tela de Gestão
    ConfiguracoesPage(),  // 4: A nova tela de Configurações
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // O ponto de quebra para mobile/desktop foi mantido.
        final isMobile = constraints.maxWidth < 750;

        if (isMobile) {
          // --- LAYOUT MOBILE ---
          return Scaffold(
            // O extendBody permite que a barra flutuante fique sobre o conteúdo.
            extendBody: true,
            body: _pages[_selectedIndex],
            // A barra de navegação flutuante que criamos.
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                // A Sidebar também precisará ser atualizada para 5 seções.
                Sidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onItemTapped,
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
  }
}
*/
/*
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Para este widget funcionar, adicione as seguintes dependências
// no seu arquivo `pubspec.yaml`:
//
// dependencies:
//   google_nav_bar: ^5.0.6
//   lucide_icons: ^0.301.0
//
// E depois execute `flutter pub get` no seu terminal.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BottomNavBar Demo',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

// Página de exemplo para demonstrar a nova BottomNavBar
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  _DemoPageState createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  int _currentIndex = 0;

  // CORREÇÃO: A lista de páginas agora tem 5 itens para corresponder à navbar.
  static const List<Widget> _pages = <Widget>[
    Center(child: Text('Página de Início (Dashboard)')),
    Center(child: Text('Página de Pedidos')),
    Center(child: Text('Página de Atendimento')),
    Center(child: Text('Página de Gestão')),
    Center(child: Text('Página de Configurações')),
  ];

  void _onNavSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Demo"),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Conteúdo principal da página selecionada
          _pages[_currentIndex],

          // A barra de navegação flutuante na parte inferior
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: BottomNavBar(
              selectedIndex: _currentIndex,
              onItemSelected: _onNavSelected,
            ),
          ),
        ],
      ),
    );
  }
}


/// Uma barra de navegação inferior flutuante, moderna e animada,
/// adaptada para a nova arquitetura do aplicativo.
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  // CORREÇÃO: A lista de itens agora reflete a nossa arquitetura final de 5 seções.
  static const List<Map<String, dynamic>> _navItems = [
    {'icon': LucideIcons.home, 'label': 'Início'},
    {'icon': LucideIcons.receipt, 'label': 'Pedidos'},
    {'icon': LucideIcons.messageSquare, 'label': 'Atendimento'},
    {'icon': LucideIcons.barChart3, 'label': 'Gestão'},
    {'icon': LucideIcons.settings, 'label': 'Configurações'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // O Container cria o efeito de "cartão flutuante"
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(.1),
            offset: const Offset(0, 5),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: GNav(
          // Estilização dos botões e da barra.
          rippleColor: theme.colorScheme.primary.withOpacity(0.1),
          hoverColor: theme.colorScheme.primary.withOpacity(0.05),
          gap: 6,
          activeColor: theme.colorScheme.onPrimary,
          iconSize: 22,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(milliseconds: 400),
          tabBackgroundColor: theme.colorScheme.primary,
          color: theme.colorScheme.onSurfaceVariant,

          // Gera as abas (GButton) a partir da nossa nova lista de itens.
          tabs: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            return GButton(
              icon: item['icon'] as IconData,
              text: item['label'] as String,
            );
          }),

          // Controle de estado
          selectedIndex: selectedIndex,
          onTabChange: onItemSelected,
        ),
      ),
    );
  }
}
*/
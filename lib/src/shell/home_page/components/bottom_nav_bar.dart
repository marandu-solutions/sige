import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<Map<String, dynamic>> modulosInfo;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.modulosInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(.1),
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: GNav(
          rippleColor: theme.colorScheme.primary.withOpacity(0.1),
          hoverColor: theme.colorScheme.primary.withOpacity(0.05),
          gap: 6,
          activeColor: theme.colorScheme.onPrimary,
          iconSize: 22,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(milliseconds: 400),
          tabBackgroundColor: theme.colorScheme.primary,
          color: theme.colorScheme.onSurfaceVariant,
          tabs: List.generate(modulosInfo.length, (index) {
            final item = modulosInfo[index];
            return GButton(
              icon: item['icone'] as IconData,
              text: item['titulo'] as String,
            );
          }),
          selectedIndex: selectedIndex,
          onTabChange: onItemSelected,
        ),
      ),
    );
  }
}

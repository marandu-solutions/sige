import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final List<Map<String, dynamic>> modulosInfo;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    required this.modulosInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Drawer(
      backgroundColor: cs.surface,
      elevation: 2,
      width: 280,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              userName,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onPrimary,
              ),
            ),
            accountEmail: Text(
              userEmail,
              style: tt.bodyMedium?.copyWith(
                color: cs.onPrimary.withOpacity(0.8),
              ),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: cs.onPrimary,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: tt.headlineMedium?.copyWith(color: cs.primary),
              ),
            ),
            decoration: BoxDecoration(color: cs.primary),
          ),
          for (int i = 0; i < modulosInfo.length; i++)
            _buildNavItem(
              context: context,
              icon: modulosInfo[i]['icone'],
              title: modulosInfo[i]['titulo'],
              index: i,
            ),
          const Spacer(),
          const Divider(thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: Icon(LucideIcons.logOut, color: cs.error),
              title: Text(
                'Sair',
                style: tt.labelLarge?.copyWith(
                  color: cs.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              hoverColor: cs.error.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onTap: onLogout,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

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
        onTap: () => onItemSelected(index),
      ),
    );
  }
}

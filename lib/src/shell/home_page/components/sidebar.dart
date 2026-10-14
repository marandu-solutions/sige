import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final String? tenantNome;
  final String? tenantLogoUrl;
  final List<Map<String, dynamic>> modulosInfo;

  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    this.tenantNome,
    this.tenantLogoUrl,
    required this.modulosInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Drawer(
      backgroundColor: cs.surface,
      elevation: 0,
      width: 280,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          // Header com Branding do Tenant (Cortesia Profissional)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
            color: cs.primary,
            child: Row(
              children: [
                if (tenantLogoUrl != null && tenantLogoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      tenantLogoUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        backgroundColor: cs.onPrimary,
                        child: Text(
                          (tenantNome ?? 'E')[0].toUpperCase(),
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  )
                else
                  CircleAvatar(
                    backgroundColor: cs.onPrimary,
                    radius: 22,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenantNome ?? userName,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userEmail,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onPrimary.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
              leading: Icon(Icons.logout_rounded, color: cs.error),
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

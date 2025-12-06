/*import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../Model/estoque.dart';

class EstoqueCard extends StatelessWidget {
  final EstoqueItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const EstoqueCard({required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // ... (código do card mantido)
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool emAlerta = item.quantidade <= item.nivelAlerta;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: emAlerta ? cs.error.withOpacity(0.7) : cs.outline.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (emAlerta ? cs.error : cs.primary).withOpacity(0.1),
          child: Icon(
            emAlerta ? LucideIcons.alertTriangle : LucideIcons.package,
            color: emAlerta ? cs.error : cs.primary,
          ),
        ),
        title: Text(item.nome, style: theme.textTheme.titleMedium),
        subtitle: Text(
          'Nível de Alerta: ${item.nivelAlerta} ${item.unidade}',
          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.quantidade.toStringAsFixed(1)}${item.unidade}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') onTap();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar Quantidade')),
                const PopupMenuItem(value: 'delete', child: Text('Excluir Insumo', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}*/
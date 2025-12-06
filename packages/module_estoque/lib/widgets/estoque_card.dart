import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_estoque/providers/stock_provider.dart';

import '../models/stock_item_model.dart';
import 'add_item.dart';

class EstoqueCard extends ConsumerWidget {
  final StockItemModel item;

  const EstoqueCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bool emAlerta = item.qtdAtual <= item.nivelAlerta;

    void showEditDialog() {
      showDialog(
        context: context,
        builder: (context) {
          return AddEstoqueItemDialog(
            tenantId: item.tenantId,
            item: item,
          );
        },
      );
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: emAlerta
              ? cs.error.withOpacity(0.7)
              : cs.outline.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: showEditDialog,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (emAlerta ? cs.error : cs.primary).withOpacity(0.1),
          child: Icon(
            emAlerta ? LucideIcons.alertTriangle : LucideIcons.package,
            color: emAlerta ? cs.error : cs.primary,
          ),
        ),
        title: Text(item.nomeProduto, style: theme.textTheme.titleMedium),
        subtitle: Text(
          'Nível de Alerta: ${item.nivelAlerta.toStringAsFixed(0)} ${item.unidadeMedida}',
          style:
              theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${item.qtdAtual.toStringAsFixed(1)}${item.unidadeMedida}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  showEditDialog();
                }
                if (value == 'delete') {
                  ref
                      .read(stockProvider(item.tenantId).notifier)
                      .deleteItem(item.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Excluir', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

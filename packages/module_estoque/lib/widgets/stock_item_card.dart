import 'package:flutter/material.dart';
import 'package:module_estoque/models/stock_item_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Card de item de estoque
class StockItemCard extends StatelessWidget {
  final StockItemModel item;

  const StockItemCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isLowStock = item.qtdAtual <= 10;
    final isOutOfStock = item.qtdAtual <= 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOutOfStock
              ? colorScheme.error
              : isLowStock
                  ? colorScheme.tertiary
                  : colorScheme.outline.withOpacity(0.1),
          width: isOutOfStock || isLowStock ? 2 : 1,
        ),
      ),
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showItemDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.package,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nomeProduto,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'SKU: ${item.sku}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOutOfStock
                      ? colorScheme.error.withOpacity(0.1)
                      : isLowStock
                          ? colorScheme.tertiary.withOpacity(0.1)
                          : colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOutOfStock
                          ? LucideIcons.xCircle
                          : isLowStock
                              ? LucideIcons.alertTriangle
                              : LucideIcons.checkCircle,
                      size: 16,
                      color: isOutOfStock
                          ? colorScheme.error
                          : isLowStock
                              ? colorScheme.tertiary
                              : colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.qtdAtual} ${item.unidadeMedida}',
                      style: textTheme.bodySmall?.copyWith(
                        color: isOutOfStock
                            ? colorScheme.error
                            : isLowStock
                                ? colorScheme.tertiary
                                : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${item.precoVenda.toStringAsFixed(2)}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.nomeProduto),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.tag),
              title: const Text('SKU'),
              subtitle: Text(item.sku),
            ),
            ListTile(
              leading: const Icon(LucideIcons.boxes),
              title: const Text('Quantidade Atual'),
              subtitle: Text('${item.qtdAtual} ${item.unidadeMedida}'),
            ),
            ListTile(
              leading: const Icon(LucideIcons.dollarSign),
              title: const Text('Preço de Venda'),
              subtitle: Text('R\$ ${item.precoVenda.toStringAsFixed(2)}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

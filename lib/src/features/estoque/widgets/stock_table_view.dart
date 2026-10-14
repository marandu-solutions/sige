import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/stock_item_model.dart';

/// Visão em Tabela Pro de Alta Densidade de Estoque (Sally UX)
/// Permite conferência ágil de dados com ordenação rápida e leitura massiva de inventário.
class StockTableView extends StatefulWidget {
  final List<StockItemModel> items;
  final Function(StockItemModel) onItemTap;
  final Function(StockItemModel) onQuickMovement;

  const StockTableView({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onQuickMovement,
  });

  @override
  State<StockTableView> createState() => _StockTableViewState();
}

class _StockTableViewState extends State<StockTableView> {
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    final sortedItems = List<StockItemModel>.from(widget.items);
    sortedItems.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.nomeProduto.compareTo(b.nomeProduto);
          break;
        case 1:
          cmp = a.sku.compareTo(b.sku);
          break;
        case 2:
          cmp = a.categoria.compareTo(b.categoria);
          break;
        case 3:
          cmp = a.qtdAtual.compareTo(b.qtdAtual);
          break;
        case 4:
          cmp = a.precoVenda.compareTo(b.precoVenda);
          break;
        case 5:
          final aDate = a.caValidade ?? DateTime(2099);
          final bDate = b.caValidade ?? DateTime(2099);
          cmp = aDate.compareTo(bDate);
          break;
      }
      return _isAscending ? cmp : -cmp;
    });

    return Container(
      decoration: BoxDecoration(
        color: isDark ? SigeColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _isAscending,
              headingRowColor: WidgetStateProperty.all(
                isDark
                    ? SigeColors.darkColumnBg
                    : SigeColors.lightColumnBg.withValues(alpha: 0.5),
              ),
              dataRowMinHeight: 52,
              dataRowMaxHeight: 58,
              columnSpacing: 24,
              columns: [
                DataColumn(
                  label: const Text('Produto', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('SKU', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Saldo Atual', style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Preço Venda', style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('EPI / CA', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                const DataColumn(
                  label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
              rows: sortedItems.map((item) {
                Color healthColor = SigeColors.success;
                if (item.isRuptura) {
                  healthColor = SigeColors.danger;
                } else if (item.isAlerta) {
                  healthColor = SigeColors.warning;
                }

                return DataRow(
                  cells: [
                    // Nome do Produto
                    DataCell(
                      InkWell(
                        onTap: () => widget.onItemTap(item),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.isEpi
                                    ? Icons.verified_user_rounded
                                    : Icons.inventory_2_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 240),
                              child: Text(
                                item.nomeProduto,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // SKU
                    DataCell(
                      Text(
                        item.sku,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    // Categoria
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.categoria,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    // Saldo Atual
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${item.qtdAtual.toInt()} ${item.unidadeMedida}',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: healthColor,
                              fontSize: 13,
                            ),
                          ),
                          if (item.isAlerta || item.isRuptura) ...[
                            const SizedBox(width: 4),
                            Icon(
                              item.isRuptura ? Icons.error_rounded : Icons.warning_amber_rounded,
                              size: 14,
                              color: healthColor,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Preço Venda
                    DataCell(
                      Text(
                        currencyFormatter.format(item.precoVenda),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // EPI / CA
                    DataCell(
                      item.isEpi
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: item.isCaVencido
                                        ? SigeColors.danger.withValues(alpha: 0.15)
                                        : (item.isCaPertoVencer
                                            ? SigeColors.warning.withValues(alpha: 0.15)
                                            : SigeColors.success.withValues(alpha: 0.12)),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.caNumero != null ? 'CA ${item.caNumero}' : 'SIM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: item.isCaVencido
                                          ? SigeColors.danger
                                          : (item.isCaPertoVencer
                                              ? SigeColors.warning
                                              : SigeColors.success),
                                    ),
                                  ),
                                ),
                                if (item.caValidade != null) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${dateFormatter.format(item.caValidade!)})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Text(
                              '--',
                              style: TextStyle(
                                color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                              ),
                            ),
                    ),
                    // Ações
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.sync_alt_rounded, size: 16),
                            tooltip: 'Movimentar',
                            onPressed: () => widget.onQuickMovement(item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            tooltip: 'Ficha 360°',
                            onPressed: () => widget.onItemTap(item),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

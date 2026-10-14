import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/stock_item_model.dart';

/// Card Rico de Produto para Visão em Grade (Sally UX)
/// Apresenta status do CA, barra de nível de estoque, preço e botões de ação rápida.
class StockItemRichCard extends StatelessWidget {
  final StockItemModel item;
  final VoidCallback onTapDetail;
  final VoidCallback onQuickMovement;

  const StockItemRichCard({
    super.key,
    required this.item,
    required this.onTapDetail,
    required this.onQuickMovement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormatter = DateFormat('dd/MM/yyyy');

    // Cálculo da porcentagem de saúde do estoque
    final maxRef = item.estoqueMinimo > 0 ? item.estoqueMinimo * 2 : 50.0;
    final stockRatio = (item.qtdAtual / maxRef).clamp(0.0, 1.0);

    Color healthColor = SigeColors.success;
    if (item.isRuptura) {
      healthColor = SigeColors.danger;
    } else if (item.isAlerta) {
      healthColor = SigeColors.warning;
    }

    final cardBg = isDark ? SigeColors.darkSurface : Colors.white;
    final borderColor = item.isRuptura
        ? SigeColors.danger.withValues(alpha: 0.6)
        : (item.isAlerta
            ? SigeColors.warning.withValues(alpha: 0.5)
            : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder));

    return InkWell(
      onTap: onTapDetail,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo: Categoria + Badges (EPI / CA / Ruptura)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Badge de Categoria
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.categoria.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      // Badge de EPI & CA
                      if (item.isEpi) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.isCaVencido
                                ? SigeColors.danger.withValues(alpha: 0.12)
                                : (item.isCaPertoVencer
                                    ? SigeColors.warning.withValues(alpha: 0.15)
                                    : SigeColors.success.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.isCaVencido
                                  ? SigeColors.danger.withValues(alpha: 0.4)
                                  : (item.isCaPertoVencer
                                      ? SigeColors.warning.withValues(alpha: 0.5)
                                      : SigeColors.success.withValues(alpha: 0.3)),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.isCaVencido
                                    ? Icons.error_outline_rounded
                                    : (item.isCaPertoVencer
                                        ? Icons.access_time_rounded
                                        : Icons.verified_rounded),
                                size: 12,
                                color: item.isCaVencido
                                    ? SigeColors.danger
                                    : (item.isCaPertoVencer
                                        ? SigeColors.warning
                                        : SigeColors.success),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.caNumero != null
                                    ? 'CA ${item.caNumero}'
                                    : 'EPI NR-06',
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
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Alerta de Estoque Crítico
                if (item.isAlerta || item.isRuptura)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.isRuptura
                          ? SigeColors.danger
                          : SigeColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.isRuptura ? 'ESGOTADO' : 'ALERTA',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: item.isRuptura ? Colors.white : SigeColors.warning,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Título do Produto
            Text(
              item.nomeProduto,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // SKU e Fabricante
            Row(
              children: [
                Text(
                  'SKU: ${item.sku}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: isDark
                        ? SigeColors.darkTextMuted
                        : SigeColors.lightTextMuted,
                  ),
                ),
                if (item.fabricante != null && item.fabricante!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text('•',
                      style: TextStyle(
                          color: isDark
                              ? SigeColors.darkTextMuted
                              : SigeColors.lightTextMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.fabricante!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? SigeColors.darkTextSecondary
                            : SigeColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 14),

            // Nível de Estoque (Barra de Progresso)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${item.qtdAtual.toInt()}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: healthColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item.unidadeMedida,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? SigeColors.darkTextMuted
                            : SigeColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Mínimo: ${item.estoqueMinimo.toInt()} ${item.unidadeMedida}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? SigeColors.darkTextMuted
                        : SigeColors.lightTextMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stockRatio,
                backgroundColor: isDark
                    ? SigeColors.darkBorder
                    : SigeColors.lightBorder,
                valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                minHeight: 6,
              ),
            ),

            const SizedBox(height: 14),

            // Preço e Informação de Validade do CA
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currencyFormatter.format(item.precoVenda),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    if (item.precoCusto > 0)
                      Text(
                        'Custo: ${currencyFormatter.format(item.precoCusto)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? SigeColors.darkTextMuted
                              : SigeColors.lightTextMuted,
                        ),
                      ),
                  ],
                ),
                if (item.isEpi && item.caValidade != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Validade CA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? SigeColors.darkTextMuted
                              : SigeColors.lightTextMuted,
                        ),
                      ),
                      Text(
                        dateFormatter.format(item.caValidade!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.isCaVencido
                              ? SigeColors.danger
                              : (item.isCaPertoVencer
                                  ? SigeColors.warning
                                  : (isDark
                                      ? SigeColors.darkTextPrimary
                                      : SigeColors.lightTextPrimary)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const Spacer(),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Botões de Ação Rápida
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.sync_alt_rounded, size: 14),
                    label: const Text('Movimentar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onQuickMovement,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  tooltip: 'Abrir Ficha 360°',
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onTapDetail,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

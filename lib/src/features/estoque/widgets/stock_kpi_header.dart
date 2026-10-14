import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../providers/stock_provider.dart';

/// Cockpit Executivo de Inventário e Conformidade de EPIs (Sally UX)
/// 4 Cards com Glassmorphism sutil, estatísticas em tempo real e badges visuais.
class StockKpiHeader extends ConsumerWidget {
  final String tenantId;

  const StockKpiHeader({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(stockKpisProvider(tenantId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final cardWidth = isCompact
            ? (constraints.maxWidth - 12) / 2
            : (constraints.maxWidth - 36) / 4;

        final cards = [
          _buildKpiCard(
            context: context,
            title: 'Patrimônio em Estoque',
            value: currencyFormatter.format(kpi.valorTotalVenda),
            subtitle: 'Custo: ${currencyFormatter.format(kpi.valorTotalCusto)}',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: theme.colorScheme.primary,
            isDark: isDark,
            width: cardWidth,
            onTap: () {
              ref.read(stockFilterStatusProvider.notifier).state = 'todos';
            },
          ),
          _buildKpiCard(
            context: context,
            title: 'Risco de Ruptura',
            value: '${kpi.itensCriticos} itens',
            subtitle: kpi.itensCriticos > 0
                ? 'Abaixo do estoque mínimo'
                : 'Estoque regularizado',
            icon: Icons.warning_amber_rounded,
            iconColor:
                kpi.itensCriticos > 0 ? SigeColors.danger : SigeColors.success,
            isDark: isDark,
            width: cardWidth,
            highlight: kpi.itensCriticos > 0,
            onTap: () {
              ref.read(stockFilterStatusProvider.notifier).state = 'criticos';
            },
          ),
          _buildKpiCard(
            context: context,
            title: 'EPIs Homologados',
            value: '${kpi.episCount} produtos',
            subtitle: '${kpi.totalItens} itens totais catalogados',
            icon: Icons.verified_user_rounded,
            iconColor: SigeColors.info,
            isDark: isDark,
            width: cardWidth,
            onTap: () {
              ref.read(stockFilterStatusProvider.notifier).state = 'epis';
            },
          ),
          _buildKpiCard(
            context: context,
            title: 'Radar de CAs & Validades',
            value: '${kpi.casPertoVencer + kpi.casVencidos} alertas',
            subtitle: kpi.casVencidos > 0
                ? '${kpi.casVencidos} vencidos • ${kpi.casPertoVencer} a vencer'
                : (kpi.casPertoVencer > 0
                    ? '${kpi.casPertoVencer} a vencer nos prox. 60d'
                    : 'Todos os CAs vigentes'),
            icon: Icons.notification_important_rounded,
            iconColor: (kpi.casVencidos > 0 || kpi.casPertoVencer > 0)
                ? SigeColors.warning
                : SigeColors.success,
            isDark: isDark,
            width: cardWidth,
            highlight: kpi.casVencidos > 0,
            onTap: () {
              ref.read(stockFilterStatusProvider.notifier).state = 'vencendo30';
            },
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards,
        );
      },
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required double width,
    bool highlight = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final bgColor = isDark ? SigeColors.darkSurface : Colors.white;
    final borderColor = highlight
        ? iconColor.withValues(alpha: 0.5)
        : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: highlight ? 1.5 : 1.0),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: highlight
                    ? iconColor
                    : (isDark
                        ? SigeColors.darkTextMuted
                        : SigeColors.lightTextMuted),
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

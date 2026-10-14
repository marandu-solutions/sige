import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../providers/client_provider.dart';

/// Cockpit Executivo de Carteira de Clientes e Contas B2B (Sally UX)
/// 4 Cards interativos em Glassmorphism com estatísticas em tempo real.
class ClientKpiHeader extends ConsumerWidget {
  final String tenantId;

  const ClientKpiHeader({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpi = ref.watch(clientKpisProvider(tenantId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth;
        if (constraints.maxWidth < 600) {
          cardWidth = constraints.maxWidth;
        } else if (constraints.maxWidth < 1100) {
          cardWidth = (constraints.maxWidth - 12) / 2;
        } else {
          cardWidth = (constraints.maxWidth - 36) / 4;
        }

        final cards = [
          _buildKpiCard(
            context: context,
            title: 'Carteira de Clientes',
            value: '${kpi.totalContas} contas',
            subtitle: '${kpi.totalEmpresasPj} Empresas • ${kpi.totalContatosB2b} Contatos B2B',
            icon: Icons.corporate_fare_rounded,
            iconColor: theme.colorScheme.primary,
            isDark: isDark,
            width: cardWidth,
            onTap: () {
              ref.read(clientFilterSegmentProvider.notifier).state = 'TODOS';
            },
          ),
          _buildKpiCard(
            context: context,
            title: 'Clientes Ativos',
            value: '${kpi.clientesAtivos} contas',
            subtitle: kpi.totalContas > 0
                ? '${((kpi.clientesAtivos / kpi.totalContas) * 100).toInt()}% da carteira engajada'
                : 'Nenhum cliente ativo',
            icon: Icons.verified_rounded,
            iconColor: SigeColors.success,
            isDark: isDark,
            width: cardWidth,
            onTap: () {
              ref.read(clientFilterSegmentProvider.notifier).state = 'ATIVOS';
            },
          ),
          _buildKpiCard(
            context: context,
            title: 'Volume LTV & Ticket',
            value: currencyFormatter.format(kpi.ltvTotal),
            subtitle: 'Ticket Médio: ${currencyFormatter.format(kpi.ticketMedio)}',
            icon: Icons.monetization_on_rounded,
            iconColor: SigeColors.warning,
            isDark: isDark,
            width: cardWidth,
            onTap: () {},
          ),
          _buildKpiCard(
            context: context,
            title: 'Novos no Mês',
            value: '+${kpi.novosMes} cadastros',
            subtitle: '${kpi.totalEmpresasPj} empresas cadastradas no total',
            icon: Icons.trending_up_rounded,
            iconColor: SigeColors.info,
            isDark: isDark,
            width: cardWidth,
            onTap: () {
              ref.read(clientFilterSegmentProvider.notifier).state = 'LEADS';
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
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final bgColor = isDark ? SigeColors.darkSurface : Colors.white;
    final borderColor = isDark ? SigeColors.darkBorder : SigeColors.lightBorder;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
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
                color: isDark
                    ? SigeColors.darkTextMuted
                    : SigeColors.lightTextMuted,
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

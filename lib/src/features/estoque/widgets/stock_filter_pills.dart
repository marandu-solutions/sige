import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../providers/stock_provider.dart';

/// Barra de Pílulas de Foco Operacional e Alternância Dual View (Grade / Tabela)
class StockFilterPills extends ConsumerWidget {
  final String tenantId;

  const StockFilterPills({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStatus = ref.watch(stockFilterStatusProvider);
    final activeViewMode = ref.watch(stockViewModeProvider);
    final kpi = ref.watch(stockKpisProvider(tenantId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filterOptions = [
      (key: 'todos', label: 'Todos', count: kpi.totalItens, icon: Icons.all_inbox_rounded),
      (key: 'criticos', label: 'Ruptura / Alerta', count: kpi.itensCriticos, icon: Icons.warning_rounded),
      (key: 'epis', label: 'EPIs com CA', count: kpi.episCount, icon: Icons.verified_user_rounded),
      (key: 'vencendo30', label: 'CAs a Vencer', count: kpi.casPertoVencer + kpi.casVencidos, icon: Icons.event_busy_rounded),
    ];

    return Row(
      children: [
        // Pílulas de Filtro Rápido
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((opt) {
                final isSelected = activeStatus == opt.key;
                final isAlert = opt.key == 'criticos' && opt.count > 0;
                final isWarning = opt.key == 'vencendo30' && opt.count > 0;

                Color badgeBg = isSelected
                    ? theme.colorScheme.primary
                    : (isDark ? SigeColors.darkSurface : Colors.white);
                Color textColor = isSelected
                    ? Colors.white
                    : (isDark ? SigeColors.darkTextPrimary : SigeColors.lightTextPrimary);

                if (isAlert && !isSelected) {
                  textColor = SigeColors.danger;
                } else if (isWarning && !isSelected) {
                  textColor = SigeColors.warning;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: Icon(
                      opt.icon,
                      size: 16,
                      color: isSelected ? Colors.white : textColor,
                    ),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(opt.label),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : (isDark
                                    ? Colors.black.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${opt.count}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      ref.read(stockFilterStatusProvider.notifier).state = opt.key;
                    },
                    backgroundColor: badgeBg,
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder),
                        width: 1.0,
                      ),
                    ),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Alternador de Visualização (Grade vs Tabela)
        Container(
          decoration: BoxDecoration(
            color: isDark ? SigeColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: activeViewMode == 'grid'
                      ? theme.colorScheme.primary
                      : (isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted),
                ),
                tooltip: 'Visualização em Grade de Cards',
                onPressed: () {
                  ref.read(stockViewModeProvider.notifier).state = 'grid';
                },
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              Container(
                height: 20,
                width: 1,
                color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
              ),
              IconButton(
                icon: Icon(
                  Icons.table_rows_rounded,
                  size: 18,
                  color: activeViewMode == 'table'
                      ? theme.colorScheme.primary
                      : (isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted),
                ),
                tooltip: 'Visualização em Tabela Pro',
                onPressed: () {
                  ref.read(stockViewModeProvider.notifier).state = 'table';
                },
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

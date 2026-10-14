import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/client_model.dart';

/// Visão em Tabela Pro de Alta Densidade para Clientes e Contas B2B (Sally UX)
class ClientTableView extends StatefulWidget {
  final List<ClientModel> clients;
  final Function(ClientModel) onClientTap;
  final Function(ClientModel) onQuickContact;

  const ClientTableView({
    super.key,
    required this.clients,
    required this.onClientTap,
    required this.onQuickContact,
  });

  @override
  State<ClientTableView> createState() => _ClientTableViewState();
}

class _ClientTableViewState extends State<ClientTableView> {
  int _sortColumnIndex = 0;
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final sortedList = List<ClientModel>.from(widget.clients);
    sortedList.sort((a, b) {
      int cmp = 0;
      switch (_sortColumnIndex) {
        case 0:
          cmp = a.nome.compareTo(b.nome);
          break;
        case 1:
          cmp = a.tipo.compareTo(b.tipo);
          break;
        case 2:
          cmp = (a.documento ?? '').compareTo(b.documento ?? '');
          break;
        case 3:
          cmp = a.telefonePrincipal.compareTo(b.telefonePrincipal);
          break;
        case 4:
          cmp = a.statusCiclo.compareTo(b.statusCiclo);
          break;
        case 5:
          cmp = a.ltvTotal.compareTo(b.ltvTotal);
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
                  label: const Text('Cliente / Nome', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Segmento / Vínculo', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('CNPJ / CPF', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('WhatsApp Principal', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  onSort: (index, ascending) {
                    setState(() {
                      _sortColumnIndex = index;
                      _isAscending = ascending;
                    });
                  },
                ),
                DataColumn(
                  label: const Text('LTV Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  numeric: true,
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
              rows: sortedList.map((c) {
                Color typeColor = theme.colorScheme.primary;
                String typeStr = 'PF';
                if (c.isPj) {
                  typeColor = SigeColors.info;
                  typeStr = 'PJ';
                } else if (c.isContatoPj) {
                  typeColor = Colors.purple;
                  typeStr = 'B2B';
                }

                return DataRow(
                  cells: [
                    // Nome e Iniciais
                    DataCell(
                      InkWell(
                        onTap: () => widget.onClientTap(c),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: typeColor.withValues(alpha: 0.12),
                              child: Text(
                                c.nome.isNotEmpty ? c.nome[0].toUpperCase() : 'C',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.nome,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (c.razaoSocial != null && c.razaoSocial!.isNotEmpty && c.razaoSocial != c.nome)
                                    Text(
                                      c.razaoSocial!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
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
                    ),
                    // Segmento / Vínculo
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              typeStr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                          ),
                          if (c.isContatoPj && c.empresaNome != null) ...[
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                c.empresaNome!,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Documento
                    DataCell(
                      Text(
                        c.documentoFormatado,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    // Telefone
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_rounded, size: 13, color: SigeColors.success),
                          const SizedBox(width: 4),
                          Text(
                            c.telefoneFormatado,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    // Status
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: c.statusCiclo == 'ATIVO'
                              ? SigeColors.success.withValues(alpha: 0.12)
                              : (isDark ? Colors.white10 : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.statusCiclo,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: c.statusCiclo == 'ATIVO'
                                ? SigeColors.success
                                : (isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted),
                          ),
                        ),
                      ),
                    ),
                    // LTV
                    DataCell(
                      Text(
                        currencyFormatter.format(c.ltvTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Ações
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            tooltip: 'Conversar',
                            onPressed: () => widget.onQuickContact(c),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            tooltip: 'Ficha 360°',
                            onPressed: () => widget.onClientTap(c),
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

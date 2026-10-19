import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/models/funcionario_model.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/services/atendimento_metrics_helper.dart';

class AtendenteInspectionDrawer extends StatefulWidget {
  final AtendenteMetrics metrics;
  final List<FuncionarioModel> outrosAtendentes;
  final VoidCallback onClose;
  final Function(AtendimentoModel card) onAbrirChat;
  final Function(AtendimentoModel card, String novoFuncionarioId, String novoFuncionarioNome) onTransferirCard;

  const AtendenteInspectionDrawer({
    super.key,
    required this.metrics,
    required this.outrosAtendentes,
    required this.onClose,
    required this.onAbrirChat,
    required this.onTransferirCard,
  });

  @override
  State<AtendenteInspectionDrawer> createState() => _AtendenteInspectionDrawerState();
}

class _AtendenteInspectionDrawerState extends State<AtendenteInspectionDrawer> {
  String _filtro = 'todos'; // 'todos', 'vacuo', 'vip'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final f = widget.metrics.funcionario;

    // Filtra e ordena cards
    List<AtendimentoModel> cards = List.from(widget.metrics.cardsAtivos);

    if (_filtro == 'vacuo') {
      cards = cards.where((c) => widget.metrics.cardsEmVacuo.contains(c)).toList();
    } else if (_filtro == 'vip') {
      cards = cards.where((c) => c.isB2BVip).toList();
    }

    // Ordenação: primeiro os que estão em vácuo, depois por valor estimado decrescente
    cards.sort((a, b) {
      final aVacuo = widget.metrics.cardsEmVacuo.contains(a);
      final bVacuo = widget.metrics.cardsEmVacuo.contains(b);
      if (aVacuo && !bVacuo) return -1;
      if (!aVacuo && bVacuo) return 1;
      return b.valorEstimadoCalculado.compareTo(a.valorEstimadoCalculado);
    });

    final faturamentoFormatado = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    ).format(widget.metrics.pipelineTotalReais);

    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da Gaveta
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                      child: Text(
                        f.nome.isNotEmpty ? f.nome[0].toUpperCase() : 'A',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  f.nome,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Modo Auditoria',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            f.cargo ?? 'Vendedor Comercial',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, size: 20),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Resumo rápido
                Row(
                  children: [
                    _buildPillSummary(
                      label: 'Ativos',
                      value: '${widget.metrics.totalAtivos}',
                      cor: const Color(0xFF2563EB),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildPillSummary(
                      label: 'No Vácuo',
                      value: '${widget.metrics.cardsEmVacuo.length}',
                      cor: widget.metrics.cardsEmVacuo.isNotEmpty ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPillSummary(
                        label: 'Total Pipeline',
                        value: faturamentoFormatado,
                        cor: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Todos (${widget.metrics.totalAtivos})', 'todos', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('⚠️ Vácuo (${widget.metrics.cardsEmVacuo.length})', 'vacuo', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('⭐ VIP (${widget.metrics.totalVipCards})', 'vip', isDark),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de conversas ativas
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.inbox, size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhum atendimento neste filtro',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: cards.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isEmVacuo = widget.metrics.cardsEmVacuo.contains(card);

                      return _buildLeadInspectionCard(
                        card: card,
                        isEmVacuo: isEmVacuo,
                        isDark: isDark,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillSummary({
    required String label,
    required String value,
    required Color cor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary)),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String id, bool isDark) {
    final isSelected = _filtro == id;
    return InkWell(
      onTap: () => setState(() => _filtro = id),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : SigeColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadInspectionCard({
    required AtendimentoModel card,
    required bool isEmVacuo,
    required bool isDark,
  }) {
    final valorFormatado = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$ ').format(card.valorEstimadoCalculado);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmVacuo
              ? const Color(0xFFEF4444)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          width: isEmVacuo ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha superior: Nome do Cliente / Empresa e Badge VIP / Vácuo
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.clienteNome.isNotEmpty ? card.clienteNome : 'Cliente sem nome',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (card.titulo.isNotEmpty && card.titulo != card.clienteNome) ...[
                      const SizedBox(height: 2),
                      Text(
                        card.titulo,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2563EB),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (card.isB2BVip) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'VIP • $valorFormatado',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                  ),
                ),
              ] else ...[
                Text(
                  valorFormatado,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ],
          ),

          if (isEmVacuo) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertTriangle, size: 12, color: Color(0xFFEF4444)),
                  SizedBox(width: 4),
                  Text(
                    'Sem resposta humana além do SLA de vácuo',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Última mensagem / Detalhes
          if (card.ultimaMensagem.isNotEmpty)
            Text(
              card.ultimaMensagem,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 12),

          // Ações do Gerente no Card
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => widget.onAbrirChat(card),
                  icon: const Icon(LucideIcons.messageSquare, size: 12),
                  label: const Text('Auditar Chat', style: TextStyle(fontSize: 11)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<FuncionarioModel>(
                tooltip: 'Transferir atendimento',
                icon: const Icon(LucideIcons.userMinus, size: 14),
                itemBuilder: (context) {
                  return widget.outrosAtendentes.map((dest) {
                    return PopupMenuItem<FuncionarioModel>(
                      value: dest,
                      child: Text('Transferir para ${dest.nome}'),
                    );
                  }).toList();
                },
                onSelected: (novoDestino) {
                  widget.onTransferirCard(card, novoDestino.id, novoDestino.nome);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

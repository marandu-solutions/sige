import 'package:flutter/material.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/widgets/atendimento_avatar.dart';
import 'package:sige/src/features/clientes/widgets/link_client_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Widget de cartão de atendimento individual - Design Moderno (Sally UX)
class AtendimentoCardWidget extends StatefulWidget {
  final AtendimentoModel card;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback? onReassign;

  const AtendimentoCardWidget({
    super.key,
    required this.card,
    required this.color,
    required this.onTap,
    this.onReassign,
  });

  @override
  State<AtendimentoCardWidget> createState() => _AtendimentoCardWidgetState();
}

class _AtendimentoCardWidgetState extends State<AtendimentoCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final (priorityBg, priorityTextColor, priorityText) =
        _getPriorityBadge(isDark);

    return Draggable<AtendimentoModel>(
      data: widget.card,
      feedback: Material(
        elevation: 6.0,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 310,
          child: AtendimentoCardWidget(
            card: widget.card,
            color: widget.color,
            onTap: () {},
            onReassign: null,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 150,
          decoration: BoxDecoration(
            color: isDark ? SigeColors.darkCardBg : SigeColors.lightCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
        ),
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? SigeColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.primary.withOpacity(0.5)
                  : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder),
              width: _isHovered ? 1.2 : 0.8,
            ),
            boxShadow: _isHovered
                ? SigeColors.lightElevatedShadow
                : SigeColors.lightCardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Badge de Prioridade + Mensagens Não Lidas + Avatar
                    Row(
                      children: [
                        // Pill de Prioridade
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: priorityBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: priorityTextColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                priorityText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: priorityTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge de Classificação Financeira / Ticket (MD06 EPIs)
                        if (widget.card.isB2BVip) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF78350F).withOpacity(0.4)
                                  : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: const Color(0xFFF59E0B),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.crown,
                                  size: 10,
                                  color: Color(0xFFD97706),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  widget.card.valorEstimadoCalculado > 0
                                      ? 'VIP • R\$ ${widget.card.valorEstimadoCalculado.toStringAsFixed(0)}'
                                      : 'B2B VIP',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (widget.card.valorEstimadoCalculado > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'R\$ ${widget.card.valorEstimadoCalculado.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),

                        // Badge de Mensagens Não Lidas (WhatsApp Style)
                        if (widget.card.mensagensNaoLidas > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981), // Esmeralda vibrante
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.messageSquare,
                                  size: 11,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.card.mensagensNaoLidas > 99
                                      ? '99+'
                                      : widget.card.mensagensNaoLidas.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        if (widget.card.fotoUrl != null &&
                            widget.card.fotoUrl!.isNotEmpty)
                          AtendimentoAvatar(
                            fotoUrl: widget.card.fotoUrl,
                            radius: 13,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Título do Atendimento (Demanda ou Negociação)
                    Text(
                      widget.card.titulo.isNotEmpty
                          ? widget.card.titulo
                          : widget.card.clienteNome,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark
                            ? SigeColors.darkTextPrimary
                            : SigeColors.lightTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    // Contato do Cliente (Nome e Telefone)
                    Row(
                      children: [
                        Icon(
                          LucideIcons.user,
                          size: 13,
                          color: isDark
                              ? SigeColors.darkTextSecondary
                              : SigeColors.lightTextSecondary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            widget.card.clienteNome,
                            style: textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? SigeColors.darkTextSecondary
                                  : SigeColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.card.clienteTelefone.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            LucideIcons.phone,
                            size: 12,
                            color: isDark
                                ? SigeColors.darkTextMuted
                                : SigeColors.lightTextMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.card.clienteTelefone,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: isDark
                                  ? SigeColors.darkTextMuted
                                  : SigeColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Vincular a Empresa / Gerenciar Cliente',
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => LinkClientDialog(
                                    tenantId: widget.card.tenantId,
                                    telefone: widget.card.clienteTelefone,
                                    nomeContato: widget.card.clienteNome,
                                    leadOrAtendimentoId: widget.card.id,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 3, vertical: 1),
                                child: Icon(
                                  Icons.link_rounded,
                                  size: 14,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Metadados Dinâmicos (EPI: Tamanho/CA; Solar: kWh/Conta)
                    if (widget.card.metadata.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: widget.card.metadata.entries.map((entry) {
                          final keyLabel =
                              entry.key.replaceAll('_', ' ').toUpperCase();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: colorScheme.primary.withOpacity(0.2),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              '$keyLabel: ${entry.value}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Preview da Última Mensagem (Estilo Balão Elegante, SEM cinza escuro no modo claro)
                    if (widget.card.ultimaMensagem.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark
                              ? SigeColors.darkBg
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark
                                ? SigeColors.darkBorder
                                : SigeColors.lightBorder,
                            width: 0.7,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                LucideIcons.messageCircle,
                                size: 12,
                                color: isDark
                                    ? SigeColors.darkTextMuted
                                    : SigeColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.card.ultimaMensagem,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? SigeColors.darkTextSecondary
                                      : const Color(0xFF334155),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Linha de Rodapé: Responsável pelo Atendimento + Botão Remanejar
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.card.funcionarioResponsavelId != null
                            ? (isDark
                                ? colorScheme.primary.withOpacity(0.12)
                                : colorScheme.primary.withOpacity(0.06))
                            : const Color(0xFFFEF3C7).withOpacity(0.8), // Âmbar suave
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: widget.card.funcionarioResponsavelId != null
                              ? colorScheme.primary.withOpacity(0.2)
                              : const Color(0xFFF59E0B).withOpacity(0.4),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.card.funcionarioResponsavelId != null
                                ? LucideIcons.userCheck
                                : LucideIcons.bot,
                            size: 13,
                            color: widget.card.funcionarioResponsavelId != null
                                ? colorScheme.primary
                                : const Color(0xFFB45309),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.card.funcionarioResponsavelNome ??
                                  (widget.card.funcionarioResponsavelId != null
                                      ? 'Atribuído'
                                      : 'Fila IA (Não Atribuído)'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.card.funcionarioResponsavelId !=
                                        null
                                    ? colorScheme.primary
                                    : const Color(0xFFB45309),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.onReassign != null)
                            InkWell(
                              onTap: widget.onReassign,
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      LucideIcons.arrowRightLeft,
                                      size: 12,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Remanejar',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color bg, Color text, String label) _getPriorityBadge(bool isDark) {
    switch (widget.card.prioridade.toLowerCase()) {
      case 'alta':
        return (
          isDark
              ? SigeColors.danger.withOpacity(0.2)
              : SigeColors.priorityHighBgLight,
          isDark ? const Color(0xFFFCA5A5) : SigeColors.priorityHighTextLight,
          'Alta',
        );
      case 'media':
        return (
          isDark
              ? SigeColors.warning.withOpacity(0.2)
              : SigeColors.priorityMediumBgLight,
          isDark ? const Color(0xFFFCD34D) : SigeColors.priorityMediumTextLight,
          'Média',
        );
      case 'baixa':
        return (
          isDark
              ? SigeColors.success.withOpacity(0.2)
              : SigeColors.priorityLowBgLight,
          isDark ? const Color(0xFF86EFAC) : SigeColors.priorityLowTextLight,
          'Baixa',
        );
      default:
        return (
          isDark
              ? SigeColors.info.withOpacity(0.2)
              : const Color(0xFFDBEAFE),
          isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
          'Normal',
        );
    }
  }
}

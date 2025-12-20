import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:module_atendimento/models/atendimento_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Widget de cartão de atendimento individual (Somente Leitura - Sem Draggable)
/// Design modernizado e impactante
class ReadOnlyAtendimentoCardWidget extends StatefulWidget {
  final AtendimentoModel card;
  final Color color;
  final VoidCallback onTap;

  const ReadOnlyAtendimentoCardWidget({
    super.key,
    required this.card,
    required this.color,
    required this.onTap,
  });

  @override
  State<ReadOnlyAtendimentoCardWidget> createState() =>
      _ReadOnlyAtendimentoCardWidgetState();
}

class _ReadOnlyAtendimentoCardWidgetState
    extends State<ReadOnlyAtendimentoCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final priorityColor = _getPriorityColor(colorScheme);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isHovered
                  ? colorScheme.primary.withOpacity(0.5)
                  : colorScheme.outlineVariant.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 12 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faixa lateral de prioridade
              Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: 0.3,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Cliente e Data
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            widget.card.clienteNome.isNotEmpty
                                ? widget.card.clienteNome[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.card.clienteNome,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm').format(widget.card.dataUltimaAtualizacao),
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Título do Atendimento
                    Text(
                      widget.card.titulo,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Última mensagem (Preview)
                    if (widget.card.ultimaMensagem.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.messageSquare,
                              size: 14,
                              color: colorScheme.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.card.ultimaMensagem,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Footer: Status e Notificações
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTag(
                          context,
                          label: _getPriorityText(),
                          color: priorityColor,
                          isOutlined: true,
                        ),
                        if (widget.card.mensagensNaoLidas > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.error.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.bell,
                                    size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  widget.card.mensagensNaoLidas.toString(),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context,
      {required String label, required Color color, bool isOutlined = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: isOutlined ? Border.all(color: color.withOpacity(0.5)) : null,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getPriorityColor(ColorScheme colorScheme) {
    switch (widget.card.prioridade.toLowerCase()) {
      case 'alta':
        return const Color(0xFFFF4D4F); // Red
      case 'media':
        return const Color(0xFFFAAD14); // Orange
      case 'baixa':
        return const Color(0xFF52C41A); // Green
      default:
        return colorScheme.primary;
    }
  }

  String _getPriorityText() {
    switch (widget.card.prioridade.toLowerCase()) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Média';
      case 'baixa':
        return 'Baixa';
      default:
        return 'Normal';
    }
  }
}

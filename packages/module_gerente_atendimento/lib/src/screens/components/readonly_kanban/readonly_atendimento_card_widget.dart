import 'package:flutter/material.dart';
import 'package:module_atendimento/models/atendimento_card_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

/// Widget de cartão de atendimento individual (Somente Leitura - Sem Draggable)
class ReadOnlyAtendimentoCardWidget extends StatelessWidget {
  final AtendimentoCardModel card;
  final Color color;
  final VoidCallback onTap;

  const ReadOnlyAtendimentoCardWidget({
    super.key,
    required this.card,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final priorityColor = _getPriorityColor(colorScheme);
    final daysUntilDue = card.dataLimite.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;

    // Apenas InkWell e Card, sem Draggable
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com prioridade e data
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getPriorityText(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: isOverdue
                        ? colorScheme.error
                        : colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM').format(card.dataLimite),
                    style: textTheme.bodySmall?.copyWith(
                      color: isOverdue
                          ? colorScheme.error
                          : colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: isOverdue ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Título do atendimento
              Text(
                card.titulo,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Informações do cliente
              Row(
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 14,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      card.clienteNome,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Telefone do cliente
              Row(
                children: [
                  Icon(
                    LucideIcons.phone,
                    size: 14,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    card.clienteTelefone,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              if (card.ultimaMensagem.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          card.ultimaMensagem,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (card.mensagensNaoLidas > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            card.mensagensNaoLidas.toString(),
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(ColorScheme colorScheme) {
    switch (card.prioridade.toLowerCase()) {
      case 'alta':
        return colorScheme.error;
      case 'media':
        return Colors.orange;
      case 'baixa':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityText() {
    switch (card.prioridade.toLowerCase()) {
      case 'alta':
        return 'Prioridade Alta';
      case 'media':
        return 'Prioridade Média';
      case 'baixa':
        return 'Prioridade Baixa';
      default:
        return 'Prioridade';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:module_kanban/models/kanban_card_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

/// Widget de cartão Kanban individual
class KanbanCardWidget extends StatelessWidget {
  final KanbanCardModel card;
  final Color color;
  final Function(String) onMove;

  const KanbanCardWidget({
    super.key,
    required this.card,
    required this.color,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final priorityColor = _getPriorityColor(colorScheme);
    final daysUntilDue = card.dataLimite.difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCardDetails(context),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título e prioridade
              Row(
                children: [
                  Expanded(
                    child: Text(
                      card.titulo,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: priorityColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      _getPriorityText(),
                      style: textTheme.bodySmall?.copyWith(
                        color: priorityColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Data limite
              Row(
                children: [
                  Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: isOverdue ? colorScheme.error : colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(card.dataLimite),
                    style: textTheme.bodySmall?.copyWith(
                      color:
                          isOverdue ? colorScheme.error : colorScheme.outline,
                      fontWeight:
                          isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (isOverdue)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Atrasado',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Ações
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botões de mover
                  Row(
                    children: [
                      if (card.colunaStatus != 'to_do')
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft, size: 16),
                          onPressed: () => _moveToPreviousColumn(),
                          tooltip: 'Mover para coluna anterior',
                        ),
                      if (card.colunaStatus != 'done')
                        IconButton(
                          icon: const Icon(LucideIcons.arrowRight, size: 16),
                          onPressed: () => _moveToNextColumn(),
                          tooltip: 'Mover para próxima coluna',
                        ),
                    ],
                  ),
                  // Menu de opções
                  PopupMenuButton<String>(
                    icon: const Icon(LucideIcons.moreVertical, size: 16),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editCard(context);
                          break;
                        case 'delete':
                          _deleteCard(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(LucideIcons.edit2, size: 16),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(LucideIcons.trash2,
                                size: 16, color: colorScheme.error),
                            const SizedBox(width: 8),
                            Text('Excluir',
                                style: TextStyle(color: colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(ColorScheme colorScheme) {
    switch (card.prioridade) {
      case 'alta':
        return colorScheme.error;
      case 'media':
        return colorScheme.tertiary;
      case 'baixa':
        return colorScheme.primary;
      default:
        return colorScheme.outline;
    }
  }

  String _getPriorityText() {
    switch (card.prioridade) {
      case 'alta':
        return 'ALTA';
      case 'media':
        return 'MÉDIA';
      case 'baixa':
        return 'BAIXA';
      default:
        return card.prioridade.toUpperCase();
    }
  }

  void _moveToPreviousColumn() {
    String newColumn;
    switch (card.colunaStatus) {
      case 'in_progress':
        newColumn = 'to_do';
        break;
      case 'done':
        newColumn = 'in_progress';
        break;
      default:
        return;
    }
    onMove(newColumn);
  }

  void _moveToNextColumn() {
    String newColumn;
    switch (card.colunaStatus) {
      case 'to_do':
        newColumn = 'in_progress';
        break;
      case 'in_progress':
        newColumn = 'done';
        break;
      default:
        return;
    }
    onMove(newColumn);
  }

  void _showCardDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(card.titulo),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.columns),
                title: const Text('Status'),
                subtitle: Text(_getStatusText()),
              ),
              ListTile(
                leading: const Icon(LucideIcons.flag),
                title: const Text('Prioridade'),
                subtitle: Text(_getPriorityText()),
              ),
              ListTile(
                leading: const Icon(LucideIcons.calendar),
                title: const Text('Data Limite'),
                subtitle:
                    Text(DateFormat('dd/MM/yyyy').format(card.dataLimite)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _editCard(BuildContext context) {
    // TODO: Implementar edição do cartão
  }

  void _deleteCard(BuildContext context) {
    // TODO: Implementar exclusão do cartão
  }

  String _getStatusText() {
    switch (card.colunaStatus) {
      case 'to_do':
        return 'A Fazer';
      case 'in_progress':
        return 'Em Progresso';
      case 'done':
        return 'Concluído';
      default:
        return card.colunaStatus;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:module_kanban/models/kanban_card_model.dart';
import 'package:module_kanban/widgets/kanban_card_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Widget de coluna do Kanban
class KanbanColumn extends StatelessWidget {
  final String title;
  final String columnId;
  final List<KanbanCardModel> cards;
  final Color color;
  final Function(String, String) onCardMove;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.columnId,
    required this.cards,
    required this.color,
    required this.onCardMove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Cabeçalho da coluna
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cards.length.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de cartões
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.clipboard,
                          size: 48,
                          color: colorScheme.outline.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum cartão',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.outline.withOpacity(0.6),
                                  ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      return KanbanCardWidget(
                        card: cards[index],
                        onMove: (newColumn) =>
                            onCardMove(cards[index].id, newColumn),
                        color: color,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

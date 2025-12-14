import 'package:flutter/material.dart';
import 'package:module_atendimento/models/atendimento_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'readonly_atendimento_card_widget.dart';

class ReadOnlyAtendimentoColumn extends StatelessWidget {
  final AtendimentoColumnModel column;
  final List<AtendimentoModel> cards;
  final Function(AtendimentoModel) onCardTap;

  const ReadOnlyAtendimentoColumn({
    super.key,
    required this.column,
    required this.cards,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        // Removido border e lógica de DragTarget
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da coluna
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: column.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: column.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    column.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Removido botão de editar
                Text(
                  cards.length.toString(),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cards da coluna
          Expanded(
            child: cards.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.inbox,
                          size: 48,
                          color: colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum atendimento',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return ReadOnlyAtendimentoCardWidget(
                        key: ValueKey(card.id),
                        card: card,
                        color: column.color,
                        onTap: () => onCardTap(card),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

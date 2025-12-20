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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1E1E)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: column.color.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: column.color.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: column.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: column.color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    column.title.toUpperCase(),
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: column.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: column.color.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    cards.length.toString(),
                    style: textTheme.labelSmall?.copyWith(
                      color: column.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cards da coluna
          Expanded(
            child: cards.isEmpty
                ? _buildEmptyState(context)
                : Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbVisibility: MaterialStateProperty.all(true),
                        radius: const Radius.circular(10),
                        thickness: MaterialStateProperty.all(4),
                        thumbColor: MaterialStateProperty.all(
                            colorScheme.outlineVariant),
                      ),
                    ),
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cards.length,
                      padding: const EdgeInsets.only(bottom: 16),
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.inbox,
                size: 32,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vazio',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

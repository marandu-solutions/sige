import 'package:flutter/material.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/models/atendimento_column_model.dart';
import 'package:sige/src/features/atendimento/widgets/atendimento_card_widget.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AtendimentoColumn extends StatefulWidget {
  final AtendimentoColumnModel column;
  final List<AtendimentoModel> cards;
  final Function(String, String) onCardMove;
  final VoidCallback onEdit;
  final Function(AtendimentoModel) onCardTap;
  final Function(AtendimentoModel)? onCardReassign;
  final int columnIndex;

  const AtendimentoColumn({
    super.key,
    required this.column,
    required this.cards,
    required this.onCardMove,
    required this.onEdit,
    required this.onCardTap,
    this.onCardReassign,
    required this.columnIndex,
  });

  @override
  State<AtendimentoColumn> createState() => _AtendimentoColumnState();
}

class _AtendimentoColumnState extends State<AtendimentoColumn> {
  bool _isCardDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final laneBg = isDark ? SigeColors.darkColumnBg : SigeColors.lightColumnBg;
    final laneBorder = isDark ? SigeColors.darkBorder : SigeColors.lightBorder;

    return DragTarget<AtendimentoModel>(
      onWillAcceptWithDetails: (details) {
        if (details.data.colunaStatus == widget.column.id) return false;
        setState(() => _isCardDraggingOver = true);
        return true;
      },
      onLeave: (_) => setState(() => _isCardDraggingOver = false),
      onAcceptWithDetails: (details) {
        setState(() => _isCardDraggingOver = false);
        widget.onCardMove(details.data.id, widget.column.id);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 320,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: _isCardDraggingOver
                ? colorScheme.primary.withOpacity(0.08)
                : laneBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isCardDraggingOver
                  ? colorScheme.primary.withOpacity(0.6)
                  : laneBorder,
              width: _isCardDraggingOver ? 1.5 : 0.8,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Elegante da Coluna (Lane Header)
              Container(
                padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? SigeColors.darkSurface.withOpacity(0.6)
                      : Colors.white.withOpacity(0.85),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: laneBorder.withOpacity(0.6),
                      width: 0.8,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Alça de arraste da coluna integrada e discreta
                    ReorderableDragStartListener(
                      index: widget.columnIndex,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            LucideIcons.gripVertical,
                            size: 15,
                            color: isDark
                                ? SigeColors.darkTextMuted.withOpacity(0.6)
                                : SigeColors.lightTextMuted.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),

                    // Indicador de Cor da Fase
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: widget.column.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.column.color.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Título da Coluna
                    Expanded(
                      child: Text(
                        widget.column.title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark
                              ? SigeColors.darkTextPrimary
                              : SigeColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Contador de Cards (Pill Badge)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? SigeColors.darkSurface
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: laneBorder,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        widget.cards.length.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? SigeColors.darkTextSecondary
                              : SigeColors.lightTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),

                    // Menu de Edição da Coluna
                    IconButton(
                      icon: const Icon(LucideIcons.moreHorizontal,
                          size: 15),
                      onPressed: widget.onEdit,
                      tooltip: 'Opções da Coluna',
                      visualDensity: VisualDensity.compact,
                      color: isDark
                          ? SigeColors.darkTextMuted
                          : SigeColors.lightTextMuted,
                    ),
                  ],
                ),
              ),

              // Lista de Cards da Coluna
              Expanded(
                child: widget.cards.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(14),
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 28, horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: laneBorder.withOpacity(0.5),
                                width: 0.8,
                              ),
                              color: isDark
                                  ? Colors.white.withOpacity(0.01)
                                  : Colors.black.withOpacity(0.01),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.layers,
                                  size: 20,
                                  color: isDark
                                      ? SigeColors.darkTextMuted.withOpacity(0.3)
                                      : SigeColors.lightTextMuted.withOpacity(0.4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nenhum atendimento',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? SigeColors.darkTextMuted
                                        : SigeColors.lightTextMuted,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Arraste leads para cá',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? SigeColors.darkTextMuted.withOpacity(0.6)
                                        : SigeColors.lightTextMuted.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        key: ValueKey(
                            widget.cards.map((e) => e.id).join(',')),
                        padding: const EdgeInsets.all(10),
                        itemCount: widget.cards.length,
                        itemBuilder: (context, index) {
                          final card = widget.cards[index];
                          return AtendimentoCardWidget(
                            key: ValueKey(card.id),
                            card: card,
                            color: widget.column.color,
                            onTap: () => widget.onCardTap(card),
                            onReassign: widget.onCardReassign != null
                                ? () => widget.onCardReassign!(card)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

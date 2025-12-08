import 'package:flutter/material.dart';
import 'package:module_atendimento/models/atendimento_card_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:module_atendimento/widgets/atendimento_card_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AtendimentoColumn extends StatefulWidget {
  final AtendimentoColumnModel column;
  final List<AtendimentoCardModel> cards;
  final Function(String, String) onCardMove;
  final VoidCallback onEdit;
  final Function(AtendimentoCardModel) onCardTap;
  final int columnIndex;

  const AtendimentoColumn({
    super.key,
    required this.column,
    required this.cards,
    required this.onCardMove,
    required this.onEdit,
    required this.onCardTap,
    required this.columnIndex,
  });

  @override
  State<AtendimentoColumn> createState() => _AtendimentoColumnState();
}

class _AtendimentoColumnState extends State<AtendimentoColumn>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isCardDraggingOver = false;
  late AnimationController _animationController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DragTarget<AtendimentoCardModel>(
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
        return MouseRegion(
          onEnter: (_) {
            setState(() => _isHovering = true);
            _animationController.forward();
          },
          onExit: (_) {
            setState(() => _isHovering = false);
            _animationController.reverse();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 320,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _isCardDraggingOver
                      ? colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isCardDraggingOver
                        ? colorScheme.primary.withOpacity(0.5)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header da coluna
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.column.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: widget.column.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.column.title,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.edit2, size: 16),
                            onPressed: widget.onEdit,
                            tooltip: 'Editar coluna',
                          ),
                          Text(
                            widget.cards.length.toString(),
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
                      child: widget.cards.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.inbox,
                                    size: 48,
                                    color:
                                        colorScheme.onSurface.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nenhum atendimento',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface
                                          .withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              // Adiciona uma key baseada nos IDs dos cards para forçar rebuild se a lista mudar
                              key: ValueKey(widget.cards.map((e) => e.id).join(',')),
                              itemCount: widget.cards.length,
                              itemBuilder: (context, index) {
                                final card = widget.cards[index];
                                return AtendimentoCardWidget(
                                  key: ValueKey(card.id),
                                  card: card,
                                  color: widget.column.color,
                                  onTap: () => widget.onCardTap(card),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -4,
                left: 0,
                right: 16, // Considerando a margem do Container
                child: Center(
                  child: SlideTransition(
                    position: _offsetAnimation,
                    child: ReorderableDragStartListener(
                      index: widget.columnIndex,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: kElevationToShadow[1],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: const Icon(
                            LucideIcons.gripHorizontal,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

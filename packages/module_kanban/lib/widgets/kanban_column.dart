import 'package:flutter/material.dart';
import 'package:module_kanban/models/kanban_card_model.dart';
import 'package:module_kanban/models/kanban_column_model.dart';
import 'package:module_kanban/widgets/kanban_card_widget.dart';
import 'package:lucide_icons/lucide_icons.dart';

class KanbanColumn extends StatefulWidget {
  final KanbanColumnModel column;
  final List<KanbanCardModel> cards;
  final Function(String, String) onCardMove;
  final VoidCallback onEdit;
  final int columnIndex;

  const KanbanColumn({
    super.key,
    required this.column,
    required this.cards,
    required this.onCardMove,
    required this.onEdit,
    required this.columnIndex,
  });

  @override
  State<KanbanColumn> createState() => _KanbanColumnState();
}

class _KanbanColumnState extends State<KanbanColumn>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
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

  void _handleHover(bool isHovering) {
    setState(() {
      _isHovering = isHovering;
      if (_isHovering) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.column.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.column.color.withOpacity(0.2),
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
                    color: _isHovering
                        ? widget.column.color.withOpacity(0.2)
                        : widget.column.color.withOpacity(0.1),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.cards.length.toString(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.edit, size: 16),
                        onPressed: widget.onEdit,
                      ),
                    ],
                  ),
                ),
                // Lista de cartões
                Expanded(
                  child: widget.cards.isEmpty
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          colorScheme.outline.withOpacity(0.6),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: widget.cards.length,
                          itemBuilder: (context, index) {
                            return KanbanCardWidget(
                              card: widget.cards[index],
                              onMove: (newColumn) => widget.onCardMove(
                                  widget.cards[index].id, newColumn),
                              color: widget.column.color,
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
            right: 0,
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
  }
}

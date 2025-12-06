import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_kanban/models/kanban_column_model.dart';
import 'package:module_kanban/providers/kanban_provider.dart';
import 'package:module_kanban/widgets/add_edit_kanban_column_dialog.dart';
import 'package:module_kanban/widgets/kanban_column.dart';
import 'package:module_kanban/widgets/add_kanban_card_dialog.dart';
import 'package:module_kanban/widgets/move_cards_and_delete_column_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math';

class KanbanScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const KanbanScreen({super.key, required this.tenantId});

  @override
  ConsumerState<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends ConsumerState<KanbanScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kanbanAsync = ref.watch(kanbanProvider(widget.tenantId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Quadro Kanban'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            onPressed: () => _showAddEditColumnDialog(context, ref),
          ),
        ],
      ),
      body: kanbanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar o quadro',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        data: (board) => Stack(
          children: [
            ReorderableListView.builder(
              buildDefaultDragHandles: false,
              scrollDirection: Axis.horizontal,
              scrollController: _scrollController,
              itemCount: board.columns.length,
              itemBuilder: (context, index) {
                final column = board.columns[index];
                final cards = board.cards
                    .where((card) => card.colunaStatus == column.id)
                    .toList();
                return SizedBox(
                  key: ValueKey(column.id),
                  width: 300,
                  child: KanbanColumn(
                    column: column,
                    cards: cards,
                    columnIndex: index,
                    onCardMove: (cardId, newColumnId) => ref
                        .read(kanbanProvider(widget.tenantId).notifier)
                        .moveCard(cardId, newColumnId),
                    onEdit: () =>
                        _showAddEditColumnDialog(context, ref, column: column),
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                ref
                    .read(kanbanProvider(widget.tenantId).notifier)
                    .reorderColumns(oldIndex, newIndex);
              },
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.offset - 300,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  heroTag: 'scroll_left',
                  child: const Icon(LucideIcons.arrowLeft),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      _scrollController.offset + 300,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  heroTag: 'scroll_right',
                  child: const Icon(LucideIcons.arrowRight),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCardDialog(context, ref),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Adicionar Card'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        heroTag: 'add_card',
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddKanbanCardDialog(
        tenantId: widget.tenantId,
        onSave: (card) =>
            ref.read(kanbanProvider(widget.tenantId).notifier).addCard(card),
      ),
    );
  }

  void _showAddEditColumnDialog(BuildContext context, WidgetRef ref,
      {KanbanColumnModel? column}) {
    final board = ref.read(kanbanProvider(widget.tenantId)).valueOrNull;
    showDialog(
      context: context,
      builder: (context) => AddEditKanbanColumnDialog(
        column: column,
        onSave: (title, color) {
          if (column != null) {
            // Update
            final updatedColumn =
                column.copyWith(title: title, colorValue: color.value);
            ref
                .read(kanbanProvider(widget.tenantId).notifier)
                .updateColumn(updatedColumn);
          } else {
            // Add
            final newColumn = KanbanColumnModel(
              id: _generateColumnId(),
              tenantId: widget.tenantId,
              title: title,
              colorValue: color.value,
              order: board?.columns.length ?? 0,
            );
            ref
                .read(kanbanProvider(widget.tenantId).notifier)
                .addColumn(newColumn);
          }
        },
        onDelete: column != null
            ? () => _handleDeleteColumn(context, ref, column)
            : null,
      ),
    );
  }

  String _generateColumnId() {
    return 'col_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  void _handleDeleteColumn(
      BuildContext context, WidgetRef ref, KanbanColumnModel column) {
    final board = ref.read(kanbanProvider(widget.tenantId)).valueOrNull;
    if (board == null) return;

    final cardsInColumn =
        board.cards.where((card) => card.colunaStatus == column.id).toList();
    final otherColumns = board.columns.where((c) => c.id != column.id).toList();

    if (cardsInColumn.isEmpty) {
      // Caso 1: Coluna vazia, apenas confirmação simples
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir Coluna?'),
          content: Text(
              'Você tem certeza que deseja excluir a coluna "${column.title}"? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(kanbanProvider(widget.tenantId).notifier)
                    .deleteColumn(column.id);
                Navigator.pop(context);
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } else {
      // Caso 2: Coluna com cards, pede para mover
      if (otherColumns.isEmpty) {
        // Não há outras colunas para mover os cards
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Não é possível excluir'),
            content: const Text(
                'Você não pode excluir esta coluna porque ela contém cards e não há outra coluna para movê-los. Crie outra coluna primeiro.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => MoveCardsAndDeleteColumnDialog(
          columnToDelete: column,
          cardsCount: cardsInColumn.length,
          otherColumns: otherColumns,
          onConfirm: (targetColumnId) {
            ref
                .read(kanbanProvider(widget.tenantId).notifier)
                .deleteColumn(column.id, targetColumnId: targetColumnId);
          },
        ),
      );
    }
  }
}

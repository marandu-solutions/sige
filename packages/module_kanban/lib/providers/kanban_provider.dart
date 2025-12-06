import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_kanban/models/kanban_board_model.dart';
import 'package:module_kanban/models/kanban_card_model.dart';
import 'package:module_kanban/models/kanban_column_model.dart';
import 'package:module_kanban/service/kanban_service.dart';

final kanbanProvider = AsyncNotifierProvider.autoDispose
    .family<KanbanNotifier, KanbanBoardModel, String>(() {
  return KanbanNotifier();
});

class KanbanNotifier
    extends AutoDisposeFamilyAsyncNotifier<KanbanBoardModel, String> {
  @override
  FutureOr<KanbanBoardModel> build(String tenantId) {
    return _getBoard(tenantId);
  }

  Future<KanbanBoardModel> _getBoard(String tenantId) {
    final kanbanService = ref.read(kanbanServiceProvider);
    return kanbanService.getBoard(tenantId);
  }

  Future<void> addCard(KanbanCardModel card) async {
    final kanbanService = ref.read(kanbanServiceProvider);

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedCards = [...currentBoard.cards, card];
      state = AsyncValue.data(currentBoard.copyWith(cards: updatedCards));
    }

    // Atualiza no Firebase em background
    try {
      await kanbanService.addCard(card);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(card.tenantId));
    }
  }

  Future<void> moveCard(String cardId, String newColumn) async {
    final kanbanService = ref.read(kanbanServiceProvider);
    final tenantId = arg;

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedCards = currentBoard.cards.map((card) {
        if (card.id == cardId) {
          return card.copyWith(colunaStatus: newColumn);
        }
        return card;
      }).toList();

      state = AsyncValue.data(currentBoard.copyWith(cards: updatedCards));
    }

    // Atualiza no Firebase em background
    try {
      await kanbanService.updateCardStatus(tenantId, cardId, newColumn);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(tenantId));
    }
  }

  Future<void> updatePriority(String cardId, String newPriority) async {
    final kanbanService = ref.read(kanbanServiceProvider);
    final tenantId = arg;

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedCards = currentBoard.cards.map((card) {
        if (card.id == cardId) {
          return card.copyWith(prioridade: newPriority);
        }
        return card;
      }).toList();

      state = AsyncValue.data(currentBoard.copyWith(cards: updatedCards));
    }

    // Atualiza no Firebase em background
    try {
      await kanbanService.updateCardPriority(tenantId, cardId, newPriority);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(tenantId));
    }
  }

  Future<void> addColumn(KanbanColumnModel column) async {
    final kanbanService = ref.read(kanbanServiceProvider);

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedColumns = [...currentBoard.columns, column];
      state = AsyncValue.data(currentBoard.copyWith(columns: updatedColumns));
    }

    // Atualiza no Firebase em background
    try {
      await kanbanService.addColumn(column);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(column.tenantId));
    }
  }

  Future<void> updateColumn(KanbanColumnModel column) async {
    final kanbanService = ref.read(kanbanServiceProvider);

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedColumns = currentBoard.columns.map((col) {
        if (col.id == column.id) {
          return column;
        }
        return col;
      }).toList();
      state = AsyncValue.data(currentBoard.copyWith(columns: updatedColumns));
    }

    // Atualiza no Firebase em background
    try {
      await kanbanService.updateColumn(column);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(column.tenantId));
    }
  }

  Future<void> deleteColumn(
    String columnId, {
    String? targetColumnId,
  }) async {
    final kanbanService = ref.read(kanbanServiceProvider);
    final tenantId = arg;

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      // Remove a coluna e seus cards
      final updatedColumns =
          currentBoard.columns.where((col) => col.id != columnId).toList();

      // Se houver cards para mover, atualiza eles também
      final updatedCards = currentBoard.cards
          .map((card) {
            if (card.colunaStatus == columnId && targetColumnId != null) {
              return card.copyWith(colunaStatus: targetColumnId);
            }
            return card;
          })
          .where((card) =>
              targetColumnId != null ? true : card.colunaStatus != columnId)
          .toList();

      state = AsyncValue.data(currentBoard.copyWith(
        columns: updatedColumns,
        cards: updatedCards,
      ));
    }

    // Atualiza no Firebase em background
    try {
      if (targetColumnId != null) {
        await kanbanService.deleteColumnAndMoveCards(
            tenantId, columnId, targetColumnId);
      } else {
        await kanbanService.deleteColumn(tenantId, columnId);
      }
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(tenantId));
    }
  }

  Future<void> reorderColumns(int oldIndex, int newIndex) async {
    final board = state.valueOrNull;
    if (board == null) return;

    final columns = List<KanbanColumnModel>.from(board.columns);
    final movedColumn = columns.removeAt(oldIndex);
    columns.insert(newIndex, movedColumn);

    state = AsyncValue.data(board.copyWith(columns: columns));

    final kanbanService = ref.read(kanbanServiceProvider);
    await kanbanService.updateColumnsOrder(arg, columns);
  }
}

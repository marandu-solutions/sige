import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/atendimento_board_model.dart';
import 'package:module_atendimento/models/atendimento_card_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:module_atendimento/models/mensagem_model.dart';
import 'package:module_atendimento/services/atendimento_service.dart';

final atendimentoProvider = AsyncNotifierProvider.family<AtendimentoNotifier,
    AtendimentoBoardModel, String>(() {
  return AtendimentoNotifier();
});

class AtendimentoNotifier
    extends FamilyAsyncNotifier<AtendimentoBoardModel, String> {
  @override
  FutureOr<AtendimentoBoardModel> build(String tenantId) {
    return _getBoard(tenantId);
  }

  Future<AtendimentoBoardModel> _getBoard(String tenantId) {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    return atendimentoService.getBoard(tenantId);
  }

  Future<void> addCard(AtendimentoCardModel card) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedCards = [...currentBoard.cards, card];
      state = AsyncValue.data(currentBoard.copyWith(cards: updatedCards));
    }

    // Atualiza no Firebase em background
    try {
      await atendimentoService.addCard(card);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(card.tenantId));
    }
  }

  Future<void> moveCard(String cardId, String newColumn) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
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
      await atendimentoService.updateCardStatus(tenantId, cardId, newColumn);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(tenantId));
    }
  }

  Future<void> updatePriority(String cardId, String newPriority) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
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
      await atendimentoService.updateCardPriority(
          tenantId, cardId, newPriority);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(tenantId));
    }
  }

  Future<void> addColumn(AtendimentoColumnModel column) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedColumns = [...currentBoard.columns, column];
      state = AsyncValue.data(currentBoard.copyWith(columns: updatedColumns));
    }

    // Atualiza no Firebase em background
    try {
      await atendimentoService.addColumn(column);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(column.tenantId));
    }
  }

  Future<void> updateColumn(AtendimentoColumnModel column) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);

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
      await atendimentoService.updateColumn(column);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(column.tenantId));
    }
  }

  Future<void> deleteColumn(String columnId, {String? targetColumnId}) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    final tenantId = arg;

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedColumns = currentBoard.columns
          .where((column) => column.id != columnId)
          .toList();

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
        await atendimentoService.deleteColumnAndMoveCards(
            tenantId, columnId, targetColumnId);
      } else {
        await atendimentoService.deleteColumn(tenantId, columnId);
      }
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(tenantId));
    }
  }

  Future<void> reorderColumns(int oldIndex, int newIndex) async {
    final board = state.valueOrNull;
    if (board == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final columns = List<AtendimentoColumnModel>.from(board.columns);
    final movedColumn = columns.removeAt(oldIndex);
    columns.insert(newIndex, movedColumn);

    // Atualiza o estado localmente sem loading
    state = AsyncValue.data(board.copyWith(columns: columns));

    // Atualiza no Firebase em background
    final atendimentoService = ref.read(atendimentoServiceProvider);
    try {
      await atendimentoService.updateColumnsOrder(arg, columns);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(arg));
    }
  }
}

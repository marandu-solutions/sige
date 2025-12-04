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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await kanbanService.addCard(card);
      return _getBoard(card.tenantId);
    });
  }

  Future<void> moveCard(String cardId, String newColumn) async {
    final kanbanService = ref.read(kanbanServiceProvider);
    final tenantId = arg;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await kanbanService.updateCardStatus(tenantId, cardId, newColumn);
      return _getBoard(tenantId);
    });
  }

  Future<void> updatePriority(String cardId, String newPriority) async {
    final kanbanService = ref.read(kanbanServiceProvider);
    final tenantId = arg;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await kanbanService.updateCardPriority(tenantId, cardId, newPriority);
      return _getBoard(tenantId);
    });
  }

  Future<void> addColumn(KanbanColumnModel column) async {
    final kanbanService = ref.read(kanbanServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await kanbanService.addColumn(column);
      return _getBoard(column.tenantId);
    });
  }

  Future<void> updateColumn(KanbanColumnModel column) async {
    final kanbanService = ref.read(kanbanServiceProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await kanbanService.updateColumn(column);
      return _getBoard(column.tenantId);
    });
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

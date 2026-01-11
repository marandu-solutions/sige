import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/atendimento_board_model.dart';
import 'package:module_atendimento/models/atendimento_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:module_atendimento/services/atendimento_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final atendimentoProvider = StreamNotifierProvider.family<AtendimentoNotifier,
    AtendimentoBoardModel, String>(() {
  return AtendimentoNotifier();
});

class AtendimentoNotifier
    extends FamilyStreamNotifier<AtendimentoBoardModel, String> {
  @override
  Stream<AtendimentoBoardModel> build(String tenantId) {
    // Observa o estado de autenticação para garantir que temos um usuário antes de buscar os dados.
    final userAsync = ref.watch(authStateProvider);

    // Se ainda estiver carregando a auth ou não tiver usuário, aguarda ou retorna vazio.
    if (userAsync.isLoading || userAsync.valueOrNull == null) {
      return Stream.value(AtendimentoBoardModel(cards: [], columns: []));
    }

    final atendimentoService = ref.read(atendimentoServiceProvider);

    return atendimentoService.getAllBoardStream(tenantId).map((board) {
      // Verificação de Consistência: Cards órfãos (com coluna_status inválido)
      if (board.columns.isNotEmpty) {
        final validColumnIds = board.columns.map((c) => c.id).toSet();
        final fixedCards = <AtendimentoModel>[];
        bool hasFixes = false;

        for (final card in board.cards) {
          if (!validColumnIds.contains(card.colunaStatus)) {
            // Card órfão detectado. Move para a primeira coluna.
            final targetColumnId = board.columns.first.id;

            // Dispara a correção no Firestore (fire and forget)
            _corrigirStatusCard(card.id, targetColumnId);

            // Corrige localmente para exibição imediata
            fixedCards.add(card.copyWith(colunaStatus: targetColumnId));
            hasFixes = true;
          } else {
            fixedCards.add(card);
          }
        }

        if (hasFixes) {
          return board.copyWith(cards: fixedCards);
        }
      }

      return board;
    });
  }

  Future<void> addCard(AtendimentoModel card) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    try {
      await atendimentoService.addCard(card);
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> moveCard(String cardId, String newColumn) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    final tenantId = arg;
    try {
      await atendimentoService.updateCardStatus(tenantId, cardId, newColumn);
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> updatePriority(String cardId, String newPriority) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    final tenantId = arg;
    try {
      await atendimentoService.updateCardPriority(
          tenantId, cardId, newPriority);
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> addColumn(AtendimentoColumnModel column) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    try {
      await atendimentoService.addColumn(column);
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> _corrigirStatusCard(String cardId, String newColumnId) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    try {
      await atendimentoService.updateCardStatus(arg, cardId, newColumnId);
    } catch (e) {
      print('Erro ao corrigir status do card: $e');
    }
  }

  Future<void> updateColumn(AtendimentoColumnModel column) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    try {
      await atendimentoService.updateColumn(column);
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> deleteColumn(String columnId, {String? targetColumnId}) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    final tenantId = arg;
    try {
      if (targetColumnId != null) {
        await atendimentoService.deleteColumnAndMoveCards(
            tenantId, columnId, targetColumnId);
      } else {
        await atendimentoService.deleteColumn(tenantId, columnId);
      }
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> reorderColumns(int oldIndex, int newIndex) async {
    // Para reordenação visual imediata, precisaríamos de estado local otimista.
    // Como estamos usando Stream puro, a atualização virá do Firestore.
    // Se o usuário sentir lag, podemos implementar cache local ou optimistic updates complexos.
    // Mas geralmente o Firestore é rápido o suficiente.

    final board = state.valueOrNull;
    if (board == null) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final columns = List<AtendimentoColumnModel>.from(board.columns);
    final movedColumn = columns.removeAt(oldIndex);
    columns.insert(newIndex, movedColumn);

    // Atualiza o backend
    final atendimentoService = ref.read(atendimentoServiceProvider);
    try {
      await atendimentoService.updateColumnsOrder(arg, columns);
    } catch (e) {
      ref.invalidateSelf();
    }
  }

  Future<void> resetUnreadCount(String cardId) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    final tenantId = arg;
    try {
      await atendimentoService.marcarMensagensComoLidas(tenantId, cardId);
    } catch (e) {
      ref.invalidateSelf();
    }
  }
}

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/atendimento_board_model.dart';
import 'package:module_atendimento/models/atendimento_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:module_atendimento/models/mensagem_model.dart';
import 'package:module_atendimento/services/atendimento_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final atendimentoProvider = AsyncNotifierProvider.family<AtendimentoNotifier,
    AtendimentoBoardModel, String>(() {
  return AtendimentoNotifier();
});

class AtendimentoNotifier
    extends FamilyAsyncNotifier<AtendimentoBoardModel, String> {
  @override
  FutureOr<AtendimentoBoardModel> build(String tenantId) async {
    // Observa o estado de autenticação para garantir que temos um usuário antes de buscar os dados.
    // Isso evita o erro de "Usuário não autenticado" e garante que buscamos o board correto (privado).
    final userAsync = ref.watch(authStateProvider);

    // Se ainda estiver carregando a auth ou não tiver usuário, aguarda ou retorna vazio.
    // O AuthWrapper deve lidar com o redirecionamento para login se não houver usuário.
    if (userAsync.isLoading || userAsync.valueOrNull == null) {
      return AtendimentoBoardModel(cards: [], columns: []);
    }

    return _getBoard(tenantId);
  }

  Future<AtendimentoBoardModel> _getBoard(String tenantId) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    final board = await atendimentoService.getBoard(tenantId);

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
  }

  Future<void> addCard(AtendimentoModel card) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedCards = [...currentBoard.cards, card];
      state = AsyncValue.data(currentBoard.copyWith(cards: updatedCards));
    }

    // Atualiza no Firebase em background
    try {
      final newId = await atendimentoService.addCard(card);

      // Atualiza o estado local com o ID real
      final updatedBoard = state.valueOrNull;
      if (updatedBoard != null) {
        final updatedCards = updatedBoard.cards.map((c) {
          if (c.id == card.id) {
            return c.copyWith(id: newId);
          }
          return c;
        }).toList();
        state = AsyncValue.data(updatedBoard.copyWith(cards: updatedCards));
      }
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
      final newId = await atendimentoService.addColumn(column);

      // Atualiza o estado local com o ID real
      final updatedBoard = state.valueOrNull;
      if (updatedBoard != null) {
        // Atualiza a coluna com o novo ID
        final updatedColumns = updatedBoard.columns.map((c) {
          if (c.id == column.id) {
            return c.copyWith(id: newId);
          }
          return c;
        }).toList();

        // Atualiza também os cards que possam ter sido movidos para esta coluna temporária
        // enquanto a requisição estava em andamento
        final updatedCards = updatedBoard.cards.map((c) {
          if (c.colunaStatus == column.id) {
            // Se o card já foi salvo no banco com o ID temporário da coluna,
            // precisamos atualizar o card no banco também.
            // Mas aqui estamos apenas atualizando o estado local.
            // O ideal seria disparar um updateCardStatus, mas vamos focar na consistência local primeiro.
            // Se o usuário moveu o card, moveCard foi chamado.
            // Se moveCard foi chamado com o ID temporário, ele salvou no banco com ID temporário.
            // Então precisamos corrigir isso no banco também.
            _corrigirStatusCard(c.id, newId);
            return c.copyWith(colunaStatus: newId);
          }
          return c;
        }).toList();

        state = AsyncValue.data(updatedBoard.copyWith(
            columns: updatedColumns, cards: updatedCards));
      }
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(column.tenantId));
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

  Future<void> resetUnreadCount(String cardId) async {
    final atendimentoService = ref.read(atendimentoServiceProvider);
    final tenantId = arg;

    // Atualiza o estado localmente sem loading
    final currentBoard = state.valueOrNull;
    if (currentBoard != null) {
      final updatedCards = currentBoard.cards.map((card) {
        if (card.id == cardId) {
          return card.copyWith(mensagensNaoLidas: 0);
        }
        return card;
      }).toList();

      state = AsyncValue.data(currentBoard.copyWith(cards: updatedCards));
    }

    // Atualiza no Firebase em background
    try {
      await atendimentoService.marcarMensagensComoLidas(tenantId, cardId);
    } catch (e) {
      // Se houver erro, recarrega o board completo
      state = await AsyncValue.guard(() => _getBoard(tenantId));
    }
  }
}

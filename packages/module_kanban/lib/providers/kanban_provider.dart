import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_kanban/models/kanban_card_model.dart';

/// Provider para gerenciar o estado do Kanban
final kanbanProvider =
    StateNotifierProvider<KanbanNotifier, AsyncValue<List<KanbanCardModel>>>(
        (ref) {
  return KanbanNotifier();
});

/// Notifier para gerenciar cartões Kanban
class KanbanNotifier extends StateNotifier<AsyncValue<List<KanbanCardModel>>> {
  KanbanNotifier() : super(const AsyncValue.loading());

  /// Carrega cartões para um tenant específico
  Future<void> loadCards(String tenantId) async {
    state = const AsyncValue.loading();
    try {
      // Implementar busca no Firestore
      state = const AsyncValue.data([]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Adiciona novo cartão
  Future<void> addCard(KanbanCardModel card) async {
    state.whenData((currentCards) {
      state = AsyncValue.data([...currentCards, card]);
    });
  }

  /// Move cartão entre colunas
  Future<void> moveCard(String cardId, String newColumn) async {
    state.whenData((currentCards) {
      final updatedCards = currentCards.map((card) {
        if (card.id == cardId) {
          return card.copyWith(colunaStatus: newColumn);
        }
        return card;
      }).toList();
      state = AsyncValue.data(updatedCards);
    });
  }

  /// Atualiza prioridade do cartão
  Future<void> updatePriority(String cardId, String newPriority) async {
    state.whenData((currentCards) {
      final updatedCards = currentCards.map((card) {
        if (card.id == cardId) {
          return card.copyWith(prioridade: newPriority);
        }
        return card;
      }).toList();
      state = AsyncValue.data(updatedCards);
    });
  }
}

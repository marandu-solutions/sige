import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_estoque/models/stock_item_model.dart';

/// Provider para gerenciar o estado do estoque
final stockProvider =
    StateNotifierProvider<StockNotifier, AsyncValue<List<StockItemModel>>>(
        (ref) {
  return StockNotifier();
});

/// Notifier para gerenciar operações de estoque
class StockNotifier extends StateNotifier<AsyncValue<List<StockItemModel>>> {
  StockNotifier() : super(const AsyncValue.loading());

  /// Carrega itens do estoque para um tenant específico
  Future<void> loadStockItems(String tenantId) async {
    state = const AsyncValue.loading();
    try {
      // Implementar busca no Firestore
      state = const AsyncValue.data([]);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Adiciona novo item ao estoque
  Future<void> addStockItem(StockItemModel item) async {
    state.whenData((currentItems) {
      state = AsyncValue.data([...currentItems, item]);
    });
  }

  /// Atualiza quantidade de um item
  Future<void> updateQuantity(String itemId, double newQuantity) async {
    state.whenData((currentItems) {
      final updatedItems = currentItems.map((item) {
        if (item.id == itemId) {
          return item.copyWith(qtdAtual: newQuantity);
        }
        return item;
      }).toList();
      state = AsyncValue.data(updatedItems);
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_item_model.dart';
import '../services/stock_service.dart';

/// Provider para o serviço de estoque
final stockServiceProvider = Provider<StockService>((ref) {
  return StockService();
});

/// Notifier para gerenciar a lista de itens de estoque do tenant
class StockNotifier extends FamilyAsyncNotifier<List<StockItemModel>, String> {
  @override
  Future<List<StockItemModel>> build(String arg) async {
    final service = ref.watch(stockServiceProvider);
    return service.loadStockItems(arg);
  }

  Future<void> addItem(StockItemModel item) async {
    await ref.read(stockServiceProvider).addStockItem(arg, item);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateItem(StockItemModel item) async {
    await ref.read(stockServiceProvider).updateStockItem(arg, item);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteItem(String itemId) async {
    await ref.read(stockServiceProvider).deleteStockItem(arg, itemId);
    ref.invalidateSelf();
    await future;
  }
}

/// Provider de estoque parametrizado por tenantId
final stockProvider =
    AsyncNotifierProvider.family<StockNotifier, List<StockItemModel>, String>(
  StockNotifier.new,
);

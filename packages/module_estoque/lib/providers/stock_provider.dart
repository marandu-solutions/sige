import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/stock_item_model.dart';
import '../services/stock_service.dart';

part 'stock_provider.g.dart';

/// Provider for the StockService dependency.
@riverpod
StockService stockService(StockServiceRef ref) {
  return StockService();
}

/// The main provider for the stock state, using a family to pass the tenantId.
///
/// This provider will manage the state of the stock items list (`AsyncValue<List<StockItemModel>>`).
@riverpod
class Stock extends _$Stock {
  /// The build method is responsible for fetching the initial list of items.
  /// It will be called automatically when the provider is first read,
  /// and will be re-executed if the `tenantId` changes or if the provider is invalidated.
  @override
  Future<List<StockItemModel>> build(String tenantId) async {
    return ref.watch(stockServiceProvider).loadStockItems(tenantId);
  }

  /// Adds a new item to the stock.
  ///
  /// After adding the item to the backend via [StockService], it invalidates
  /// the provider to trigger a refetch of the entire list, ensuring UI consistency.
  Future<void> addItem(StockItemModel item) async {
    // `arg` is the tenantId passed to the family provider.
    await ref.read(stockServiceProvider).addStockItem(tenantId, item);
    // Invalidate the provider to re-run the build method and get the fresh list.
    ref.invalidateSelf();
    // By awaiting `future`, we ensure the caller can wait until the state is updated.
    await future;
  }

  /// Updates an existing item in the stock.
  ///
  /// Similar to `addItem`, it invalidates the provider to trigger a refetch.
  Future<void> updateItem(StockItemModel item) async {
    await ref.read(stockServiceProvider).updateStockItem(tenantId, item);
    ref.invalidateSelf();
    await future;
  }

  /// Deletes an item from the stock.
  ///
  /// After deleting the item, it invalidates the provider to get the updated list.
  Future<void> deleteItem(String itemId) async {
    await ref.read(stockServiceProvider).deleteStockItem(tenantId, itemId);
    ref.invalidateSelf();
    await future;
  }
}

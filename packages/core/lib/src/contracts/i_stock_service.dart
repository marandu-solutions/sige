abstract class IStockService {
  /// Fetches a list of available stock items for a given tenant.
  Future<List<Map<String, dynamic>>> getAvailableStock(String tenantId);
  
  /// Checks if a specific item is in stock
  Future<bool> hasStock(String tenantId, String itemId, int quantity);
  
  /// Decrements stock when a sale/atendimento is closed
  Future<bool> decrementStock(String tenantId, String itemId, int quantity);
}

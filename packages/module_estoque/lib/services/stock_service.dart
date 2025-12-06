import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stock_item_model.dart';

/// Service para gerenciar operações de estoque no Firebase
class StockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtém a coleção de estoque para um tenant específico
  CollectionReference<Map<String, dynamic>> _getStockCollection(
      String tenantId) {
    return _firestore.collection('tenant').doc(tenantId).collection('estoque');
  }

  /// Carrega todos os itens do estoque para um tenant
  Future<List<StockItemModel>> loadStockItems(String tenantId) async {
    try {
      final snapshot = await _getStockCollection(tenantId).get();
      return snapshot.docs
          .map((doc) => StockItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao carregar itens do estoque: $e');
    }
  }

  /// Adiciona um novo item ao estoque
  Future<StockItemModel> addStockItem(
      String tenantId, StockItemModel item) async {
    try {
      final docRef = await _getStockCollection(tenantId).add(item.toMap());
      return item.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erro ao adicionar item ao estoque: $e');
    }
  }

  /// Atualiza um item existente no estoque
  Future<void> updateStockItem(String tenantId, StockItemModel item) async {
    try {
      await _getStockCollection(tenantId).doc(item.id).update(item.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar item do estoque: $e');
    }
  }

  /// Remove um item do estoque
  Future<void> deleteStockItem(String tenantId, String itemId) async {
    try {
      await _getStockCollection(tenantId).doc(itemId).delete();
    } catch (e) {
      throw Exception('Erro ao remover item do estoque: $e');
    }
  }

  /// Atualiza apenas a quantidade de um item específico
  Future<void> updateQuantity(
      String tenantId, String itemId, double newQuantity) async {
    try {
      await _getStockCollection(tenantId).doc(itemId).update({
        'qtd_atual': newQuantity,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar quantidade do item: $e');
    }
  }

  /// Busca itens por nome ou SKU
  Future<List<StockItemModel>> searchStockItems(
      String tenantId, String query) async {
    try {
      final snapshot = await _getStockCollection(tenantId)
          .where('nome_produto', isGreaterThanOrEqualTo: query)
          .where('nome_produto', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => StockItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar itens do estoque: $e');
    }
  }
}

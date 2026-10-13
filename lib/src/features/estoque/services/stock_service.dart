import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sige/src/core/core.dart';
import '../models/stock_item_model.dart';

/// Service para gerenciar operações de estoque no Firebase
class StockService implements IStockService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StockService() {
    ServiceRegistry().register<IStockService>(this);
  }

  @override
  Future<List<StockItemLookup>> searchAvailableStock(String tenantId, String query) async {
    final items = await loadStockItems(tenantId);
    final q = query.toLowerCase();
    return items
        .where((i) =>
            i.nomeProduto.toLowerCase().contains(q) ||
            i.sku.toLowerCase().contains(q))
        .map((i) => StockItemLookup(
              id: i.id,
              nome: i.nomeProduto,
              preco: i.precoVenda,
              quantidadeEstoque: i.qtdAtual.toInt(),
              grade: i.unidadeMedida,
            ))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAvailableStock(String tenantId) async {
    final items = await loadStockItems(tenantId);
    return items.map((i) => {
      'id': i.id,
      'nome': i.nomeProduto,
      'sku': i.sku,
      'qtd': i.qtdAtual,
      'preco': i.precoVenda,
      'unidade': i.unidadeMedida,
    }).toList();
  }

  @override
  Future<bool> hasStock(String tenantId, String itemId, int quantity) async {
    try {
      final doc = await _getStockCollection(tenantId).doc(itemId).get();
      if (!doc.exists || doc.data() == null) return false;
      final qtd = (doc.data()!['qtd_atual'] ?? 0.0) as num;
      return qtd >= quantity;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> decrementStock(String tenantId, String itemId, int quantity) async {
    try {
      return await _firestore.runTransaction<bool>((tx) async {
        final ref = _getStockCollection(tenantId).doc(itemId);
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) return false;
        final currentQtd = (snapshot.data()!['qtd_atual'] ?? 0.0) as num;
        if (currentQtd < quantity) return false;
        tx.update(ref, {'qtd_atual': currentQtd - quantity});
        return true;
      });
    } catch (_) {
      return false;
    }
  }

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

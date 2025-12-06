import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_kanban/models/kanban_board_model.dart';
import 'package:module_kanban/models/kanban_card_model.dart';
import 'package:module_kanban/models/kanban_column_model.dart';

final kanbanServiceProvider = Provider<KanbanService>((ref) {
  return KanbanService(FirebaseFirestore.instance);
});

class KanbanService {
  final FirebaseFirestore _firestore;

  KanbanService(this._firestore);

  // Coleções
  CollectionReference<KanbanCardModel> _cardsRef(String tenantId) => _firestore
      .collection('tenant')
      .doc(tenantId)
      .collection('kanban')
      .doc('board')
      .collection('cards')
      .withConverter<KanbanCardModel>(
        fromFirestore: (snapshot, _) => KanbanCardModel.fromFirestore(snapshot),
        toFirestore: (card, _) => card.toMap(),
      );

  CollectionReference<KanbanColumnModel> _columnsRef(String tenantId) =>
      _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('kanban')
          .doc('board')
          .collection('columns')
          .withConverter<KanbanColumnModel>(
            fromFirestore: (snapshot, _) =>
                KanbanColumnModel.fromFirestore(snapshot),
            toFirestore: (column, _) => column.toMap(),
          );

  // Operações do Board
  Future<KanbanBoardModel> getBoard(String tenantId) async {
    final cardsFuture = getCards(tenantId);
    final columnsFuture = getColumns(tenantId);

    final results = await Future.wait([cardsFuture, columnsFuture]);
    return KanbanBoardModel(
      cards: results[0] as List<KanbanCardModel>,
      columns: results[1] as List<KanbanColumnModel>,
    );
  }

  // Operações de Coluna
  Future<List<KanbanColumnModel>> getColumns(String tenantId) async {
    final snapshot = await _columnsRef(tenantId).orderBy('order').get();
    if (snapshot.docs.isEmpty) {
      return [];
    }
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addColumn(KanbanColumnModel column) async {
    await _columnsRef(column.tenantId).doc(column.id).set(column);
  }

  Future<void> updateColumn(KanbanColumnModel column) async {
    await _columnsRef(column.tenantId).doc(column.id).update(column.toMap());
  }

  Future<void> updateColumnsOrder(
      String tenantId, List<KanbanColumnModel> columns) async {
    final batch = _firestore.batch();
    for (int i = 0; i < columns.length; i++) {
      final column = columns[i];
      final docRef = _columnsRef(tenantId).doc(column.id);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  Future<void> deleteColumn(String tenantId, String columnId) async {
    await _columnsRef(tenantId).doc(columnId).delete();
  }

  Future<void> deleteColumnAndMoveCards(
      String tenantId, String columnIdToDelete, String targetColumnId) async {
    final WriteBatch batch = _firestore.batch();

    // 1. Pega os cards da coluna a ser excluída
    final cardsSnapshot = await _cardsRef(tenantId)
        .where('coluna_status', isEqualTo: columnIdToDelete)
        .get();

    // 2. Atualiza cada card para a nova coluna
    for (final doc in cardsSnapshot.docs) {
      batch.update(doc.reference, {'coluna_status': targetColumnId});
    }

    // 3. Deleta a coluna
    final columnRef = _columnsRef(tenantId).doc(columnIdToDelete);
    batch.delete(columnRef);

    // 4. Commita o batch
    await batch.commit();
  }

  // Operações de Cartão
  Future<List<KanbanCardModel>> getCards(String tenantId) async {
    final snapshot = await _cardsRef(tenantId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addCard(KanbanCardModel card) async {
    await _cardsRef(card.tenantId).add(card);
  }

  Future<void> updateCardStatus(
      String tenantId, String cardId, String newStatus) async {
    await _cardsRef(tenantId).doc(cardId).update({'coluna_status': newStatus});
  }

  Future<void> updateCardPriority(
      String tenantId, String cardId, String newPriority) async {
    await _cardsRef(tenantId).doc(cardId).update({'prioridade': newPriority});
  }
}

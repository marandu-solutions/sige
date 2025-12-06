import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/atendimento_board_model.dart';
import 'package:module_atendimento/models/atendimento_card_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:module_atendimento/models/mensagem_model.dart';

final atendimentoServiceProvider = Provider<AtendimentoService>((ref) {
  return AtendimentoService(FirebaseFirestore.instance);
});

class AtendimentoService {
  final FirebaseFirestore _firestore;

  AtendimentoService(this._firestore);

  // Coleções
  CollectionReference<AtendimentoCardModel> _cardsRef(String tenantId) =>
      _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('atendimento')
          .doc('board')
          .collection('cards')
          .withConverter<AtendimentoCardModel>(
            fromFirestore: (snapshot, _) =>
                AtendimentoCardModel.fromFirestore(snapshot),
            toFirestore: (card, _) => card.toMap(),
          );

  CollectionReference<AtendimentoColumnModel> _columnsRef(String tenantId) =>
      _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('atendimento')
          .doc('board')
          .collection('columns')
          .withConverter<AtendimentoColumnModel>(
            fromFirestore: (snapshot, _) =>
                AtendimentoColumnModel.fromFirestore(snapshot),
            toFirestore: (column, _) => column.toMap(),
          );

  CollectionReference<MensagemModel> _mensagensRef(
          String tenantId, String atendimentoId) =>
      _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('atendimento')
          .doc('board')
          .collection('cards')
          .doc(atendimentoId)
          .collection('mensagens')
          .withConverter<MensagemModel>(
            fromFirestore: (snapshot, _) =>
                MensagemModel.fromFirestore(snapshot),
            toFirestore: (mensagem, _) => mensagem.toMap(),
          );

  // Operações do Board
  Future<AtendimentoBoardModel> getBoard(String tenantId) async {
    final cardsFuture = getCards(tenantId);
    final columnsFuture = getColumns(tenantId);

    final results = await Future.wait([cardsFuture, columnsFuture]);
    return AtendimentoBoardModel(
      cards: results[0] as List<AtendimentoCardModel>,
      columns: results[1] as List<AtendimentoColumnModel>,
    );
  }

  // Operações de Cards
  Future<List<AtendimentoCardModel>> getCards(String tenantId) async {
    final snapshot = await _cardsRef(tenantId).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addCard(AtendimentoCardModel card) async {
    await _cardsRef(card.tenantId).add(card);
  }

  Future<void> updateCard(AtendimentoCardModel card) async {
    await _cardsRef(card.tenantId).doc(card.id).set(card);
  }

  Future<void> updateCardStatus(
      String tenantId, String cardId, String newStatus) async {
    await _cardsRef(tenantId).doc(cardId).update({
      'coluna_status': newStatus,
    });
  }

  Future<void> updateCardPriority(
      String tenantId, String cardId, String newPriority) async {
    await _cardsRef(tenantId).doc(cardId).update({
      'prioridade': newPriority,
    });
  }

  Future<void> deleteCard(String tenantId, String cardId) async {
    await _cardsRef(tenantId).doc(cardId).delete();
  }

  // Operações de Colunas
  Future<List<AtendimentoColumnModel>> getColumns(String tenantId) async {
    final snapshot =
        await _columnsRef(tenantId).orderBy('order', descending: false).get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addColumn(AtendimentoColumnModel column) async {
    await _columnsRef(column.tenantId).add(column);
  }

  Future<void> updateColumn(AtendimentoColumnModel column) async {
    await _columnsRef(column.tenantId).doc(column.id).set(column);
  }

  Future<void> deleteColumn(String tenantId, String columnId) async {
    await _columnsRef(tenantId).doc(columnId).delete();
  }

  Future<void> deleteColumnAndMoveCards(
    String tenantId,
    String columnId,
    String targetColumnId,
  ) async {
    final batch = _firestore.batch();

    // Move os cards para a coluna de destino
    final cardsSnapshot = await _cardsRef(tenantId)
        .where('coluna_status', isEqualTo: columnId)
        .get();

    for (final doc in cardsSnapshot.docs) {
      batch.update(doc.reference, {'coluna_status': targetColumnId});
    }

    // Deleta a coluna
    batch.delete(_columnsRef(tenantId).doc(columnId));

    await batch.commit();
  }

  Future<void> updateColumnsOrder(
      String tenantId, List<AtendimentoColumnModel> columns) async {
    final batch = _firestore.batch();

    for (int i = 0; i < columns.length; i++) {
      final column = columns[i];
      batch.update(
        _columnsRef(tenantId).doc(column.id),
        {'order': i},
      );
    }

    await batch.commit();
  }

  // Operações de Mensagens
  Future<List<MensagemModel>> getMensagens(
      String tenantId, String atendimentoId) async {
    final snapshot = await _mensagensRef(tenantId, atendimentoId)
        .orderBy('data_envio', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addMensagem(MensagemModel mensagem) async {
    await _mensagensRef(mensagem.tenantId, mensagem.atendimentoId)
        .add(mensagem);

    // Atualiza o card com a última mensagem
    await _cardsRef(mensagem.tenantId).doc(mensagem.atendimentoId).update({
      'ultima_mensagem': mensagem.texto,
      'ultima_mensagem_data': Timestamp.fromDate(mensagem.dataEnvio),
      'mensagens_nao_lidas': FieldValue.increment(mensagem.isUsuario ? 0 : 1),
    });
  }

  Future<void> marcarMensagensComoLidas(
      String tenantId, String atendimentoId) async {
    await _cardsRef(tenantId).doc(atendimentoId).update({
      'mensagens_nao_lidas': 0,
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  CollectionReference<AtendimentoColumnModel> _columnsRef(String tenantId) {
    final user = FirebaseAuth.instance.currentUser;
    // Se não houver usuário logado (ex: durante logout ou inicialização), retorna a referência padrão do tenant.
    // Mas o ideal é que cada usuário tenha suas colunas.
    // A estrutura ideal seria: tenant/{tenantId}/users/{userId}/atendimento/board/columns
    // Mas para manter compatibilidade com a estrutura atual (tenant/{tenantId}/atendimento/board/columns),
    // podemos continuar usando a estrutura atual SE o requisito for um board compartilhado.
    // O usuário disse: "o kanban é algo individual do usuário logado no sistema... mas do jeito que essa collection está no firebase eu acredito que não esteja tornando isso possivel".
    
    // CORREÇÃO: Para tornar individual por usuário, precisamos mudar a referência para incluir o ID do usuário.
    if (user != null) {
      return _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('users')
          .doc(user.uid)
          .collection('atendimento_board_columns') // Nome da coleção de colunas pessoais
          .withConverter<AtendimentoColumnModel>(
            fromFirestore: (snapshot, _) =>
                AtendimentoColumnModel.fromFirestore(snapshot),
            toFirestore: (column, _) => column.toMap(),
          );
    }
    
    // Fallback para board compartilhado se não tiver user (não deve acontecer em uso normal)
    return _firestore
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
  }

  CollectionReference<MensagemModel> _mensagensRef(String tenantId) =>
      _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('interactions')
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Filtra apenas os leads atribuídos ao funcionário logado
    final snapshot = await _cardsRef(tenantId)
        .where('funcionario_responsavel_id', isEqualTo: user.uid)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addCard(AtendimentoCardModel card) async {
    final user = FirebaseAuth.instance.currentUser;

    // Se o card não tiver funcionário responsável, atribui ao usuário atual (caso o próprio funcionário crie)
    final cardToSave = card.funcionarioResponsavelId == null && user != null
        ? card.copyWith(funcionarioResponsavelId: user.uid)
        : card;

    await _cardsRef(cardToSave.tenantId).add(cardToSave);
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
    final snapshot = await _mensagensRef(tenantId)
        .where('atendimento_id', isEqualTo: atendimentoId)
        .orderBy('data_envio', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> addMensagem(MensagemModel mensagem) async {
    await _mensagensRef(mensagem.tenantId).add(mensagem);

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

  // Envio de Mensagem para Integração (N8N)
  Future<void> sendMessage(
      String tenantId, String leadId, String customerPhone, String text) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final mensagem = MensagemModel(
        id: '', // Será gerado pelo Firestore
        tenantId: tenantId,
        atendimentoId: leadId,
        texto: text,
        isUsuario: true,
        dataEnvio: DateTime.now(),
        status: 'pending_send',
        remetenteUid: user.uid,
        remetenteTipo: 'vendedor',
        telefoneDestino: customerPhone,
      );

      // Salva na coleção de interações do tenant
      await _mensagensRef(tenantId).add(mensagem);
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }
}

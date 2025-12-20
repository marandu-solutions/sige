import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/atendimento_board_model.dart';
import 'package:module_atendimento/models/atendimento_model.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:module_atendimento/models/mensagem_model.dart';

final atendimentoServiceProvider = Provider<AtendimentoService>((ref) {
  return AtendimentoService(FirebaseFirestore.instance);
});

class AtendimentoService {
  final FirebaseFirestore _firestore;

  AtendimentoService(this._firestore);

  // Coleções
  CollectionReference<AtendimentoModel> _cardsRef(String tenantId) => _firestore
      .collection('tenant')
      .doc(tenantId)
      .collection('atendimento')
      .doc('board')
      .collection('historico')
      .withConverter<AtendimentoModel>(
        fromFirestore: (snapshot, _) =>
            AtendimentoModel.fromFirestore(snapshot),
        toFirestore: (card, _) => card.toMap(),
      );

  CollectionReference<AtendimentoColumnModel> _columnsRef(String tenantId) {
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
    final columnsFuture = getColumns(tenantId);
    // Busca os cards (getCards já filtra os arquivados)
    var cardsFuture = getCards(tenantId);

    final results = await Future.wait([cardsFuture, columnsFuture]);
    var cards = results[0] as List<AtendimentoModel>;
    final columns = results[1] as List<AtendimentoColumnModel>;

    return _processBoardData(tenantId, cards, columns);
  }

  Future<AtendimentoBoardModel> getAllBoard(String tenantId) async {
    final columnsFuture = getColumns(tenantId);
    // Busca TODOS os cards (getAllCards já filtra os arquivados)
    var cardsFuture = getAllCards(tenantId);

    final results = await Future.wait([cardsFuture, columnsFuture]);
    var cards = results[0] as List<AtendimentoModel>;
    final columns = results[1] as List<AtendimentoColumnModel>;

    return _processBoardData(tenantId, cards, columns);
  }

  Future<AtendimentoBoardModel> _processBoardData(
      String tenantId,
      List<AtendimentoModel> cards,
      List<AtendimentoColumnModel> columns) async {
    // Lógica de Limpeza: Arquivar cards na coluna "Finalizados" > 24h
    // Procura por coluna que contenha "Finalizado" ou "Concluido" no título (case insensitive)
    AtendimentoColumnModel? finalizadosColumn;
    try {
      finalizadosColumn = columns.firstWhere(
        (c) {
          final title = c.title.toLowerCase();
          return title.contains('finalizado') || title.contains('concluido');
        },
      );
    } catch (_) {
      // Nenhuma coluna de finalizados encontrada
    }

    if (finalizadosColumn != null) {
      final now = DateTime.now();
      final cardsToArchive = <AtendimentoModel>[];
      final finalizadosId = finalizadosColumn.id;

      for (final card in cards) {
        if (card.colunaStatus == finalizadosId &&
            card.dataEntradaColuna != null) {
          final diff = now.difference(card.dataEntradaColuna!);
          if (diff.inHours >= 24) {
            cardsToArchive.add(card);
          }
        }
      }

      if (cardsToArchive.isNotEmpty) {
        // Arquiva no Firestore
        for (final card in cardsToArchive) {
          await _archiveCard(tenantId, card.id);
        }

        // Remove da lista local para atualizar a UI imediatamente
        cards = cards
            .where(
                (c) => !cardsToArchive.any((archived) => archived.id == c.id))
            .toList();
      }
    }

    return AtendimentoBoardModel(
      cards: cards,
      columns: columns,
    );
  }

  // Operações de Cards
  Future<List<AtendimentoModel>> getCards(String tenantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Filtra apenas os leads atribuídos ao funcionário logado
    final snapshot = await _cardsRef(tenantId)
        .where('funcionario_responsavel_id', isEqualTo: user.uid)
        .get();

    // Filtra localmente cards arquivados
    return snapshot.docs
        .map((doc) => doc.data())
        .where((card) => card.status != 'arquivado')
        .toList();
  }

  Future<List<AtendimentoModel>> getAllCards(String tenantId) async {
    // Busca todos os cards do tenant sem filtro de usuário
    final snapshot = await _cardsRef(tenantId).get();

    // Filtra localmente cards arquivados
    return snapshot.docs
        .map((doc) => doc.data())
        .where((card) => card.status != 'arquivado')
        .toList();
  }

  Future<String> addCard(AtendimentoModel card) async {
    final user = FirebaseAuth.instance.currentUser;

    // Se o card não tiver funcionário responsável, atribui ao usuário atual (caso o próprio funcionário crie)
    final cardToSave = card.funcionarioResponsavelId == null && user != null
        ? card.copyWith(funcionarioResponsavelId: user.uid)
        : card;

    final docRef = await _cardsRef(cardToSave.tenantId).add(cardToSave);
    return docRef.id;
  }

  Future<void> updateCard(AtendimentoModel card) async {
    final cardToSave = card.copyWith(
      dataUltimaAtualizacao: DateTime.now(),
    );
    await _cardsRef(card.tenantId).doc(card.id).set(cardToSave);
  }

  Future<void> updateCardStatus(
      String tenantId, String cardId, String newColumnId) async {
    // Ao mover de coluna, atualizamos data_entrada_coluna
    await _cardsRef(tenantId).doc(cardId).update({
      'coluna_status': newColumnId,
      'data_entrada_coluna': FieldValue.serverTimestamp(),
      'data_ultima_atualizacao': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCardPriority(
      String tenantId, String cardId, String newPriority) async {
    await _cardsRef(tenantId).doc(cardId).update({
      'prioridade': newPriority,
      'data_ultima_atualizacao': FieldValue.serverTimestamp(),
    });
  }

  // Método interno para arquivar (Soft Delete do Kanban)
  Future<void> _archiveCard(String tenantId, String cardId) async {
    await _cardsRef(tenantId).doc(cardId).update({
      'status': 'arquivado',
      'data_ultima_atualizacao': FieldValue.serverTimestamp(),
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

  Future<String> addColumn(AtendimentoColumnModel column) async {
    final docRef = await _columnsRef(column.tenantId).add(column);
    return docRef.id;
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
      batch.update(doc.reference, {
        'coluna_status': targetColumnId,
        'data_entrada_coluna': FieldValue.serverTimestamp(),
        'data_ultima_atualizacao': FieldValue.serverTimestamp(),
      });
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
  Stream<List<MensagemModel>> getMensagensStream(
      String tenantId, String atendimentoId) {
    return _mensagensRef(tenantId)
        .where('atendimento_id', isEqualTo: atendimentoId)
        .orderBy('data_envio', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

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
      'data_ultima_atualizacao': FieldValue.serverTimestamp(),
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
      String tenantId, String atendimentoId, String customerPhone, String text,
      {String? leadId, String? mensagemTipo}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final mensagem = MensagemModel(
        id: '', // Será gerado pelo Firestore
        tenantId: tenantId,
        atendimentoId: atendimentoId,
        texto: text,
        isUsuario: true,
        dataEnvio: DateTime.now(),
        status: 'pending_send',
        remetenteUid: user.uid,
        remetenteTipo: 'vendedor',
        telefoneDestino: customerPhone,
        leadId: leadId,
        mensagemTipo: mensagemTipo,
      );

      // Salva na coleção de interações do tenant
      await _mensagensRef(tenantId).add(mensagem);
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }
}

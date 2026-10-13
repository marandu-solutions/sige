import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/features/atendimento/models/atendimento_board_model.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/models/atendimento_column_model.dart';
import 'package:sige/src/features/atendimento/models/mensagem_model.dart';

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

  Stream<AtendimentoBoardModel> getBoardStream(String tenantId) {
    final columnsStream = getColumnsStream(tenantId);
    final cardsStream = getCardsStream(tenantId);

    return _combineLatest2(columnsStream, cardsStream, (columns, cards) async {
      return _processBoardData(tenantId, cards, columns);
    });
  }

  Stream<AtendimentoBoardModel> getAllBoardStream(String tenantId) {
    final columnsStream = getColumnsStream(tenantId);
    final cardsStream = getAllCardsStream(tenantId);

    return _combineLatest2(columnsStream, cardsStream, (columns, cards) async {
      return _processBoardData(tenantId, cards, columns);
    });
  }

  Stream<R> _combineLatest2<A, B, R>(
    Stream<A> streamA,
    Stream<B> streamB,
    Future<R> Function(A a, B b) combiner,
  ) {
    final controller = StreamController<R>();
    A? latestA;
    B? latestB;
    bool hasA = false;
    bool hasB = false;

    void emit() async {
      if (hasA && hasB) {
        try {
          final result = await combiner(latestA as A, latestB as B);
          controller.add(result);
        } catch (e) {
          controller.addError(e);
        }
      }
    }

    final subA = streamA.listen(
      (a) {
        latestA = a;
        hasA = true;
        emit();
      },
      onError: controller.addError,
    );

    final subB = streamB.listen(
      (b) {
        latestB = b;
        hasB = true;
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () {
      subA.cancel();
      subB.cancel();
    };

    return controller.stream;
  }

  Future<AtendimentoBoardModel> _processBoardData(
      String tenantId,
      List<AtendimentoModel> cards,
      List<AtendimentoColumnModel> columns) async {
    // Fetch tenant to get tempoAtendimento
    final tenantDoc = await _firestore.collection('tenant').doc(tenantId).get();
    final int tempoAtendimento = tenantDoc.data()?['tempo_atendimento'] ?? 0;

    // Garante a ordenação das colunas pelo campo 'order'
    columns.sort((a, b) => a.order.compareTo(b.order));

    final now = DateTime.now();
    final cardsToArchive = <AtendimentoModel>[];
    final cardsToExpire = <AtendimentoModel>[];

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

    for (final card in cards) {
      // 1. Verifica expiração do tempo limite de atendimento baseado na última mensagem (ou data de criação)
      if (card.isAtivo && tempoAtendimento > 0) {
        final referenceDate = card.ultimaMensagemData ?? card.dataCriacao;
        final expirationDate =
            referenceDate.add(Duration(hours: tempoAtendimento));
        if (now.isAfter(expirationDate) ||
            now.isAtSameMomentAs(expirationDate)) {
          cardsToExpire.add(card);
          continue; // Pula para o próximo card, já que este vai ser inativado
        }
      }

      // 2. Verifica se deve ser arquivado da coluna finalizados
      if (finalizadosColumn != null &&
          card.colunaStatus == finalizadosColumn.id &&
          card.dataEntradaColuna != null) {
        final diff = now.difference(card.dataEntradaColuna!);
        if (diff.inHours >= 24) {
          cardsToArchive.add(card);
        }
      }
    }

    if (cardsToExpire.isNotEmpty) {
      // Encerra no Firestore (marca is_ativo = false)
      for (final card in cardsToExpire) {
        await _encerrarAtendimento(tenantId, card.id);
      }

      // Remove da lista local para atualizar a UI imediatamente
      cards = cards
          .where((c) => !cardsToExpire.any((expired) => expired.id == c.id))
          .toList();
    }

    if (cardsToArchive.isNotEmpty) {
      // Arquiva no Firestore
      for (final card in cardsToArchive) {
        await _archiveCard(tenantId, card.id);
      }

      // Remove da lista local para atualizar a UI imediatamente
      cards = cards
          .where((c) => !cardsToArchive.any((archived) => archived.id == c.id))
          .toList();
    }

    return AtendimentoBoardModel(
      cards: cards,
      columns: columns,
    );
  }

  // Método interno para encerrar atendimento expirado
  Future<void> _encerrarAtendimento(String tenantId, String cardId) async {
    await _cardsRef(tenantId).doc(cardId).update({
      'is_ativo': false,
      'data_ultima_atualizacao': FieldValue.serverTimestamp(),
    });
  }

  // Operações de Cards
  Future<List<AtendimentoModel>> getCards(String tenantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Filtra apenas os leads atribuídos ao funcionário logado
    final snapshot = await _cardsRef(tenantId)
        .where('funcionario_responsavel_id', isEqualTo: user.uid)
        .get();

    // Filtra localmente cards arquivados e inativos
    return snapshot.docs
        .map((doc) => doc.data())
        .where((card) => card.status != 'arquivado' && card.isAtivo)
        .toList();
  }

  Stream<List<AtendimentoModel>> getCardsStream(String tenantId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _cardsRef(tenantId)
        .where('funcionario_responsavel_id', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => doc.data())
            .where((card) => card.status != 'arquivado' && card.isAtivo)
            .toList());
  }

  Future<List<AtendimentoModel>> getAllCards(String tenantId) async {
    // Busca todos os cards do tenant sem filtro de usuário
    final snapshot = await _cardsRef(tenantId).get();

    // Filtra localmente cards arquivados e inativos
    return snapshot.docs
        .map((doc) => doc.data())
        .where((card) => card.status != 'arquivado' && card.isAtivo)
        .toList();
  }

  Stream<List<AtendimentoModel>> getAllCardsStream(String tenantId) {
    return _cardsRef(tenantId).snapshots().map((snapshot) => snapshot.docs
        .map((doc) => doc.data())
        .where((card) => card.status != 'arquivado' && card.isAtivo)
        .toList());
  }

  Future<List<AtendimentoModel>> getHistoryCards(String tenantId) async {
    // Busca todos os cards do tenant
    final snapshot = await _cardsRef(tenantId).get();

    // Filtra localmente os cards que foram encerrados (inativos ou arquivados)
    return snapshot.docs
        .map((doc) => doc.data())
        .where((card) => card.status == 'arquivado' || !card.isAtivo)
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

  /// Remaneja a responsabilidade de um atendimento para outro atendente (MD03 - Cockpit do Gerente)
  Future<void> reassignCard(
    String tenantId,
    String cardId,
    String? newFuncionarioId, {
    String? newFuncionarioNome,
    String? motivo,
  }) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final updateData = <String, dynamic>{
      'funcionario_responsavel_id': newFuncionarioId,
      'funcionario_responsavel_nome': newFuncionarioNome,
      'data_ultima_atualizacao': FieldValue.serverTimestamp(),
    };

    if (newFuncionarioId != null) {
      updateData['historico_atribuicoes'] = FieldValue.arrayUnion([
        {
          'para_funcionario_id': newFuncionarioId,
          'para_funcionario_nome': newFuncionarioNome,
          'por_usuario_id': currentUserId,
          'data': Timestamp.now(),
          'motivo': motivo ?? 'Remanejamento manual pelo gerente',
        }
      ]);
    }

    await _cardsRef(tenantId).doc(cardId).update(updateData);
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
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    }

    // Se não há colunas na subcoleção, busca do documento do Tenant (MD02 kanban_config.colunas)
    return await _initializeTenantColumns(tenantId);
  }

  Stream<List<AtendimentoColumnModel>> getColumnsStream(String tenantId) {
    return _columnsRef(tenantId)
        .orderBy('order', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isEmpty) {
            return await _initializeTenantColumns(tenantId);
          }
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  Future<List<AtendimentoColumnModel>> _initializeTenantColumns(String tenantId) async {
    try {
      final tenantDoc = await _firestore.collection('tenant').doc(tenantId).get();
      final data = tenantDoc.data();
      final kanbanConfig = data?['kanban_config'] as Map<String, dynamic>? ??
          data?['config']?['kanban_config'] as Map<String, dynamic>?;
      final rawColumns = kanbanConfig?['colunas'] as List<dynamic>?;

      final List<AtendimentoColumnModel> defaultColumns = [];

      if (rawColumns != null && rawColumns.isNotEmpty) {
        for (int i = 0; i < rawColumns.length; i++) {
          final colMap = rawColumns[i] as Map<String, dynamic>;
          final colId = colMap['id']?.toString() ?? 'col_${i + 1}';
          final title = colMap['titulo']?.toString() ?? 'Coluna ${i + 1}';
          final corStr = colMap['cor']?.toString();
          int colorVal = 0xFF3B82F6;
          if (corStr != null) {
            final hex = corStr.replaceAll('#', '');
            colorVal = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16) ?? 0xFF3B82F6;
          }

          defaultColumns.add(AtendimentoColumnModel(
            id: colId,
            tenantId: tenantId,
            title: title,
            colorValue: colorVal,
            order: i,
            isInitial: i == 0,
          ));
        }
      } else {
        defaultColumns.addAll([
          AtendimentoColumnModel(
            id: 'c1',
            tenantId: tenantId,
            title: 'Novos Atendimentos',
            colorValue: 0xFF3B82F6,
            order: 0,
            isInitial: true,
          ),
          AtendimentoColumnModel(
            id: 'c2',
            tenantId: tenantId,
            title: 'Em Cotação / Qualificação',
            colorValue: 0xFFF59E0B,
            order: 1,
            isInitial: false,
          ),
          AtendimentoColumnModel(
            id: 'c3',
            tenantId: tenantId,
            title: 'Aguardando Cliente',
            colorValue: 0xFF8B5CF6,
            order: 2,
            isInitial: false,
          ),
          AtendimentoColumnModel(
            id: 'c4',
            tenantId: tenantId,
            title: 'Concluído / Despachado',
            colorValue: 0xFF10B981,
            order: 3,
            isInitial: false,
          ),
        ]);
      }

      final batch = _firestore.batch();
      for (final col in defaultColumns) {
        batch.set(_columnsRef(tenantId).doc(col.id), col);
      }
      await batch.commit();

      return defaultColumns;
    } catch (e) {
      return [];
    }
  }

  Future<String> addColumn(AtendimentoColumnModel column) async {
    if (column.isInitial) {
      await _disableOtherInitialColumns(column.tenantId, null);
    }
    final docRef = await _columnsRef(column.tenantId).add(column);
    return docRef.id;
  }

  Future<void> updateColumn(AtendimentoColumnModel column) async {
    if (column.isInitial) {
      await _disableOtherInitialColumns(column.tenantId, column.id);
    }
    await _columnsRef(column.tenantId).doc(column.id).set(column);
  }

  Future<void> _disableOtherInitialColumns(
      String tenantId, String? currentColumnId) async {
    final query =
        await _columnsRef(tenantId).where('is_initial', isEqualTo: true).get();

    final batch = _firestore.batch();
    bool hasChanges = false;

    for (final doc in query.docs) {
      if (currentColumnId == null || doc.id != currentColumnId) {
        batch.update(doc.reference, {'is_initial': false});
        hasChanges = true;
      }
    }

    if (hasChanges) {
      await batch.commit();
    }
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
    // Usamos toMap(useServerTimestamp: true) diretamente para garantir o horário correto do servidor
    await _firestore
        .collection('tenant')
        .doc(mensagem.tenantId)
        .collection('interactions')
        .add(mensagem.toMap(useServerTimestamp: true));

    // Atualiza o card com a última mensagem
    await _cardsRef(mensagem.tenantId).doc(mensagem.atendimentoId).update({
      'ultima_mensagem': mensagem.texto,
      'ultima_mensagem_data': FieldValue.serverTimestamp(),
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
        messageId: '',
      );

      // Salva na coleção de interações do tenant
      await _firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('interactions')
          .add(mensagem.toMap(useServerTimestamp: true));
    } catch (e) {
      throw Exception('Erro ao enviar mensagem: $e');
    }
  }
}

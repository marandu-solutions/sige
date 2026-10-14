import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sige/src/core/core.dart';
import '../models/stock_item_model.dart';
import '../models/stock_lote_model.dart';
import '../models/stock_movimentacao_model.dart';
import '../models/epi_entrega_rastreio_model.dart';

/// Service de Estoque de Alta Performance e Conformidade NR-06.
/// Implementa IStockService do ServiceRegistry e gerencia Lotes, CAs,
/// Movimentações Atômicas e Integração com CRM de Recompra de EPIs.
class StockService implements IStockService {
  final FirebaseFirestore _firestore;

  StockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    try {
      ServiceRegistry().register<IStockService>(this);
    } catch (_) {}
  }

  // --- COLEÇÕES FIRESTORE ---

  CollectionReference<Map<String, dynamic>> _getStockCollection(String tenantId) {
    return _firestore.collection('tenant').doc(tenantId).collection('estoque');
  }

  CollectionReference<Map<String, dynamic>> _getLotesCollection(
      String tenantId, String itemId) {
    return _getStockCollection(tenantId).doc(itemId).collection('lotes');
  }

  CollectionReference<Map<String, dynamic>> _getMovimentacoesCollection(
      String tenantId) {
    return _firestore
        .collection('tenant')
        .doc(tenantId)
        .collection('estoque_movimentacoes');
  }

  CollectionReference<Map<String, dynamic>> _getEpiRastreioCollection(
      String tenantId) {
    return _firestore
        .collection('tenant')
        .doc(tenantId)
        .collection('epi_entregas_rastreio');
  }

  // --- IStockService IMPLEMENTATION (IoC & Multi-Tenant) ---

  @override
  Future<List<StockItemLookup>> searchAvailableStock(
      String tenantId, String query) async {
    final items = await loadStockItems(tenantId);
    final q = query.toLowerCase();
    return items
        .where((i) =>
            i.ativo &&
            (i.nomeProduto.toLowerCase().contains(q) ||
                i.sku.toLowerCase().contains(q) ||
                (i.caNumero != null && i.caNumero!.contains(q))))
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
    return items
        .where((i) => i.ativo)
        .map((i) => {
              'id': i.id,
              'nome': i.nomeProduto,
              'sku': i.sku,
              'qtd': i.qtdAtual,
              'preco': i.precoVenda,
              'unidade': i.unidadeMedida,
              'is_epi': i.isEpi,
              'ca_numero': i.caNumero,
            })
        .toList();
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
  Future<bool> decrementStock(
      String tenantId, String itemId, int quantity) async {
    try {
      return await _firestore.runTransaction<bool>((tx) async {
        final ref = _getStockCollection(tenantId).doc(itemId);
        final snapshot = await tx.get(ref);
        if (!snapshot.exists) return false;
        final currentQtd = (snapshot.data()!['qtd_atual'] ?? 0.0) as num;
        if (currentQtd < quantity) return false;
        tx.update(ref, {
          'qtd_atual': currentQtd - quantity,
          'atualizado_em': Timestamp.now(),
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  // --- PRODUTOS (REALTIME STREAMS & CRUD) ---

  Stream<List<StockItemModel>> watchStockItems(String tenantId) {
    return _getStockCollection(tenantId)
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StockItemModel.fromFirestore(doc)).toList());
  }

  Future<List<StockItemModel>> loadStockItems(String tenantId) async {
    try {
      final snapshot = await _getStockCollection(tenantId).get();
      return snapshot.docs
          .map((doc) => StockItemModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('StockService: Erro ao carregar itens: $e');
      return [];
    }
  }

  Future<StockItemModel> addStockItem(
      String tenantId, StockItemModel item) async {
    try {
      final docRef = await _getStockCollection(tenantId).add(item.toMap());
      return item.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erro ao adicionar item ao estoque: $e');
    }
  }

  Future<void> updateStockItem(String tenantId, StockItemModel item) async {
    try {
      await _getStockCollection(tenantId).doc(item.id).update(item.toMap());
    } catch (e) {
      throw Exception('Erro ao atualizar item do estoque: $e');
    }
  }

  Future<void> deleteStockItem(String tenantId, String itemId) async {
    try {
      // Soft-delete para preservar auditoria e histórico de CAs
      await _getStockCollection(tenantId).doc(itemId).update({
        'ativo': false,
        'atualizado_em': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erro ao remover item do estoque: $e');
    }
  }

  // --- GESTÃO DE LOTES (REALTIME STREAMS & CRUD) ---

  Stream<List<StockLoteModel>> watchItemLotes(
      String tenantId, String itemId) {
    return _getLotesCollection(tenantId, itemId)
        .orderBy('criado_em', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => StockLoteModel.fromFirestore(doc)).toList());
  }

  Future<List<StockLoteModel>> loadItemLotes(
      String tenantId, String itemId) async {
    try {
      final snapshot = await _getLotesCollection(tenantId, itemId).get();
      return snapshot.docs
          .map((doc) => StockLoteModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('StockService: Erro ao carregar lotes do item: $e');
      return [];
    }
  }

  Future<StockLoteModel> addLote(
      String tenantId, String itemId, StockLoteModel lote) async {
    try {
      final docRef = await _getLotesCollection(tenantId, itemId).add(lote.toMap());
      return lote.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erro ao adicionar lote: $e');
    }
  }

  // --- TRANSAÇÕES ATÔMICAS DE MOVIMENTAÇÃO (AUDITORIA E LOTE) ---

  Future<bool> registrarMovimentacao({
    required String tenantId,
    required String itemId,
    required String tipo, // ENTRADA, SAIDA_VENDA, SAIDA_EPI, AJUSTE_POSITIVO, AJUSTE_NEGATIVO, PERDA, DEVOLUCAO
    required double quantidade,
    required String motivo,
    String? loteCodigo,
    String? usuarioUid,
    String? usuarioNome,
    // Dados opcionais para registro de entrega de EPI e CRM
    String? clienteId,
    String? clienteNome,
    String? clienteTelefone,
    int? diasVidaUtil,
  }) async {
    try {
      return await _firestore.runTransaction<bool>((tx) async {
        final itemRef = _getStockCollection(tenantId).doc(itemId);
        final itemSnap = await tx.get(itemRef);
        if (!itemSnap.exists) return false;

        final itemData = itemSnap.data()!;
        final saldoAnterior = (itemData['qtd_atual'] ?? 0.0) as num;
        final nomeProduto = itemData['nome_produto'] as String? ?? '';
        final sku = itemData['sku'] as String? ?? '';
        final isEpi = itemData['is_epi'] as bool? ?? false;
        final caNumero = itemData['ca_numero'] as String?;
        final nivelAlerta = (itemData['nivel_alerta'] ?? 0.0) as num;

        final isIncremento = tipo == 'ENTRADA' ||
            tipo == 'AJUSTE_POSITIVO' ||
            tipo == 'DEVOLUCAO';

        if (!isIncremento && saldoAnterior < quantidade) {
          throw Exception('Saldo insuficiente para esta saída ($saldoAnterior disponível).');
        }

        final saldoPosterior = isIncremento
            ? saldoAnterior + quantidade
            : saldoAnterior - quantidade;

        // 1. Atualiza o saldo geral do item
        tx.update(itemRef, {
          'qtd_atual': saldoPosterior,
          'atualizado_em': Timestamp.now(),
        });

        // 2. Se houver lote especificado, ajusta a quantidade do lote
        if (loteCodigo != null && loteCodigo.isNotEmpty) {
          final lotesQuery = await _getLotesCollection(tenantId, itemId)
              .where('lote_codigo', isEqualTo: loteCodigo)
              .limit(1)
              .get();

          if (lotesQuery.docs.isNotEmpty) {
            final loteRef = lotesQuery.docs.first.reference;
            final loteSnap = await tx.get(loteRef);
            if (loteSnap.exists) {
              final loteQtdAtual = (loteSnap.data()!['qtd_atual'] ?? 0.0) as num;
              final novaLoteQtd = isIncremento
                  ? loteQtdAtual + quantidade
                  : (loteQtdAtual - quantidade).clamp(0.0, double.infinity);
              tx.update(loteRef, {
                'qtd_atual': novaLoteQtd,
                'status': novaLoteQtd == 0 ? 'ESGOTADO' : 'ATIVO',
              });
            }
          }
        }

        // 3. Grava registro auditável de movimentação
        final movRef = _getMovimentacoesCollection(tenantId).doc();
        tx.set(movRef, {
          'id': movRef.id,
          'tenant_id': tenantId,
          'item_id': itemId,
          'nome_produto': nomeProduto,
          'sku': sku,
          'tipo': tipo,
          'quantidade': quantidade,
          'saldo_anterior': saldoAnterior,
          'saldo_posterior': saldoPosterior,
          'lote_codigo': loteCodigo,
          'motivo': motivo,
          'usuario_uid': usuarioUid,
          'usuario_nome': usuarioNome,
          'timestamp': Timestamp.now(),
        });

        // 4. Se for saída de EPI para cliente com dados de contato, cria rastreio para o CRM Omnichannel
        if (isEpi &&
            clienteTelefone != null &&
            clienteTelefone.isNotEmpty &&
            clienteNome != null &&
            clienteNome.isNotEmpty) {
          final vidaUtil = diasVidaUtil ??
              (itemData['dias_vida_util_uso'] as int?) ??
              60;
          final rastreioRef = _getEpiRastreioCollection(tenantId).doc();
          final dataEntrega = DateTime.now();
          final dataVencimentoUso = dataEntrega.add(Duration(days: vidaUtil));

          tx.set(rastreioRef, {
            'id': rastreioRef.id,
            'tenant_id': tenantId,
            'item_id': itemId,
            'nome_produto': nomeProduto,
            'lote_codigo': loteCodigo ?? 'LOT-GERAL',
            'ca_numero': caNumero,
            'cliente_id': clienteId,
            'cliente_nome': clienteNome,
            'cliente_telefone': clienteTelefone,
            'quantidade_entregue': quantidade,
            'data_entrega': Timestamp.fromDate(dataEntrega),
            'data_vencimento_uso': Timestamp.fromDate(dataVencimentoUso),
            'dias_vida_util': vidaUtil,
            'd30_disparado': false,
            'd15_disparado': false,
            'd0_disparado': false,
            'status_recompra': 'PENDENTE',
            'observacao': motivo,
          });

          // Dispara evento no EventBus
          EventBus().publish(EpiDeliveredEvent(
            tenantId: tenantId,
            itemId: itemId,
            nomeProduto: nomeProduto,
            loteCodigo: loteCodigo ?? 'LOT-GERAL',
            clienteNome: clienteNome,
            clienteTelefone: clienteTelefone,
            quantidade: quantidade,
            diasVidaUtil: vidaUtil,
          ));
        }

        // 5. Se o estoque ficou abaixo do nível de alerta, publica evento
        if (saldoPosterior <= nivelAlerta) {
          EventBus().publish(StockBelowThresholdEvent(
            tenantId: tenantId,
            itemId: itemId,
            nomeProduto: nomeProduto,
            qtdAtual: saldoPosterior.toDouble(),
            nivelAlerta: nivelAlerta.toDouble(),
          ));
        }

        return true;
      });
    } catch (e) {
      debugPrint('StockService: Erro na transação de movimentação: $e');
      rethrow;
    }
  }

  // --- HISTÓRICO DE MOVIMENTAÇÕES ---

  Stream<List<StockMovimentacaoModel>> watchMovimentacoes(String tenantId,
      {String? itemId, int limit = 50}) {
    Query<Map<String, dynamic>> query = _getMovimentacoesCollection(tenantId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (itemId != null && itemId.isNotEmpty) {
      query = query.where('item_id', isEqualTo: itemId);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => StockMovimentacaoModel.fromFirestore(doc))
        .toList());
  }

  // --- RASTREIO DE EPIs & RÉGUA OMNICHANNEL ---

  Stream<List<EpiEntregaRastreioModel>> watchEpiEntregas(String tenantId) {
    return _getEpiRastreioCollection(tenantId)
        .orderBy('data_vencimento_uso', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EpiEntregaRastreioModel.fromFirestore(doc))
            .toList());
  }

  /// Simula ou executa o disparo da régua preventiva de reposição (D-30, D-15 ou D-0)
  /// e gera card automático no funil de Atendimento
  Future<bool> dispararReguaPreventiva({
    required String tenantId,
    required EpiEntregaRastreioModel entrega,
    required String gatilho, // 'D-30', 'D-15' ou 'D-0'
  }) async {
    try {
      final docRef = _getEpiRastreioCollection(tenantId).doc(entrega.id);

      Map<String, dynamic> updateData = {
        'status_recompra': 'CONTATADO',
      };

      if (gatilho == 'D-30') updateData['d30_disparado'] = true;
      if (gatilho == 'D-15') updateData['d15_disparado'] = true;
      if (gatilho == 'D-0') updateData['d0_disparado'] = true;

      await docRef.update(updateData);

      // Publica evento no EventBus para que o atendimento/n8n reaja
      EventBus().publish(EpiExpiringEvent(
        tenantId: tenantId,
        rastreioId: entrega.id,
        clienteNome: entrega.clienteNome,
        clienteTelefone: entrega.clienteTelefone,
        nomeProduto: entrega.nomeProduto,
        caNumero: entrega.caNumero,
        diasRestantes: entrega.diasRestantes,
      ));

      return true;
    } catch (e) {
      debugPrint('StockService: Erro ao disparar régua preventiva: $e');
      return false;
    }
  }

  /// Gera dados de demonstração com conformidade NR-06, lotes e rastreio CRM
  Future<void> seedDemoData(String tenantId) async {
    final now = DateTime.now();

    final demoItems = [
      StockItemModel(
        id: '',
        tenantId: tenantId,
        nomeProduto: 'Protetor Auditivo de Inserção Silicone 16dB',
        sku: 'EPI-PROT-15618',
        qtdAtual: 140.0,
        unidadeMedida: 'PAR',
        precoVenda: 12.50,
        precoCusto: 4.20,
        nivelAlerta: 30.0,
        estoqueMinimo: 30.0,
        categoria: 'Proteção Auditiva',
        codigoBarrasEan: '7891234560012',
        isEpi: true,
        caNumero: '15618',
        caValidade: now.add(const Duration(days: 480)),
        caSituacao: 'VALIDO',
        normasAtendidas: ['NR-06', 'ANSI S12.6'],
        diasVidaUtilUso: 90,
        fabricante: '3M do Brasil',
        tipoProtecao: 'Auditiva',
        criadoEm: now,
        atualizadoEm: now,
      ),
      StockItemModel(
        id: '',
        tenantId: tenantId,
        nomeProduto: 'Respirador Semifacial Dobrável PFF2 (N95) c/ Válvula',
        sku: 'EPI-RESP-38512',
        qtdAtual: 8.0, // Alerta de Ruptura!
        unidadeMedida: 'UN',
        precoVenda: 9.80,
        precoCusto: 3.50,
        nivelAlerta: 25.0,
        estoqueMinimo: 25.0,
        categoria: 'Proteção Respiratória',
        codigoBarrasEan: '7891234560029',
        isEpi: true,
        caNumero: '38512',
        caValidade: now.add(const Duration(days: 340)),
        caSituacao: 'VALIDO',
        normasAtendidas: ['NR-06', 'ABNT NBR 13698'],
        diasVidaUtilUso: 30,
        fabricante: 'Delta Plus',
        tipoProtecao: 'Respiratória',
        criadoEm: now,
        atualizadoEm: now,
      ),
      StockItemModel(
        id: '',
        tenantId: tenantId,
        nomeProduto: 'Luva Nitrílica Resistência Química Verde Solvex',
        sku: 'EPI-LUV-42100',
        qtdAtual: 85.0,
        unidadeMedida: 'PAR',
        precoVenda: 28.90,
        precoCusto: 14.20,
        nivelAlerta: 20.0,
        estoqueMinimo: 20.0,
        categoria: 'Mãos e Braços (Luvas)',
        codigoBarrasEan: '7891234560036',
        isEpi: true,
        caNumero: '42100',
        caValidade: now.add(const Duration(days: 22)), // Perto de vencer CA!
        caSituacao: 'VALIDO',
        normasAtendidas: ['NR-06', 'EN 374', 'EN 388'],
        diasVidaUtilUso: 60,
        fabricante: 'Ansell',
        tipoProtecao: 'Mãos e Braços (Luvas)',
        criadoEm: now,
        atualizadoEm: now,
      ),
      StockItemModel(
        id: '',
        tenantId: tenantId,
        nomeProduto: 'Botina de Segurança Microfibra c/ Bico Composite',
        sku: 'EPI-CALC-34211',
        qtdAtual: 34.0,
        unidadeMedida: 'PAR',
        precoVenda: 168.00,
        precoCusto: 95.00,
        nivelAlerta: 15.0,
        estoqueMinimo: 15.0,
        categoria: 'Pés e Pernas (Calçados)',
        codigoBarrasEan: '7891234560043',
        isEpi: true,
        caNumero: '34211',
        caValidade: now.add(const Duration(days: 620)),
        caSituacao: 'VALIDO',
        normasAtendidas: ['NR-06', 'ABNT NBR ISO 20345'],
        diasVidaUtilUso: 180,
        fabricante: 'Marluvas',
        tipoProtecao: 'Pés e Pernas (Calçados)',
        criadoEm: now,
        atualizadoEm: now,
      ),
      StockItemModel(
        id: '',
        tenantId: tenantId,
        nomeProduto: 'Óculos de Segurança Antirrisco e Antiembaçante Danny',
        sku: 'EPI-OCUL-27532',
        qtdAtual: 62.0,
        unidadeMedida: 'UN',
        precoVenda: 18.50,
        precoCusto: 7.80,
        nivelAlerta: 15.0,
        estoqueMinimo: 15.0,
        categoria: 'Visual e Facial',
        codigoBarrasEan: '7891234560050',
        isEpi: true,
        caNumero: '27532',
        caValidade: now.add(const Duration(days: 410)),
        caSituacao: 'VALIDO',
        normasAtendidas: ['NR-06', 'ANSI/ISEA Z87.1'],
        diasVidaUtilUso: 120,
        fabricante: 'Danny EPI',
        tipoProtecao: 'Visual e Facial',
        criadoEm: now,
        atualizadoEm: now,
      ),
    ];

    for (final item in demoItems) {
      final docRef = await _getStockCollection(tenantId).add(item.toMap());
      final itemId = docRef.id;

      // Adiciona Lote inicial
      await addLote(
        tenantId,
        itemId,
        StockLoteModel(
          id: '',
          tenantId: tenantId,
          itemId: itemId,
          loteCodigo: 'LOT-${now.year}-${item.sku.split('-').last}',
          dataFabricacao: now.subtract(const Duration(days: 30)),
          dataValidade: now.add(const Duration(days: 365)),
          qtdInicial: item.qtdAtual,
          qtdAtual: item.qtdAtual,
          precoAquisicao: item.precoCusto,
          fornecedor: item.fabricante ?? 'Distribuidor Autorizado',
        ),
      );

      // Se for o protetor auditivo, simula uma entrega com validade de uso nos próximos 12 dias para ativar CRM
      if (item.sku == 'EPI-PROT-15618') {
        await _getEpiRastreioCollection(tenantId).add({
          'tenant_id': tenantId,
          'item_id': itemId,
          'nome_produto': item.nomeProduto,
          'ca_numero': item.caNumero,
          'cliente_nome': 'Construtora Forte Engenharia',
          'cliente_telefone': '5511988887766',
          'data_entrega': now.subtract(const Duration(days: 78)),
          'dias_vida_util': 90,
          'data_vencimento_uso': now.add(const Duration(days: 12)),
          'quantidade_entregue': 20.0,
          'd30_disparado': true,
          'd15_disparado': false,
          'd0_disparado': false,
          'status_recompra': 'PENDENTE',
        });
      }
    }
  }
}


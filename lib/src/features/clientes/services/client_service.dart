import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sige/src/core/core.dart';
import '../models/client_model.dart';
import '../models/client_address_model.dart';

/// Serviço Central de Clientes, Contas B2B e Pessoas Físicas do SIGE (MD05)
/// Implementa ILeadLookupProvider no ServiceRegistry para integração sem atrito com o Atendimento.
class ClientService implements ILeadLookupProvider {
  final FirebaseFirestore _firestore;

  ClientService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance {
    try {
      ServiceRegistry().register<ILeadLookupProvider>(this);
    } catch (_) {}
  }

  // --- COLEÇÃO FIRESTORE MULTI-TENANT ---

  CollectionReference<Map<String, dynamic>> _getClientsCollection(String tenantId) {
    return _firestore.collection('tenant').doc(tenantId).collection('clientes');
  }

  CollectionReference<Map<String, dynamic>> _getLegacyLeadsCollection(String tenantId) {
    return _firestore.collection('tenant').doc(tenantId).collection('leads');
  }

  // --- ILeadLookupProvider IMPLEMENTATION (Atendimento Integration) ---

  @override
  Future<List<LeadLookupItem>> searchLeads(String tenantId, String query) async {
    final clients = await loadClients(tenantId);
    final q = query.toLowerCase().replaceAll(RegExp(r'\D'), '');
    final qText = query.toLowerCase();

    return clients.where((c) {
      final matchNome = c.nome.toLowerCase().contains(qText);
      final matchRazao = c.razaoSocial != null && c.razaoSocial!.toLowerCase().contains(qText);
      final matchEmpresa = c.empresaNome != null && c.empresaNome!.toLowerCase().contains(qText);
      final matchTel = q.isNotEmpty && c.telefones.any((t) => t.replaceAll(RegExp(r'\D'), '').contains(q));
      final matchDoc = q.isNotEmpty && c.documento != null && c.documento!.contains(q);

      return matchNome || matchRazao || matchEmpresa || matchTel || matchDoc;
    }).map((c) => LeadLookupItem(
          id: c.id,
          nome: c.nomeExibicao,
          telefone: c.telefonePrincipal,
          email: c.emails.isNotEmpty ? c.emails.first : null,
          fotoUrl: c.fotoUrl,
        )).toList();
  }

  @override
  Future<LeadLookupItem?> getLeadById(String tenantId, String leadId) async {
    try {
      final doc = await _getClientsCollection(tenantId).doc(leadId).get();
      if (doc.exists && doc.data() != null) {
        final client = ClientModel.fromFirestore(doc);
        return LeadLookupItem(
          id: client.id,
          nome: client.nomeExibicao,
          telefone: client.telefonePrincipal,
          email: client.emails.isNotEmpty ? client.emails.first : null,
          fotoUrl: client.fotoUrl,
        );
      }

      // Fallback para coleção legada de leads se ainda não migrado
      final legacyDoc = await _getLegacyLeadsCollection(tenantId).doc(leadId).get();
      if (legacyDoc.exists && legacyDoc.data() != null) {
        final client = ClientModel.fromMap(legacyDoc.data()!, legacyDoc.id);
        return LeadLookupItem(
          id: client.id,
          nome: client.nome,
          telefone: client.telefonePrincipal,
          email: client.emails.isNotEmpty ? client.emails.first : null,
          fotoUrl: client.fotoUrl,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- CRUD REATIVO EM TEMPO REAL ---

  Stream<List<ClientModel>> watchClients(String tenantId) {
    return _getClientsCollection(tenantId)
        .orderBy('atualizado_em', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Fallback: se clientes estiver vazio, tenta ler leads legados
        final legacySnapshot = await _getLegacyLeadsCollection(tenantId)
            .orderBy('data_criacao', descending: true)
            .get();
        if (legacySnapshot.docs.isNotEmpty) {
          return legacySnapshot.docs
              .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
              .toList();
        }
      }
      return snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
    });
  }

  Future<List<ClientModel>> loadClients(String tenantId) async {
    final snapshot = await _getClientsCollection(tenantId)
        .orderBy('atualizado_em', descending: true)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.map((doc) => ClientModel.fromFirestore(doc)).toList();
    }

    // Fallback legado
    final legacySnapshot = await _getLegacyLeadsCollection(tenantId)
        .orderBy('data_criacao', descending: true)
        .get();
    return legacySnapshot.docs
        .map((doc) => ClientModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<String> addClient(String tenantId, ClientModel client) async {
    final data = client.toMap();
    data['criado_em'] = FieldValue.serverTimestamp();
    data['atualizado_em'] = FieldValue.serverTimestamp();

    final docRef = await _getClientsCollection(tenantId).add(data);
    final newId = docRef.id;

    // Se for CONTATO_PJ e tiver empresaId associada, atualiza a lista de contatos da PJ
    if (client.isContatoPj && client.empresaId != null && client.empresaId!.isNotEmpty) {
      await _getClientsCollection(tenantId).doc(client.empresaId).update({
        'contatos_vinculados_ids': FieldValue.arrayUnion([newId]),
        'atualizado_em': FieldValue.serverTimestamp(),
      });
    }

    return newId;
  }

  Future<void> updateClient(String tenantId, ClientModel client) async {
    final data = client.toMap();
    data['atualizado_em'] = FieldValue.serverTimestamp();
    await _getClientsCollection(tenantId).doc(client.id).set(data, SetOptions(merge: true));

    // Se tiver empresa vinculada, garante sincronização
    if (client.isContatoPj && client.empresaId != null && client.empresaId!.isNotEmpty) {
      await _getClientsCollection(tenantId).doc(client.empresaId).update({
        'contatos_vinculados_ids': FieldValue.arrayUnion([client.id]),
        'atualizado_em': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteClient(String tenantId, String clientId) async {
    await _getClientsCollection(tenantId).doc(clientId).delete();
  }

  // --- MÉTODOS DE VÍNCULO & FUSÃO B2B (MD05) ---

  /// Vincula um contato existente (ou recém-criado) a uma Empresa Mãe PJ
  Future<void> vincularContatoAEmpresa({
    required String tenantId,
    required String contatoId,
    required String empresaId,
    required String empresaNome,
    required String cargo,
  }) async {
    final batch = _firestore.batch();

    // 1. Atualiza o contato com os dados da empresa
    final contatoRef = _getClientsCollection(tenantId).doc(contatoId);
    batch.update(contatoRef, {
      'tipo': 'CONTATO_PJ',
      'empresa_id': empresaId,
      'empresa_nome': empresaNome,
      'cargo': cargo,
      'atualizado_em': FieldValue.serverTimestamp(),
    });

    // 2. Registra o contato na lista de contatos vinculados da empresa PJ
    final empresaRef = _getClientsCollection(tenantId).doc(empresaId);
    batch.update(empresaRef, {
      'contatos_vinculados_ids': FieldValue.arrayUnion([contatoId]),
      'atualizado_em': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Adiciona um novo número de telefone a um cliente existente (fusão de números)
  Future<void> adicionarTelefoneACliente({
    required String tenantId,
    required String clienteId,
    required String novoTelefone,
  }) async {
    final clean = novoTelefone.trim();
    if (clean.isEmpty) return;

    await _getClientsCollection(tenantId).doc(clienteId).update({
      'telefones': FieldValue.arrayUnion([clean]),
      'atualizado_em': FieldValue.serverTimestamp(),
    });
  }

  /// Busca cliente por telefone (compara dígitos limpos)
  Future<ClientModel?> buscarClientePorTelefone(String tenantId, String telefone) async {
    final cleanTarget = telefone.replaceAll(RegExp(r'\D'), '');
    if (cleanTarget.isEmpty) return null;

    final clients = await loadClients(tenantId);
    for (final c in clients) {
      for (final t in c.telefones) {
        final cleanT = t.replaceAll(RegExp(r'\D'), '');
        if (cleanT == cleanTarget ||
            (cleanTarget.length >= 8 && cleanT.endsWith(cleanTarget.substring(cleanTarget.length - 8)))) {
          return c;
        }
      }
    }
    return null;
  }

  // --- INTEGRAÇÃO COM BRASILAPI (ENRIQUECIMENTO AUTOMÁTICO DE CNPJ / CEP) ---

  /// Consulta dados cadastrais completos da empresa na Receita Federal via BrasilAPI
  Future<Map<String, dynamic>?> consultarCnpjBrasilApi(String cnpj) async {
    try {
      final clean = cnpj.replaceAll(RegExp(r'\D'), '');
      if (clean.length != 14) return null;

      final url = Uri.parse('https://brasilapi.com.br/api/cnpj/v1/$clean');
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        final razaoSocial = data['razao_social']?.toString() ?? '';
        final fantasiaRaw = data['nome_fantasia']?.toString().trim();
        final nomeFantasia = (fantasiaRaw != null && fantasiaRaw.isNotEmpty)
            ? fantasiaRaw
            : razaoSocial;
        final cnaeDesc = data['cnae_fiscal_descricao']?.toString() ?? '';
        final cep = data['cep']?.toString() ?? '';
        final logradouro = data['logradouro']?.toString() ?? '';
        final numero = data['numero']?.toString() ?? '';
        final complemento = data['complemento']?.toString() ?? '';
        final bairro = data['bairro']?.toString() ?? '';
        final municipio = data['municipio']?.toString() ?? '';
        final uf = data['uf']?.toString() ?? '';
        final tel1 = data['ddd_telefone_1']?.toString() ?? '';
        final email = data['email']?.toString() ?? '';

        return {
          'razao_social': razaoSocial,
          'nome_fantasia': nomeFantasia,
          'cnae_descricao': cnaeDesc,
          'telefone': tel1,
          'email': email,
          'endereco': ClientAddressModel(
            cep: cep,
            logradouro: logradouro,
            numero: numero,
            complemento: complemento,
            bairro: bairro,
            cidade: municipio,
            uf: uf,
          ),
        };
      }
      return null;
    } catch (e) {
      debugPrint('ClientService: Erro ao consultar BrasilAPI CNPJ: $e');
      return null;
    }
  }

  /// Consulta dados de logradouro a partir do CEP via BrasilAPI
  Future<ClientAddressModel?> consultarCepBrasilApi(String cep) async {
    try {
      final clean = cep.replaceAll(RegExp(r'\D'), '');
      if (clean.length != 8) return null;

      final url = Uri.parse('https://brasilapi.com.br/api/cep/v1/$clean');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return ClientAddressModel(
          cep: clean,
          logradouro: data['street']?.toString() ?? '',
          numero: '',
          complemento: '',
          bairro: data['neighborhood']?.toString() ?? '',
          cidade: data['city']?.toString() ?? '',
          uf: data['state']?.toString() ?? '',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // --- SEED DE DEMONSTRAÇÃO (MD05) ---

  Future<void> seedDemoClients(String tenantId) async {
    final now = DateTime.now();

    // 1. Empresa Matriz B2B 1
    final metropoleRef = await _getClientsCollection(tenantId).add({
      'tenant_id': tenantId,
      'tipo': 'PJ',
      'nome': 'Construtora Metrópole Ltda',
      'razao_social': 'Construtora Metrópole Engenharia e Obras Ltda',
      'documento': '12345678000190',
      'inscricao_estadual': '109.876.543.210',
      'telefones': ['1133221100', '11988881122'],
      'telefone_principal': '1133221100',
      'emails': ['compras@metropole.com.br', 'suprimentos@metropole.com.br'],
      'empresa_id': null,
      'empresa_nome': null,
      'cargo': null,
      'contatos_vinculados_ids': [],
      'status_ciclo': 'ATIVO',
      'tags': ['VIP', 'CONSTRUTORA', 'RECORRENTE', 'TABELA_A'],
      'origem': 'INDICACAO',
      'limite_credito': 80000.0,
      'tabela_preco': 'TABELA_A',
      'ltv_total': 48900.0,
      'total_atendimentos': 18,
      'ultima_compra_data': Timestamp.fromDate(now.subtract(const Duration(days: 6))),
      'endereco': const ClientAddressModel(
        cep: '01310100',
        logradouro: 'Avenida Paulista',
        numero: '1200',
        complemento: '14º Andar - Sala 142',
        bairro: 'Bela Vista',
        cidade: 'São Paulo',
        uf: 'SP',
      ).toMap(),
      'criado_em': Timestamp.fromDate(now.subtract(const Duration(days: 120))),
      'atualizado_em': Timestamp.fromDate(now),
      'observacoes_internas': 'Entregas de EPIs devem ter agendamento prévio com o almoxarifado de cada canteiro de obras.',
    });

    final metropoleId = metropoleRef.id;

    // 2. Contato B2B Vinculado à Metrópole (Comprador)
    final marcosRef = await _getClientsCollection(tenantId).add({
      'tenant_id': tenantId,
      'tipo': 'CONTATO_PJ',
      'nome': 'Eng. Marcos Vinícius',
      'razao_social': null,
      'documento': '22233344455',
      'inscricao_estadual': null,
      'telefones': ['11988881122', '11987776655'],
      'telefone_principal': '11988881122',
      'emails': ['marcos.compras@metropole.com.br'],
      'empresa_id': metropoleId,
      'empresa_nome': 'Construtora Metrópole Ltda',
      'cargo': 'Comprador Central de Obras',
      'contatos_vinculados_ids': [],
      'status_ciclo': 'ATIVO',
      'tags': ['COMPRADOR', 'AUTORIZADO'],
      'origem': 'WHATSAPP',
      'ltv_total': 34200.0,
      'total_atendimentos': 12,
      'criado_em': Timestamp.fromDate(now.subtract(const Duration(days: 90))),
      'atualizado_em': Timestamp.fromDate(now),
    });

    // 3. Contato B2B Vinculado à Metrópole (Almoxarife)
    final zeRef = await _getClientsCollection(tenantId).add({
      'tenant_id': tenantId,
      'tipo': 'CONTATO_PJ',
      'nome': 'Seu Zé (Almoxarifado Obra Alphaville)',
      'razao_social': null,
      'documento': null,
      'inscricao_estadual': null,
      'telefones': ['11977774433'],
      'telefone_principal': '11977774433',
      'emails': ['obra.alphaville@metropole.com.br'],
      'empresa_id': metropoleId,
      'empresa_nome': 'Construtora Metrópole Ltda',
      'cargo': 'Mestre / Encarregado de Obra',
      'contatos_vinculados_ids': [],
      'status_ciclo': 'ATIVO',
      'tags': ['OBRA', 'RECEBIMENTO_EPI'],
      'origem': 'WHATSAPP',
      'ltv_total': 14700.0,
      'total_atendimentos': 6,
      'criado_em': Timestamp.fromDate(now.subtract(const Duration(days: 45))),
      'atualizado_em': Timestamp.fromDate(now),
    });

    // Atualiza a PJ com os contatos vinculados
    await metropoleRef.update({
      'contatos_vinculados_ids': [marcosRef.id, zeRef.id],
    });

    // 4. Empresa B2B 2 (Indústria Delta)
    await _getClientsCollection(tenantId).add({
      'tenant_id': tenantId,
      'tipo': 'PJ',
      'nome': 'Indústria Metalúrgica Delta S/A',
      'razao_social': 'Delta Metalurgia e Laminações Industriais S/A',
      'documento': '98765432000110',
      'inscricao_estadual': '333.444.555.666',
      'telefones': ['1133445500', '11999990011'],
      'telefone_principal': '1133445500',
      'emails': ['suprimentos@deltametal.com.br'],
      'status_ciclo': 'ATIVO',
      'tags': ['INDUSTRIA', 'GRANDES_VOLUMES', 'ATACADO'],
      'origem': 'SITE',
      'limite_credito': 150000.0,
      'tabela_preco': 'ATACADO',
      'ltv_total': 124500.0,
      'total_atendimentos': 26,
      'ultima_compra_data': Timestamp.fromDate(now.subtract(const Duration(days: 14))),
      'endereco': const ClientAddressModel(
        cep: '09750000',
        logradouro: 'Avenida das Indústrias',
        numero: '3500',
        complemento: 'Galpão 3',
        bairro: 'Distrito Industrial',
        cidade: 'São Bernardo do Campo',
        uf: 'SP',
      ).toMap(),
      'criado_em': Timestamp.fromDate(now.subtract(const Duration(days: 200))),
      'atualizado_em': Timestamp.fromDate(now),
    });

    // 5. Cliente Pessoa Física B2C (Dr. Roberto Albuquerque)
    await _getClientsCollection(tenantId).add({
      'tenant_id': tenantId,
      'tipo': 'PF',
      'nome': 'Dr. Roberto Albuquerque',
      'documento': '33344455566',
      'telefones': ['11977773344', '11966662211'], // 2 números vinculados ao mesmo cliente!
      'telefone_principal': '11977773344',
      'emails': ['roberto.albuquerque@clinica.com.br'],
      'status_ciclo': 'ATIVO',
      'tags': ['PROFISSIONAL_LIBERAL', 'RECORRENTE'],
      'origem': 'WHATSAPP',
      'ltv_total': 4850.0,
      'total_atendimentos': 5,
      'ultima_compra_data': Timestamp.fromDate(now.subtract(const Duration(days: 21))),
      'criado_em': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
      'atualizado_em': Timestamp.fromDate(now),
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/client_model.dart';
import '../services/client_service.dart';

/// Provider do serviço de clientes
final clientServiceProvider = Provider<ClientService>((ref) {
  return ClientService();
});

/// Stream em tempo real da lista de clientes do tenant
final clientsStreamProvider =
    StreamProvider.family<List<ClientModel>, String>((ref, tenantId) {
  final service = ref.watch(clientServiceProvider);
  return service.watchClients(tenantId);
});

// --- ESTADOS DE CONTROLE DE FILTROS & UI ---

final clientSearchQueryProvider = StateProvider<String>((ref) => '');
final clientFilterSegmentProvider = StateProvider<String>((ref) => 'TODOS'); // 'TODOS', 'PJ', 'CONTATO_PJ', 'PF', 'ATIVOS', 'LEADS'
final clientFilterTagProvider = StateProvider<String>((ref) => 'TODAS');
final clientViewModeProvider = StateProvider<String>((ref) => 'grid'); // 'grid' | 'table'

// --- KPIS DE CARTEIRA DE CLIENTES (COMPUTED PROVIDER) ---

class ClientKpiData {
  final int totalContas;
  final int totalEmpresasPj;
  final int totalContatosB2b;
  final int totalPessoasFisicas;
  final int clientesAtivos;
  final double ltvTotal;
  final double ticketMedio;
  final int novosMes;

  const ClientKpiData({
    required this.totalContas,
    required this.totalEmpresasPj,
    required this.totalContatosB2b,
    required this.totalPessoasFisicas,
    required this.clientesAtivos,
    required this.ltvTotal,
    required this.ticketMedio,
    required this.novosMes,
  });
}

final clientKpisProvider =
    Provider.family<ClientKpiData, String>((ref, tenantId) {
  final clientsAsync = ref.watch(clientsStreamProvider(tenantId));
  final clients = clientsAsync.valueOrNull ?? [];

  int pj = 0;
  int contatoB2b = 0;
  int pf = 0;
  int ativos = 0;
  double ltv = 0.0;
  int novosMes = 0;
  final now = DateTime.now();

  for (final c in clients) {
    if (c.isPj) pj++;
    if (c.isContatoPj) contatoB2b++;
    if (c.isPf) pf++;
    if (c.statusCiclo == 'ATIVO') ativos++;
    ltv += c.ltvTotal;

    // Novos no mês corrente
    if (c.criadoEm.year == now.year && c.criadoEm.month == now.month) {
      novosMes++;
    }
  }

  final contasCompradoras = pj + pf;
  final ticketMedio = contasCompradoras > 0 ? (ltv / contasCompradoras) : 0.0;

  return ClientKpiData(
    totalContas: clients.length,
    totalEmpresasPj: pj,
    totalContatosB2b: contatoB2b,
    totalPessoasFisicas: pf,
    clientesAtivos: ativos,
    ltvTotal: ltv,
    ticketMedio: ticketMedio,
    novosMes: novosMes,
  );
});

// --- LISTA FILTRADA REATIVA ---

final filteredClientsProvider =
    Provider.family<List<ClientModel>, String>((ref, tenantId) {
  final clientsAsync = ref.watch(clientsStreamProvider(tenantId));
  final clients = clientsAsync.valueOrNull ?? [];

  final query = ref.watch(clientSearchQueryProvider).trim().toLowerCase();
  final segment = ref.watch(clientFilterSegmentProvider);
  final tag = ref.watch(clientFilterTagProvider);
  final queryDigits = query.replaceAll(RegExp(r'\D'), '');

  return clients.where((c) {
    // 1. Filtro textual
    if (query.isNotEmpty) {
      final matchNome = c.nome.toLowerCase().contains(query);
      final matchRazao = c.razaoSocial != null && c.razaoSocial!.toLowerCase().contains(query);
      final matchEmpresa = c.empresaNome != null && c.empresaNome!.toLowerCase().contains(query);
      final matchCargo = c.cargo != null && c.cargo!.toLowerCase().contains(query);
      final matchTel = queryDigits.isNotEmpty && c.telefones.any((t) => t.replaceAll(RegExp(r'\D'), '').contains(queryDigits));
      final matchDoc = queryDigits.isNotEmpty && c.documento != null && c.documento!.contains(queryDigits);
      final matchEmail = c.emails.any((e) => e.toLowerCase().contains(query));

      if (!matchNome && !matchRazao && !matchEmpresa && !matchCargo && !matchTel && !matchDoc && !matchEmail) {
        return false;
      }
    }

    // 2. Filtro de Segmento
    if (segment == 'PJ' && !c.isPj) return false;
    if (segment == 'CONTATO_PJ' && !c.isContatoPj) return false;
    if (segment == 'PF' && !c.isPf) return false;
    if (segment == 'ATIVOS' && c.statusCiclo != 'ATIVO') return false;
    if (segment == 'LEADS' && c.statusCiclo != 'LEAD') return false;

    // 3. Filtro de Tag
    if (tag != 'TODAS' && !c.tags.contains(tag)) {
      return false;
    }

    return true;
  }).toList();
});

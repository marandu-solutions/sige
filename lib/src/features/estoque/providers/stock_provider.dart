import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_item_model.dart';
import '../models/stock_lote_model.dart';
import '../models/stock_movimentacao_model.dart';
import '../models/epi_entrega_rastreio_model.dart';
import '../services/stock_service.dart';

/// Provider para o serviço de estoque
final stockServiceProvider = Provider<StockService>((ref) {
  return StockService();
});

/// StreamProvider reativo em tempo real para os itens do estoque do tenant
final stockStreamProvider =
    StreamProvider.family<List<StockItemModel>, String>((ref, tenantId) {
  final service = ref.watch(stockServiceProvider);
  return service.watchStockItems(tenantId);
});

/// Notifier com métodos de mutação para manter retrocompatibilidade
class StockNotifier extends FamilyAsyncNotifier<List<StockItemModel>, String> {
  @override
  Future<List<StockItemModel>> build(String arg) async {
    final service = ref.watch(stockServiceProvider);
    return service.loadStockItems(arg);
  }

  Future<void> addItem(StockItemModel item) async {
    await ref.read(stockServiceProvider).addStockItem(arg, item);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateItem(StockItemModel item) async {
    await ref.read(stockServiceProvider).updateStockItem(arg, item);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteItem(String itemId) async {
    await ref.read(stockServiceProvider).deleteStockItem(arg, itemId);
    ref.invalidateSelf();
    await future;
  }
}

final stockProvider =
    AsyncNotifierProvider.family<StockNotifier, List<StockItemModel>, String>(
  StockNotifier.new,
);

// --- ESTADOS DE CONTROLE DE UI & FILTROS ---

final stockSearchQueryProvider = StateProvider<String>((ref) => '');
final stockFilterCategoryProvider = StateProvider<String>((ref) => 'TODOS');
final stockFilterStatusProvider = StateProvider<String>((ref) => 'todos'); // 'todos', 'criticos', 'epis', 'vencendo30'
final stockViewModeProvider = StateProvider<String>((ref) => 'grid'); // 'grid' | 'table'

// --- KPIS DE INVENTÁRIO (COMPUTED PROVIDER) ---

class StockKpiData {
  final double valorTotalVenda;
  final double valorTotalCusto;
  final int totalItens;
  final int itensCriticos;
  final int episCount;
  final int casVencidos;
  final int casPertoVencer;

  const StockKpiData({
    required this.valorTotalVenda,
    required this.valorTotalCusto,
    required this.totalItens,
    required this.itensCriticos,
    required this.episCount,
    required this.casVencidos,
    required this.casPertoVencer,
  });
}

final stockKpisProvider =
    Provider.family<StockKpiData, String>((ref, tenantId) {
  final itemsAsync = ref.watch(stockStreamProvider(tenantId));
  final items = itemsAsync.valueOrNull ?? [];

  double totalVenda = 0.0;
  double totalCusto = 0.0;
  int criticos = 0;
  int epis = 0;
  int casVencidos = 0;
  int casPertoVencer = 0;

  for (final item in items) {
    totalVenda += item.precoVenda * item.qtdAtual;
    totalCusto += item.precoCusto * item.qtdAtual;
    if (item.isAlerta || item.isRuptura) criticos++;
    if (item.isEpi) {
      epis++;
      if (item.isCaVencido) casVencidos++;
      if (item.isCaPertoVencer) casPertoVencer++;
    }
  }

  return StockKpiData(
    valorTotalVenda: totalVenda,
    valorTotalCusto: totalCusto,
    totalItens: items.length,
    itensCriticos: criticos,
    episCount: epis,
    casVencidos: casVencidos,
    casPertoVencer: casPertoVencer,
  );
});

// --- LISTA FILTRADA REATIVA ---

final filteredStockProvider =
    Provider.family<List<StockItemModel>, String>((ref, tenantId) {
  final itemsAsync = ref.watch(stockStreamProvider(tenantId));
  final items = itemsAsync.valueOrNull ?? [];

  final query = ref.watch(stockSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(stockFilterCategoryProvider);
  final status = ref.watch(stockFilterStatusProvider);

  return items.where((item) {
    // 1. Filtro de texto (Nome, SKU ou CA)
    if (query.isNotEmpty) {
      final matchName = item.nomeProduto.toLowerCase().contains(query);
      final matchSku = item.sku.toLowerCase().contains(query);
      final matchCa = item.caNumero != null && item.caNumero!.contains(query);
      final matchEan = item.codigoBarrasEan != null &&
          item.codigoBarrasEan!.contains(query);
      if (!matchName && !matchSku && !matchCa && !matchEan) return false;
    }

    // 2. Filtro de Categoria
    if (category != 'TODOS' && item.categoria != category) {
      return false;
    }

    // 3. Filtro de Status Semântico
    if (status == 'criticos' && !item.isAlerta && !item.isRuptura) {
      return false;
    }
    if (status == 'epis' && !item.isEpi) {
      return false;
    }
    if (status == 'vencendo30' && !item.isCaPertoVencer && !item.isCaVencido) {
      return false;
    }

    return true;
  }).toList();
});

// --- SUB-PROVIDERS DE LOTES, MOVIMENTAÇÕES E CRM ---

final stockItemLotesProvider =
    StreamProvider.family<List<StockLoteModel>, ({String tenantId, String itemId})>(
  (ref, arg) {
    final service = ref.watch(stockServiceProvider);
    return service.watchItemLotes(arg.tenantId, arg.itemId);
  },
);

final stockMovimentacoesProvider =
    StreamProvider.family<List<StockMovimentacaoModel>, String>(
  (ref, tenantId) {
    final service = ref.watch(stockServiceProvider);
    return service.watchMovimentacoes(tenantId);
  },
);

final stockEpiEntregasProvider =
    StreamProvider.family<List<EpiEntregaRastreioModel>, String>(
  (ref, tenantId) {
    final service = ref.watch(stockServiceProvider);
    return service.watchEpiEntregas(tenantId);
  },
);

/// Item de produto/estoque resumido para consulta rápida no Atendimento (ex: EPIs)
class StockItemLookup {
  final String id;
  final String nome;
  final double preco;
  final int quantidadeEstoque;
  final String? codigoCa; // Certificado de aprovação para EPI
  final String? grade;    // Tamanho ou variação

  const StockItemLookup({
    required this.id,
    required this.nome,
    required this.preco,
    required this.quantidadeEstoque,
    this.codigoCa,
    this.grade,
  });
}

/// Contrato desacoplado para consulta e reserva de estoque
abstract class IStockService {
  Future<List<StockItemLookup>> searchAvailableStock(String tenantId, String query);
  Future<bool> hasStock(String tenantId, String itemId, int quantity);
  Future<bool> decrementStock(String tenantId, String itemId, int quantity);
}

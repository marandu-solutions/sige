import 'package:flutter_test/flutter_test.dart';
import 'package:sige/src/core/core.dart';

class MockStockService implements IStockService {
  @override
  Future<List<StockItemLookup>> searchAvailableStock(String tenantId, String query) async {
    return [
      const StockItemLookup(
        id: 'bot_1',
        nome: 'Bota Nobuck Bico Composite',
        preco: 149.90,
        quantidadeEstoque: 25,
        codigoCa: '45678',
        grade: '42',
      ),
    ];
  }

  @override
  Future<bool> hasStock(String tenantId, String itemId, int quantity) async => true;

  @override
  Future<bool> decrementStock(String tenantId, String itemId, int quantity) async => true;
}

void main() {
  test('ServiceRegistry allows decoupled IoC registration and lookup', () async {
    final registry = ServiceRegistry();
    final mockStock = MockStockService();

    registry.register<IStockService>(mockStock);

    final resolved = getService<IStockService>();
    expect(resolved, isNotNull);

    final results = await resolved!.searchAvailableStock('tenant_epi_01', 'bota');
    expect(results.length, equals(1));
    expect(results.first.nome, contains('Bota'));
    expect(results.first.codigoCa, equals('45678'));
  });
}

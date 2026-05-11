import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core/src/contracts/service_registry.dart';
import 'package:core/src/contracts/i_stock_service.dart';

/// Um exemplo de como o module_atendimento pode consumir o module_estoque 
/// sem importar diretamente o pacote de estoque, garantindo que compile mesmo se 
/// o módulo de estoque for removido.
class ExampleAtendimentoVendaWidget extends ConsumerWidget {
  final String tenantId;
  final String produtoId;
  final int quantidadeDesejada;

  const ExampleAtendimentoVendaWidget({
    Key? key,
    required this.tenantId,
    required this.produtoId,
    required this.quantidadeDesejada,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tenta obter o serviço de estoque do Registry
    final stockService = getService<IStockService>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Venda do Produto: $produtoId'),
            const SizedBox(height: 8),
            
            // Verifica se o módulo de estoque está instalado/registrado
            if (stockService == null)
              const Text(
                'Módulo de estoque não disponível. Venda liberada sem baixa automática.',
                style: TextStyle(color: Colors.orange),
              )
            else
              // Se estiver disponível, usamos o contrato para verificar o estoque
              FutureBuilder<bool>(
                future: stockService.hasStock(tenantId, produtoId, quantidadeDesejada),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  
                  if (snapshot.hasError) {
                    return const Text('Erro ao verificar estoque');
                  }
                  
                  final hasStock = snapshot.data ?? false;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasStock ? 'Em estoque!' : 'Estoque insuficiente',
                        style: TextStyle(
                          color: hasStock ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: hasStock ? () async {
                          // Realiza a venda e desconta o estoque através da Interface
                          final success = await stockService.decrementStock(
                            tenantId, 
                            produtoId, 
                            quantidadeDesejada,
                          );
                          
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Venda realizada e estoque atualizado!')),
                            );
                          }
                        } : null,
                        child: const Text('Confirmar Venda'),
                      )
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/stock_item_model.dart';
import '../providers/stock_provider.dart';
import '../widgets/add_item.dart';
import '../widgets/estoque_card.dart';

class EstoqueScreen extends ConsumerStatefulWidget {
  final String tenantId;
  const EstoqueScreen({super.key, required this.tenantId});

  @override
  ConsumerState<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends ConsumerState<EstoqueScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddItemDialog({StockItemModel? item}) {
    showDialog(
      context: context,
      builder: (context) {
        return AddEstoqueItemDialog(
          tenantId: widget.tenantId,
          item: item,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estoque = ref.watch(stockProvider(widget.tenantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle de Estoque"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar insumo...',
                  prefixIcon: const Icon(LucideIcons.search),
                ),
              ),
            ),
            Expanded(
              child: estoque.when(
                data: (items) {
                  final filteredItems = items.where((item) {
                    final query = _searchController.text.toLowerCase();
                    return item.nomeProduto.toLowerCase().contains(query);
                  }).toList();

                  filteredItems.sort((a, b) {
                    bool aAlerta = a.qtdAtual <= a.nivelAlerta;
                    bool bAlerta = b.qtdAtual <= b.nivelAlerta;
                    if (aAlerta && !bAlerta) return -1;
                    if (!aAlerta && bAlerta) return 1;
                    return a.nomeProduto.compareTo(b.nomeProduto);
                  });

                  if (filteredItems.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return EstoqueCard(
                        item: item,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text(error.toString())),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_stock_item',
        onPressed: () => _showAddItemDialog(),
        tooltip: 'Adicionar Insumo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.search,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Seu estoque está vazio.'
                : 'Nenhum item encontrado.',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Adicione seu primeiro insumo para começar.'
                : 'Tente uma busca diferente.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

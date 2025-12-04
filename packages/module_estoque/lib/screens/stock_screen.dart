import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_estoque/models/stock_item_model.dart';
import 'package:module_estoque/providers/stock_provider.dart';
import 'package:module_estoque/widgets/stock_item_card.dart';
import 'package:module_estoque/widgets/add_stock_item_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Tela principal de estoque
class StockScreen extends ConsumerWidget {
  final String tenantId;

  const StockScreen({
    super.key,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(stockProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Gestão de Estoque'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => ref.read(stockProvider.notifier).loadStockItems(tenantId),
          ),
        ],
      ),
      body: stockAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar estoque', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        data: (items) => items.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.package, size: 64, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    Text('Nenhum item em estoque', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Adicione seu primeiro produto', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return StockItemCard(item: items[index]);
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, ref),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Adicionar Item'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddStockItemDialog(
        tenantId: tenantId,
        onSave: (item) => ref.read(stockProvider.notifier).addStockItem(item),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_kanban/providers/kanban_provider.dart';
import 'package:module_kanban/widgets/kanban_column.dart';
import 'package:module_kanban/widgets/add_kanban_card_dialog.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Tela principal do Kanban
class KanbanScreen extends ConsumerWidget {
  final String tenantId;

  const KanbanScreen({
    super.key,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanbanAsync = ref.watch(kanbanProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Quadro Kanban'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () =>
                ref.read(kanbanProvider.notifier).loadCards(tenantId),
          ),
        ],
      ),
      body: kanbanAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar cartões',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        data: (cards) => Row(
          children: [
            // Coluna To Do
            Expanded(
              child: KanbanColumn(
                title: 'A Fazer',
                columnId: 'to_do',
                cards: cards
                    .where((card) => card.colunaStatus == 'to_do')
                    .toList(),
                color: colorScheme.secondary,
                onCardMove: (cardId, newColumn) => ref
                    .read(kanbanProvider.notifier)
                    .moveCard(cardId, newColumn),
              ),
            ),
            // Coluna In Progress
            Expanded(
              child: KanbanColumn(
                title: 'Em Progresso',
                columnId: 'in_progress',
                cards: cards
                    .where((card) => card.colunaStatus == 'in_progress')
                    .toList(),
                color: colorScheme.tertiary,
                onCardMove: (cardId, newColumn) => ref
                    .read(kanbanProvider.notifier)
                    .moveCard(cardId, newColumn),
              ),
            ),
            // Coluna Done
            Expanded(
              child: KanbanColumn(
                title: 'Concluído',
                columnId: 'done',
                cards:
                    cards.where((card) => card.colunaStatus == 'done').toList(),
                color: colorScheme.primary,
                onCardMove: (cardId, newColumn) => ref
                    .read(kanbanProvider.notifier)
                    .moveCard(cardId, newColumn),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCardDialog(context, ref),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Adicionar Card'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AddKanbanCardDialog(
        tenantId: tenantId,
        onSave: (card) => ref.read(kanbanProvider.notifier).addCard(card),
      ),
    );
  }
}

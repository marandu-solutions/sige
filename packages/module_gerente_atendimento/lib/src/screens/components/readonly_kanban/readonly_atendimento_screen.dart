import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_atendimento/module_atendimento.dart';
import 'readonly_atendimento_column.dart';

class ReadOnlyAtendimentoScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final String funcionarioIdFilter;

  const ReadOnlyAtendimentoScreen({
    super.key,
    required this.tenantId,
    required this.funcionarioIdFilter,
  });

  @override
  ConsumerState<ReadOnlyAtendimentoScreen> createState() =>
      _ReadOnlyAtendimentoScreenState();
}

class _ReadOnlyAtendimentoScreenState
    extends ConsumerState<ReadOnlyAtendimentoScreen> {
  late final ScrollController _scrollController;
  AtendimentoCardModel? _cardSelecionado;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atendimentoAsync = ref.watch(atendimentoProvider(widget.tenantId));
    final colorScheme = Theme.of(context).colorScheme;

    // Se estiver carregando ou erro, tratamos normalmente
    return atendimentoAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erro: $error')),
      data: (board) {
        if (board.columns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.columns,
                  size: 64,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma coluna encontrada',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            // Usando ListView.builder em vez de ReorderableListView
            ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: board.columns.length,
              itemBuilder: (context, index) {
                final column = board.columns[index];
                final columnCards = board.cards
                    .where((card) => card.colunaStatus == column.id)
                    .where((card) =>
                        card.funcionarioResponsavelId ==
                        widget.funcionarioIdFilter)
                    .toList();

                return SizedBox(
                  key: ValueKey(column.id),
                  width: 336, // 320 width + 16 margin
                  child: ReadOnlyAtendimentoColumn(
                    column: column,
                    cards: columnCards,
                    onCardTap: (card) => _handleCardTap(card),
                  ),
                );
              },
            ),

            // Chat flutuante (Permitido visualizar/interagir com o chat?)
            // O gerente pode querer ver o chat.
            if (_cardSelecionado != null)
              ChatPage(
                tenantId: widget.tenantId,
                atendimentoId: _cardSelecionado!.id,
                contactName: _cardSelecionado!.clienteNome,
                onClose: () {
                  setState(() {
                    _cardSelecionado = null;
                  });
                },
              ),
          ],
        );
      },
    );
  }

  void _handleCardTap(AtendimentoCardModel card) {
    setState(() {
      _cardSelecionado = card;
    });
  }
}

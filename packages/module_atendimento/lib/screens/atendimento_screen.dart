import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:module_atendimento/models/atendimento_model.dart';
import 'package:module_atendimento/providers/atendimento_provider.dart';
import 'package:module_atendimento/widgets/add_edit_atendimento_column_dialog.dart';
import 'package:module_atendimento/widgets/atendimento_column.dart';
import 'package:module_atendimento/widgets/add_atendimento_card_dialog.dart';
import 'package:module_atendimento/widgets/move_cards_and_delete_atendimento_column_dialog.dart';
import 'package:module_atendimento/widgets/chat_page.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math';

class AtendimentoScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final String? funcionarioIdFilter;

  const AtendimentoScreen({
    super.key,
    required this.tenantId,
    this.funcionarioIdFilter,
  });

  @override
  ConsumerState<AtendimentoScreen> createState() => _AtendimentoScreenState();
}

class _AtendimentoScreenState extends ConsumerState<AtendimentoScreen> {
  late final ScrollController _scrollController;
  AtendimentoModel? _cardSelecionado;

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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Atendimentos'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus),
            tooltip: 'Adicionar Coluna',
            onPressed: () => _showAddEditColumnDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(LucideIcons.userPlus),
            tooltip: 'Adicionar Atendimento',
            onPressed: () => _showAddCardDialog(context, ref),
          ),
        ],
      ),
      body: atendimentoAsync.when(
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
                  const SizedBox(height: 8),
                  Text(
                    'Crie sua primeira coluna para começar a organizar seus atendimentos',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditColumnDialog(context, ref),
                    icon: const Icon(LucideIcons.plus),
                    label: const Text('Adicionar Coluna'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ReorderableListView.builder(
                buildDefaultDragHandles: false,
                scrollDirection: Axis.horizontal,
                scrollController: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: board.columns.length,
                itemBuilder: (context, index) {
                  final column = board.columns[index];
                  final columnCards = board.cards
                      .where((card) => card.colunaStatus == column.id)
                      .where((card) =>
                          widget.funcionarioIdFilter == null ||
                          card.funcionarioResponsavelId ==
                              widget.funcionarioIdFilter)
                      .toList();

                  return SizedBox(
                    key: ValueKey(column.id),
                    width: 336, // 320 width + 16 margin
                    child: AtendimentoColumn(
                      column: column,
                      cards: columnCards,
                      onCardMove: (cardId, newColumn) =>
                          _handleCardMove(ref, cardId, newColumn),
                      onEdit: () =>
                          _showAddEditColumnDialog(context, ref, column),
                      onCardTap: (card) => _handleCardTap(card),
                      columnIndex: index,
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  ref
                      .read(atendimentoProvider(widget.tenantId).notifier)
                      .reorderColumns(oldIndex, newIndex);
                },
              ),

              // Chat flutuante
              if (_cardSelecionado != null)
                ChatPage(
                  tenantId: widget.tenantId,
                  atendimentoId: _cardSelecionado!.id,
                  contactName: _cardSelecionado!.clienteNome,
                  contactPhone: _cardSelecionado!.clienteTelefone,
                  leadId: _cardSelecionado!.leadId,
                  fotoUrl: _cardSelecionado!.fotoUrl,
                  onClose: () {
                    setState(() {
                      _cardSelecionado = null;
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleCardTap(AtendimentoModel card) {
    if (card.mensagensNaoLidas > 0) {
      ref
          .read(atendimentoProvider(widget.tenantId).notifier)
          .resetUnreadCount(card.id);
    }
    setState(() {
      _cardSelecionado = card;
    });
  }

  void _handleCardMove(WidgetRef ref, String cardId, String newColumn) {
    ref
        .read(atendimentoProvider(widget.tenantId).notifier)
        .moveCard(cardId, newColumn);
  }

  void _showAddEditColumnDialog(
    BuildContext context,
    WidgetRef ref, [
    AtendimentoColumnModel? column,
  ]) {
    showDialog(
      context: context,
      builder: (context) => AddEditAtendimentoColumnDialog(
        column: column,
        onSave: (title, color) {
          if (column == null) {
            // Adicionar nova coluna
            final newColumn = AtendimentoColumnModel(
              id: 'temp_${Random().nextInt(1000000)}',
              tenantId: widget.tenantId,
              title: title,
              colorValue: color.toARGB32(),
              order: 0,
            );
            ref
                .read(atendimentoProvider(widget.tenantId).notifier)
                .addColumn(newColumn);
          } else {
            // Editar coluna existente
            final updatedColumn = column.copyWith(
              title: title,
              colorValue: color.toARGB32(),
            );
            ref
                .read(atendimentoProvider(widget.tenantId).notifier)
                .updateColumn(updatedColumn);
          }
        },
        onDelete: column != null
            ? () => _handleDeleteColumn(context, ref, column)
            : null,
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    final atendimentoAsync = ref.read(atendimentoProvider(widget.tenantId));
    if (atendimentoAsync.valueOrNull?.columns.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Crie uma coluna primeiro antes de adicionar atendimentos')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddAtendimentoCardDialog(
        tenantId: widget.tenantId,
        columns: atendimentoAsync.valueOrNull!.columns,
        onSave: (titulo, clienteNome, clienteTelefone, prioridade, colunaId,
            leadId, fotoUrl) {
          final newCard = AtendimentoModel(
            id: 'temp_${Random().nextInt(1000000)}',
            tenantId: widget.tenantId,
            titulo: titulo,
            clienteNome: clienteNome,
            clienteTelefone: clienteTelefone,
            colunaStatus: colunaId,
            prioridade: prioridade,
            dataCriacao: DateTime.now(),
            dataUltimaAtualizacao: DateTime.now(),
            dataEntradaColuna: DateTime.now(),
            status: 'ativo',
            ultimaMensagem: '',
            ultimaMensagemData: DateTime.now(),
            mensagensNaoLidas: 0,
            leadId: leadId,
            fotoUrl: fotoUrl,
          );
          ref
              .read(atendimentoProvider(widget.tenantId).notifier)
              .addCard(newCard);
        },
      ),
    );
  }

  void _handleDeleteColumn(
    BuildContext context,
    WidgetRef ref,
    AtendimentoColumnModel column,
  ) {
    final atendimentoAsync = ref.read(atendimentoProvider(widget.tenantId));
    if (atendimentoAsync.valueOrNull == null) return;

    final board = atendimentoAsync.valueOrNull!;
    final columnCards =
        board.cards.where((card) => card.colunaStatus == column.id).toList();

    if (columnCards.isEmpty) {
      // Se não houver cards, pede confirmação simples
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Excluir Coluna'),
          content: Text(
              'Tem certeza que deseja excluir a coluna "${column.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(atendimentoProvider(widget.tenantId).notifier)
                    .deleteColumn(column.id);
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('EXCLUIR'),
            ),
          ],
        ),
      );
      return;
    }

    final otherColumns =
        board.columns.where((col) => col.id != column.id).toList();

    if (otherColumns.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não é possível excluir a única coluna')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MoveCardsAndDeleteAtendimentoColumnDialog(
        columnToDelete: column,
        cardsCount: columnCards.length,
        otherColumns: otherColumns,
        onConfirm: (targetColumnId) {
          ref
              .read(atendimentoProvider(widget.tenantId).notifier)
              .deleteColumn(column.id, targetColumnId: targetColumnId);
        },
      ),
    );
  }
}

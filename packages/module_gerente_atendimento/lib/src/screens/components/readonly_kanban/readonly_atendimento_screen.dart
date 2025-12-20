import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_atendimento/module_atendimento.dart';
import 'package:module_gerente_atendimento/src/providers/gerente_atendimento_provider.dart';
import 'package:module_gerente_atendimento/src/screens/components/readonly_kanban/readonly_chat_page.dart';
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
    final atendimentoAsync =
        ref.watch(gerenteAtendimentoProvider(widget.tenantId));
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors
          .transparent, // Permite que o gradiente do pai apareça se houver
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF141414),
                    const Color(0xFF0A0A0A),
                  ]
                : [
                    const Color(0xFFF5F7FA),
                    const Color(0xFFE4E7EB),
                  ],
          ),
        ),
        child: atendimentoAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.alertTriangle,
                    size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text('Erro ao carregar dados',
                    style: TextStyle(color: colorScheme.error)),
              ],
            ),
          ),
          data: (board) {
            if (board.columns.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.trello,
                      size: 64,
                      color: colorScheme.onSurface.withOpacity(0.1),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhum quadro disponível',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'As colunas aparecerão aqui quando configuradas.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                // Kanban Board Horizontal Scroll
                Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    itemCount: board.columns.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final column = board.columns[index];
                      final columnCards = board.cards
                          .where((card) => card.colunaStatus == column.id)
                          .where((card) =>
                              card.funcionarioResponsavelId ==
                              widget.funcionarioIdFilter)
                          .toList();

                      return Padding(
                        padding: EdgeInsets.only(
                            right: index == board.columns.length - 1 ? 0 : 8),
                        child: ReadOnlyAtendimentoColumn(
                          key: ValueKey(column.id),
                          column: column,
                          cards: columnCards,
                          onCardTap: (card) => _handleCardTap(card),
                        ),
                      );
                    },
                  ),
                ),

                // Chat Overlay com Animação Simples
                if (_cardSelecionado != null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black54, // Backdrop
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          margin: const EdgeInsets.all(24),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ReadOnlyChatPage(
                            tenantId: widget.tenantId,
                            atendimentoId: _cardSelecionado!.id,
                            contactName: _cardSelecionado!.clienteNome,
                            contactPhone: _cardSelecionado!.clienteTelefone,
                            fotoUrl: _cardSelecionado!.fotoUrl,
                            onClose: () {
                              setState(() {
                                _cardSelecionado = null;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleCardTap(AtendimentoModel card) {
    setState(() {
      _cardSelecionado = card;
    });
  }
}

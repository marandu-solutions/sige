import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math';
import 'package:core/core.dart';
import 'package:module_admin_empresa/module_admin_empresa.dart';
import 'package:module_admin_empresa/src/providers/admin_providers.dart';
import 'package:module_atendimento/module_atendimento.dart';
import 'package:module_gerente_atendimento/src/providers/gerente_atendimento_provider.dart';
import 'components/funcionario_atendimento_column.dart';
import 'components/add_lead_gerente_dialog.dart';
import 'components/readonly_kanban/readonly_atendimento_screen.dart';
import 'components/readonly_kanban/readonly_chat_page.dart';

class GerenteAtendimentoScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const GerenteAtendimentoScreen({super.key, required this.tenantId});

  @override
  ConsumerState<GerenteAtendimentoScreen> createState() =>
      _GerenteAtendimentoScreenState();
}

class _GerenteAtendimentoScreenState
    extends ConsumerState<GerenteAtendimentoScreen> {
  late final ScrollController _scrollController;
  AtendimentoModel? _selectedCard;

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
    final funcionariosAsync = ref.watch(funcionariosProvider(widget.tenantId));
    final atendimentoAsync =
        ref.watch(gerenteAtendimentoProvider(widget.tenantId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Visão do Gerente'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Stack(
        children: [
          funcionariosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Erro ao carregar funcionários: $err')),
            data: (funcionarios) {
              if (funcionarios.isEmpty) {
                return const Center(
                    child: Text('Nenhum funcionário encontrado.'));
              }

              return atendimentoAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Erro ao carregar atendimentos: $err')),
                data: (board) {
                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    itemCount: funcionarios.length,
                    itemBuilder: (context, index) {
                      final funcionario = funcionarios[index];
                      final employeeCards = board.cards
                          .where(
                            (card) =>
                                card.funcionarioResponsavelId == funcionario.id,
                          )
                          .toList();

                      return FuncionarioAtendimentoColumn(
                        funcionario: funcionario,
                        cards: employeeCards,
                        onExpand: () =>
                            _openFuncionarioKanban(context, funcionario),
                        onCardTap: (card) {
                          setState(() {
                            _selectedCard = card;
                          });
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          if (_selectedCard != null)
            ReadOnlyChatPage(
              tenantId: widget.tenantId,
              atendimentoId: _selectedCard!.id,
              contactName: _selectedCard!.clienteNome,
              contactPhone: _selectedCard!.clienteTelefone,
              fotoUrl: _selectedCard!.fotoUrl,
              onClose: () {
                setState(() {
                  _selectedCard = null;
                });
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLeadDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showAddLeadDialog(BuildContext context) {
    final atendimentoAsync =
        ref.read(gerenteAtendimentoProvider(widget.tenantId));
    final funcionariosAsync = ref.read(funcionariosProvider(widget.tenantId));

    if (atendimentoAsync.valueOrNull?.columns.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Crie uma coluna primeiro antes de adicionar atendimentos')),
      );
      return;
    }

    if (!funcionariosAsync.hasValue || funcionariosAsync.value!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Nenhum funcionário disponível para atribuir o lead')),
      );
      // Opcional: permitir criar sem funcionário mesmo assim?
      // Por enquanto vamos assumir que pode continuar se a lista estiver vazia, mas o dropdown ficará vazio.
    }

    showDialog(
      context: context,
      builder: (context) => AddLeadGerenteDialog(
        tenantId: widget.tenantId,
        columns: atendimentoAsync.valueOrNull!.columns,
        funcionarios: funcionariosAsync.value ?? [],
        onSave: (titulo, clienteNome, clienteTelefone, prioridade, dataLimite,
            colunaId, funcionarioId, leadId) {
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
            funcionarioResponsavelId: funcionarioId,
            leadId: leadId,
          );
          ref
              .read(gerenteAtendimentoProvider(widget.tenantId).notifier)
              .addCard(newCard);
        },
      ),
    );
  }

  void _openFuncionarioKanban(
    BuildContext context,
    FuncionarioModel funcionario,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Scaffold(
                appBar: AppBar(
                  title: Text('Kanban: ${funcionario.nome}'),
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                body: ReadOnlyAtendimentoScreen(
                  tenantId: widget.tenantId,
                  funcionarioIdFilter: funcionario.id,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

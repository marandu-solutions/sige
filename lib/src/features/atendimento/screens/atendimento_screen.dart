import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/features/atendimento/models/atendimento_column_model.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/providers/atendimento_provider.dart';
import 'package:sige/src/features/atendimento/widgets/add_edit_atendimento_column_dialog.dart';
import 'package:sige/src/features/atendimento/widgets/atendimento_column.dart';
import 'package:sige/src/features/atendimento/widgets/add_atendimento_card_dialog.dart';
import 'package:sige/src/features/atendimento/widgets/move_cards_and_delete_atendimento_column_dialog.dart';
import 'package:sige/src/features/atendimento/widgets/chat_page.dart';
import 'package:sige/src/features/atendimento/screens/history_atendimento_screen/history_atendimento_screen.dart';
import 'package:sige/src/features/auth/auth_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';

import 'package:sige/src/core/core.dart';

/// Workspace Pessoal de Alta Performance do Vendedor / Atendente (Sally UX)
/// Projetado com design moderno, micro-interações, busca instantânea,
/// filtros de foco operacional e KPIs de produtividade ao vivo.
class AtendimentoScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const AtendimentoScreen({
    super.key,
    required this.tenantId,
  });

  @override
  ConsumerState<AtendimentoScreen> createState() => _AtendimentoScreenState();
}

class _AtendimentoScreenState extends ConsumerState<AtendimentoScreen> {
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  AtendimentoModel? _cardSelecionado;
  String _vendedorFilter = 'all'; // 'all', 'unread', 'high_priority', 'followup'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final atendimentoAsync = ref.watch(atendimentoProvider(widget.tenantId));
    final authService = ref.watch(authServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final userName = authService.userData?['nome'] ?? 'Vendedor';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: isDark ? SigeColors.darkBg : SigeColors.lightBg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.messageSquareQuote,
                size: 20,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Meus Atendimentos',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.zap, size: 10, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            'PRODUTIVIDADE VENDAS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_getGreeting()}, $firstName • Avance negociações e feche cotações',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? SigeColors.darkTextSecondary
                        : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.history, size: 18),
            tooltip: 'Histórico de Atendimentos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HistoryAtendimentoScreen(
                    tenantId: widget.tenantId,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 18),
            tooltip: 'Adicionar Etapa ao Funil',
            onPressed: () => _showAddEditColumnDialog(context, ref),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(LucideIcons.userPlus, size: 15),
            label: const Text(
              'Novo Cliente',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            onPressed: () => _showAddCardDialog(context, ref),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: atendimentoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Erro ao carregar atendimentos: $error')),
        data: (board) {
          // Filtra para trazer os atendimentos pertencentes ao vendedor logado
          final myCards = board.cards.where((card) {
            if (currentUserId != null) {
              return card.funcionarioResponsavelId == currentUserId;
            }
            return true;
          }).toList();

          final unreadCards =
              myCards.where((c) => c.mensagensNaoLidas > 0).toList();
          final highPriorityCards = myCards
              .where((c) =>
                  c.prioridade.toLowerCase() == 'alta' ||
                  c.prioridade.toLowerCase() == 'urgente')
              .toList();

          return Column(
            children: [
              // ==========================================
              // HEADER DE ALTA PERFORMANCE (METAS & FOCO)
              // ==========================================
              _buildSellerCockpitHeader(
                context,
                colorScheme,
                isDark,
                firstName: firstName,
                totalCards: myCards.length,
                unreadCount: unreadCards.length,
                highPriorityCount: highPriorityCards.length,
              ),

              // ==========================================
              // BARRA DE FOCO & BUSCA INSTANTÂNEA
              // ==========================================
              _buildSellerFocusBar(
                context,
                colorScheme,
                isDark,
                totalCount: myCards.length,
                unreadCount: unreadCards.length,
                highPriorityCount: highPriorityCards.length,
              ),

              // ==========================================
              // KANBAN VIEWPORT DO VENDEDOR
              // ==========================================
              Expanded(
                child: board.columns.isEmpty
                    ? _buildEmptyColumnsState(context, colorScheme)
                    : Stack(
                        children: [
                          ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            scrollDirection: Axis.horizontal,
                            scrollController: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: board.columns.length,
                            itemBuilder: (context, index) {
                              final column = board.columns[index];

                              // Filtro dinâmico por coluna + filtros de foco e busca
                              final columnCards = myCards
                                  .where((card) =>
                                      card.colunaStatus == column.id)
                                  .where((card) {
                                // Filtro de busca por texto
                                if (_searchQuery.isNotEmpty) {
                                  final matchName = card.clienteNome
                                      .toLowerCase()
                                      .contains(_searchQuery);
                                  final matchPhone =
                                      card.clienteTelefone.contains(_searchQuery);
                                  final matchTitle = card.titulo
                                      .toLowerCase()
                                      .contains(_searchQuery);
                                  if (!matchName && !matchPhone && !matchTitle) {
                                    return false;
                                  }
                                }

                                // Filtros rápidos
                                if (_vendedorFilter == 'unread') {
                                  return card.mensagensNaoLidas > 0;
                                }
                                if (_vendedorFilter == 'high_priority') {
                                  return card.prioridade.toLowerCase() ==
                                          'alta' ||
                                      card.prioridade.toLowerCase() ==
                                          'urgente';
                                }
                                return true;
                              }).toList();

                              return SizedBox(
                                key: ValueKey(column.id),
                                width: 334,
                                child: AtendimentoColumn(
                                  column: column,
                                  cards: columnCards,
                                  onCardMove: (cardId, newColumn) =>
                                      _handleCardMove(ref, cardId, newColumn),
                                  onEdit: () => _showAddEditColumnDialog(
                                      context, ref, column),
                                  onCardTap: (card) => _handleCardTap(card),
                                  onCardReassign: null, // Vendedor não reatribui cards
                                  columnIndex: index,
                                ),
                              );
                            },
                            onReorder: (oldIndex, newIndex) {
                              ref
                                  .read(
                                      atendimentoProvider(widget.tenantId).notifier)
                                  .reorderColumns(oldIndex, newIndex);
                            },
                          ),

                          // Chat Flutuante
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // HEADER DE METAS & STATUS DO VENDEDOR (Cockpit Ribbon)
  // ===========================================================================
  Widget _buildSellerCockpitHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required String firstName,
    required int totalCards,
    required int unreadCount,
    required int highPriorityCount,
  }) {
    String motivationText;
    if (unreadCount > 0) {
      motivationText =
          'Atenção: Você tem $unreadCount clientes esperando resposta no WhatsApp/Omnichannel!';
    } else if (totalCards > 0) {
      motivationText =
          'Sua carteira está 100% respondida! Ótimo momento para avançar propostas.';
    } else {
      motivationText =
          'Nenhum cliente ativo no momento. Solicite leads ou cadastre uma nova cotação.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? SigeColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Ícone de Status de Ritmo
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: unreadCount > 0
                  ? const Color(0xFF10B981).withOpacity(0.12)
                  : colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              unreadCount > 0 ? LucideIcons.messageCircle : LucideIcons.trendingUp,
              size: 20,
              color: unreadCount > 0 ? const Color(0xFF10B981) : colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Texto de Acolhimento e Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Pipeline Ativo de $firstName',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: unreadCount > 0
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        unreadCount > 0 ? 'Respostas Pendentes' : 'Carteira em Dia',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: unreadCount > 0
                              ? const Color(0xFFB45309)
                              : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  motivationText,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? SigeColors.darkTextSecondary
                        : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // KPI Chips de Alto Impacto
          _buildKpiBadge(
            label: 'Em Negociação',
            value: '$totalCards',
            icon: LucideIcons.users,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _buildKpiBadge(
            label: 'Aguardando Resposta',
            value: '$unreadCount',
            icon: LucideIcons.messageSquare,
            color: unreadCount > 0 ? const Color(0xFF10B981) : Colors.grey,
            isAlert: unreadCount > 0,
          ),
          const SizedBox(width: 8),
          _buildKpiBadge(
            label: 'Alta Prioridade',
            value: '$highPriorityCount',
            icon: LucideIcons.flame,
            color: highPriorityCount > 0 ? const Color(0xFFEF4444) : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiBadge({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(isAlert ? 0.4 : 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: color.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BARRA DE FOCO & BUSCA INSTANTÂNEA DO VENDEDOR
  // ===========================================================================
  Widget _buildSellerFocusBar(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark, {
    required int totalCount,
    required int unreadCount,
    required int highPriorityCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? SigeColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          // Campo de Busca Rápida Instantânea
          Expanded(
            flex: 2,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkBg : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                  width: 0.8,
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Filtrar cliente por nome, telefone ou produto...',
                  hintStyle: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? SigeColors.darkTextMuted
                        : SigeColors.lightTextMuted,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 14,
                    color: isDark
                        ? SigeColors.darkTextMuted
                        : SigeColors.lightTextMuted,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 12),
                          onPressed: () => _searchController.clear(),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Segmented Focus Pills (Filtros de Produtividade)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFocusPill(
                    label: 'Todos os Clientes',
                    count: totalCount,
                    filterKey: 'all',
                    icon: LucideIcons.layoutGrid,
                    activeColor: colorScheme.primary,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFocusPill(
                    label: 'Mensagens Não Lidas',
                    count: unreadCount,
                    filterKey: 'unread',
                    icon: LucideIcons.messageSquare,
                    activeColor: const Color(0xFF10B981),
                    isAlert: unreadCount > 0,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildFocusPill(
                    label: 'Alta Prioridade',
                    count: highPriorityCount,
                    filterKey: 'high_priority',
                    icon: LucideIcons.flame,
                    activeColor: const Color(0xFFEF4444),
                    isAlert: highPriorityCount > 0,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusPill({
    required String label,
    required int count,
    required String filterKey,
    required IconData icon,
    required Color activeColor,
    required bool isDark,
    bool isAlert = false,
  }) {
    final isSelected = _vendedorFilter == filterKey;

    return InkWell(
      onTap: () {
        setState(() {
          _vendedorFilter = isSelected && filterKey != 'all' ? 'all' : filterKey;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(isDark ? 0.2 : 0.12)
              : (isDark
                  ? Colors.white.withOpacity(0.03)
                  : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? activeColor
                  : (isDark
                      ? SigeColors.darkTextSecondary
                      : SigeColors.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? activeColor
                    : (isDark
                        ? SigeColors.darkTextPrimary
                        : SigeColors.lightTextPrimary),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : (isDark ? SigeColors.darkBg : Colors.white),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ESTADO VAZIO & OPERAÇÕES
  // ===========================================================================
  Widget _buildEmptyColumnsState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.columns,
            size: 54,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhuma etapa cadastrada no funil',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crie sua primeira etapa para organizar o fluxo de atendimento da sua carteira',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _showAddEditColumnDialog(context, ref),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Adicionar Coluna'),
          ),
        ],
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
        onSave: (title, color, isInitial) {
          if (column == null) {
            final newColumn = AtendimentoColumnModel(
              id: 'temp_${Random().nextInt(1000000)}',
              tenantId: widget.tenantId,
              title: title,
              colorValue: color.toARGB32(),
              order: 0,
              isInitial: isInitial,
            );
            ref
                .read(atendimentoProvider(widget.tenantId).notifier)
                .addColumn(newColumn);
          } else {
            final updatedColumn = column.copyWith(
              title: title,
              colorValue: color.toARGB32(),
              isInitial: isInitial,
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
            leadId, fotoUrl, metadata) {
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
            funcionarioResponsavelId:
                FirebaseAuth.instance.currentUser?.uid,
            leadId: leadId,
            fotoUrl: fotoUrl,
            metadata: metadata,
          );
          ref
              .read(atendimentoProvider(widget.tenantId).notifier)
              .addCard(newCard);

          fireEvent(NewLeadEvent(
            tenantId: widget.tenantId,
            leadId: leadId ?? newCard.id,
            leadName: clienteNome,
          ));

          fireEvent(AlertEvent(
            message: 'Novo atendimento criado para $clienteNome',
            type: AlertType.success,
          ));
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

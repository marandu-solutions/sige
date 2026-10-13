import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/features/atendimento/models/atendimento_column_model.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/providers/atendimento_provider.dart';
import 'package:sige/src/features/atendimento/widgets/add_edit_atendimento_column_dialog.dart';
import 'package:sige/src/features/atendimento/widgets/atendimento_column.dart';
import 'package:sige/src/features/atendimento/widgets/add_atendimento_card_dialog.dart';
import 'package:sige/src/features/atendimento/widgets/move_cards_and_delete_atendimento_column_dialog.dart';
import 'package:sige/src/features/atendimento/widgets/chat_page.dart';
import 'package:sige/src/features/atendimento/widgets/exp_atendimento_config_dialog.dart';
import 'package:sige/src/features/atendimento/screens/history_atendimento_screen/history_atendimento_screen.dart';
import 'package:sige/src/features/admin_empresa/src/providers/admin_providers.dart';
import 'package:sige/src/core/models/funcionario_model.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:math';

import 'package:sige/src/core/core.dart';

/// Cockpit de Comando Executivo do Gerente de Atendimento (Sally UX)
/// Arquitetura Dual-Pane: Radar Operacional da Equipe + Viewport do Funil ao Vivo.
/// Suporta 1 a 100+ atendentes com pesquisa instantânea, termômetro de carga,
/// redistribuição inteligente e remanejamento por Drag & Drop direto na sidebar.
class GerenteAtendimentoScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const GerenteAtendimentoScreen({
    super.key,
    required this.tenantId,
  });

  @override
  ConsumerState<GerenteAtendimentoScreen> createState() =>
      _GerenteAtendimentoScreenState();
}

class _GerenteAtendimentoScreenState
    extends ConsumerState<GerenteAtendimentoScreen> {
  late final ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  AtendimentoModel? _cardSelecionado;
  String _selectedSupervisorFilter = 'all'; // 'all', 'unassigned' ou funcionarioId
  String _searchQuery = '';
  String _teamWorkloadFilter = 'todos'; // 'todos', 'sobrecarga', 'disponiveis'
  bool _isSidebarCollapsed = false;

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

  @override
  Widget build(BuildContext context) {
    final atendimentoAsync = ref.watch(atendimentoProvider(widget.tenantId));
    final funcionariosAsync = ref.watch(funcionariosProvider(widget.tenantId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final funcionarios = funcionariosAsync.valueOrNull ?? [];

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
              child: Icon(LucideIcons.shieldCheck, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Cockpit de Supervisão Comercial',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.secondary.withOpacity(0.3),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'MODO GERENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Radar da equipe em tempo real • Auditoria e remanejamento ágil de leads',
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
            icon: const Icon(LucideIcons.clock, size: 18),
            tooltip: 'Configurar Regras de Expiração',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ExpAtendimentoConfigDialog(
                  tenantId: widget.tenantId,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.history, size: 18),
            tooltip: 'Histórico Completo de Atendimentos',
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
            label: const Text('Novo Lead', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onPressed: () => _showAddCardDialog(context, ref),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: atendimentoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erro ao carregar atendimentos: $error')),
        data: (board) {
          final unassignedCards = board.cards
              .where((c) =>
                  c.funcionarioResponsavelId == null ||
                  c.funcionarioResponsavelId!.isEmpty)
              .toList();

          // Identifica o atendente atualmente inspecionado
          FuncionarioModel? selectedFuncionario;
          if (_selectedSupervisorFilter != 'all' &&
              _selectedSupervisorFilter != 'unassigned') {
            try {
              selectedFuncionario = funcionarios.firstWhere(
                (f) => f.id == _selectedSupervisorFilter,
              );
            } catch (_) {
              selectedFuncionario = null;
            }
          }

          return Row(
            children: [
              // ==========================================
              // PAINEL LATERAL: RADAR OPERACIONAL DA EQUIPE
              // ==========================================
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: _isSidebarCollapsed ? 68 : 310,
                decoration: BoxDecoration(
                  color: isDark ? SigeColors.darkSurface : Colors.white,
                  border: Border(
                    right: BorderSide(
                      color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                      width: 0.8,
                    ),
                  ),
                ),
                child: _isSidebarCollapsed
                    ? _buildCollapsedSidebar(
                        context,
                        colorScheme,
                        isDark,
                        board.cards,
                        funcionarios,
                        unassignedCards.length,
                      )
                    : _buildExpandedRadarSidebar(
                        context,
                        colorScheme,
                        isDark,
                        board.cards,
                        funcionarios,
                        unassignedCards.length,
                      ),
              ),

              // ==========================================
              // VIEWPORT PRINCIPAL: HUD EXECUTIVO + KANBAN
              // ==========================================
              Expanded(
                child: Column(
                  children: [
                    // HUD Executivo do Atendente / Contexto Inspecionado
                    _buildExecutiveHud(
                      context,
                      colorScheme,
                      isDark,
                      selectedFuncionario,
                      _selectedSupervisorFilter,
                      board.cards,
                      unassignedCards,
                      funcionarios,
                    ),

                    // O Funil de Vendas do Atendente Inspecionado
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

                                    // Filtro dinâmico pelo vendedor inspecionado pelo gerente
                                    final columnCards = board.cards
                                        .where((card) =>
                                            card.colunaStatus == column.id)
                                        .where((card) {
                                      if (_selectedSupervisorFilter == 'unassigned') {
                                        return card.funcionarioResponsavelId ==
                                                null ||
                                            card.funcionarioResponsavelId!.isEmpty;
                                      }
                                      if (_selectedSupervisorFilter != 'all') {
                                        return card.funcionarioResponsavelId ==
                                            _selectedSupervisorFilter;
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
                                        onCardReassign: (card) => _showReassignDialog(
                                          context,
                                          card,
                                          funcionarios,
                                        ),
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

                                // Chat Flutuante se um card for aberto
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SIDEBAR EXPANDIDA: RADAR OPERACIONAL DA EQUIPE
  // ===========================================================================
  Widget _buildExpandedRadarSidebar(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    List<AtendimentoModel> allCards,
    List<FuncionarioModel> funcionarios,
    int unassignedCount,
  ) {
    // Aplica filtros de busca e carga de trabalho
    final filteredFuncionarios = funcionarios.where((func) {
      if (_searchQuery.isNotEmpty) {
        final matchNome = func.nome.toLowerCase().contains(_searchQuery);
        final matchCargo = (func.cargo ?? '').toLowerCase().contains(_searchQuery);
        if (!matchNome && !matchCargo) return false;
      }

      final count = allCards
          .where((c) => c.funcionarioResponsavelId == func.id)
          .length;

      if (_teamWorkloadFilter == 'sobrecarga') {
        return count >= 10;
      } else if (_teamWorkloadFilter == 'disponiveis') {
        return count <= 4;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Topo da Sidebar: Título + Botão de Colapsar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
          child: Row(
            children: [
              Icon(LucideIcons.usersRound, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Radar da Equipe',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? SigeColors.darkTextPrimary : SigeColors.lightTextPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${funcionarios.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(LucideIcons.panelLeftClose, size: 16),
                tooltip: 'Recolher Painel',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _isSidebarCollapsed = true),
              ),
            ],
          ),
        ),

        // Barra de Busca Rápida de Atendentes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
                hintText: 'Buscar atendente ou cargo...',
                hintStyle: TextStyle(
                  fontSize: 11,
                  color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 14,
                  color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
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

        // Filtros Rápidos de Carga (Tabs Segmentadas)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Row(
            children: [
              _buildFilterPill('Todos', 'todos', colorScheme, isDark),
              const SizedBox(width: 4),
              _buildFilterPill('Sobrecarga', 'sobrecarga', colorScheme, isDark),
              const SizedBox(width: 4),
              _buildFilterPill('Livres', 'disponiveis', colorScheme, isDark),
            ],
          ),
        ),

        const Divider(height: 1, thickness: 0.8),

        // Itens Fixos: Visão Panorâmica + Fila IA 24/7
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
          child: Column(
            children: [
              // 1. Visão Panorâmica (Todos)
              _buildSpecialDockItem(
                title: 'Visão Panorâmica',
                subtitle: 'Todos os clientes no funil',
                count: allCards.length,
                icon: LucideIcons.layoutGrid,
                iconColor: colorScheme.primary,
                isSelected: _selectedSupervisorFilter == 'all',
                onTap: () => setState(() => _selectedSupervisorFilter = 'all'),
                isDark: isDark,
              ),
              const SizedBox(height: 6),

              // 2. Fila IA 24/7 (Leads não atribuídos)
              _buildSpecialDockItem(
                title: 'Fila IA 24/7 (Omnichannel)',
                subtitle: unassignedCount > 0
                    ? '$unassignedCount novos aguardando'
                    : 'Sem pendências',
                count: unassignedCount,
                icon: LucideIcons.bot,
                iconColor: const Color(0xFFD97706),
                isSelected: _selectedSupervisorFilter == 'unassigned',
                isWarning: unassignedCount > 0,
                onTap: () => setState(() => _selectedSupervisorFilter = 'unassigned'),
                isDark: isDark,
                quickAction: unassignedCount > 0
                    ? Tooltip(
                        message: 'Distribuir leads da Fila IA em Round-Robin',
                        child: InkWell(
                          onTap: () => _distributeUnassignedRoundRobin(
                            allCards.where((c) =>
                                c.funcionarioResponsavelId == null ||
                                c.funcionarioResponsavelId!.isEmpty).toList(),
                            funcionarios,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.sparkles, size: 10, color: Colors.white),
                                SizedBox(width: 3),
                                Text(
                                  'Auto',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),

        const Divider(height: 12, thickness: 0.8),

        // Título da Seção de Atendentes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Row(
            children: [
              Text(
                'ATENDENTES (${filteredFuncionarios.length})',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                ),
              ),
              const Spacer(),
              Text(
                'Arraste leads para cá',
                style: TextStyle(
                  fontSize: 9,
                  color: colorScheme.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Lista Escalonável de Atendentes (DragTarget habilitado para remanejamento direto!)
        Expanded(
          child: filteredFuncionarios.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Nenhum atendente encontrado para o filtro aplicado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  itemCount: filteredFuncionarios.length,
                  itemBuilder: (context, index) {
                    final func = filteredFuncionarios[index];
                    final funcCards = allCards
                        .where((c) => c.funcionarioResponsavelId == func.id)
                        .toList();
                    final unreadCount = funcCards.fold<int>(
                        0, (sum, c) => sum + c.mensagensNaoLidas);
                    final isSelected = _selectedSupervisorFilter == func.id;

                    return _buildAttendantRadarCard(
                      context,
                      func: func,
                      cardCount: funcCards.length,
                      unreadCount: unreadCount,
                      isSelected: isSelected,
                      isDark: isDark,
                      colorScheme: colorScheme,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SIDEBAR COLAPSADA: MODO COMPACTO / ICON RAIL
  // ===========================================================================
  Widget _buildCollapsedSidebar(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    List<AtendimentoModel> allCards,
    List<FuncionarioModel> funcionarios,
    int unassignedCount,
  ) {
    return Column(
      children: [
        const SizedBox(height: 12),
        IconButton(
          icon: const Icon(LucideIcons.panelLeftOpen, size: 18),
          tooltip: 'Expandir Radar da Equipe',
          onPressed: () => setState(() => _isSidebarCollapsed = false),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 8),

        // Botão Visão Panorâmica
        Tooltip(
          message: 'Visão Panorâmica (${allCards.length})',
          child: InkWell(
            onTap: () => setState(() => _selectedSupervisorFilter = 'all'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _selectedSupervisorFilter == 'all'
                    ? colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.layoutGrid,
                size: 18,
                color: _selectedSupervisorFilter == 'all'
                    ? colorScheme.primary
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Botão Fila IA
        Tooltip(
          message: 'Fila IA 24/7 ($unassignedCount)',
          child: InkWell(
            onTap: () => setState(() => _selectedSupervisorFilter = 'unassigned'),
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedSupervisorFilter == 'unassigned'
                        ? const Color(0xFFFEF3C7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.bot,
                    size: 18,
                    color: const Color(0xFFD97706),
                  ),
                ),
                if (unassignedCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$unassignedCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
        const Divider(height: 1),

        // Avatares dos Atendentes com DragTarget
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: funcionarios.length,
            itemBuilder: (context, index) {
              final func = funcionarios[index];
              final count = allCards
                  .where((c) => c.funcionarioResponsavelId == func.id)
                  .length;
              final isSelected = _selectedSupervisorFilter == func.id;

              return DragTarget<AtendimentoModel>(
                onWillAcceptWithDetails: (details) =>
                    details.data.funcionarioResponsavelId != func.id,
                onAcceptWithDetails: (details) =>
                    _handleDragAndDropReassign(details.data, func),
                builder: (context, candidateData, rejectedData) {
                  final isHovered = candidateData.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Tooltip(
                      message: '${func.nome} ($count leads)',
                      child: InkWell(
                        onTap: () =>
                            setState(() => _selectedSupervisorFilter = func.id),
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isHovered
                                    ? const Color(0xFF10B981)
                                    : (isSelected
                                        ? colorScheme.primary
                                        : Colors.transparent),
                                width: isHovered || isSelected ? 2.0 : 0,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage: func.fotoUrl != null &&
                                      func.fotoUrl!.isNotEmpty
                                  ? NetworkImage(func.fotoUrl!)
                                  : null,
                              child: func.fotoUrl == null || func.fotoUrl!.isEmpty
                                  ? Text(
                                      func.nome.isNotEmpty
                                          ? func.nome[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MICRO-CARD DE ATENDENTE NO RADAR (Com Termômetro de Carga e DragTarget)
  // ===========================================================================
  Widget _buildAttendantRadarCard(
    BuildContext context, {
    required FuncionarioModel func,
    required int cardCount,
    required int unreadCount,
    required bool isSelected,
    required bool isDark,
    required ColorScheme colorScheme,
  }) {
    // Termômetro de Carga:
    // 0-4 = Ideal (Verde)
    // 5-9 = Moderada (Âmbar/Azul)
    // 10+ = Sobrecarga (Vermelho)
    Color gaugeColor;
    String gaugeLabel;
    double progressRatio;

    if (cardCount <= 4) {
      gaugeColor = const Color(0xFF10B981); // Emerald
      gaugeLabel = 'Disponível';
      progressRatio = (cardCount / 10).clamp(0.08, 1.0);
    } else if (cardCount <= 9) {
      gaugeColor = const Color(0xFFF59E0B); // Amber
      gaugeLabel = 'Carga Ideal';
      progressRatio = (cardCount / 10).clamp(0.1, 1.0);
    } else {
      gaugeColor = const Color(0xFFEF4444); // Red
      gaugeLabel = 'Sobrecarga';
      progressRatio = 1.0;
    }

    return DragTarget<AtendimentoModel>(
      onWillAcceptWithDetails: (details) {
        return details.data.funcionarioResponsavelId != func.id;
      },
      onAcceptWithDetails: (details) {
        _handleDragAndDropReassign(details.data, func);
      },
      builder: (context, candidateData, rejectedData) {
        final isDraggingOver = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: isDraggingOver
                ? const Color(0xFF10B981).withOpacity(0.12)
                : (isSelected
                    ? colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08)
                    : (isDark ? SigeColors.darkBg : const Color(0xFFF8FAFC))),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDraggingOver
                  ? const Color(0xFF10B981)
                  : (isSelected
                      ? colorScheme.primary
                      : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder)),
              width: isDraggingOver || isSelected ? 1.4 : 0.8,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() => _selectedSupervisorFilter = func.id);
              },
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar com Indicador Online
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundImage: func.fotoUrl != null &&
                                      func.fotoUrl!.isNotEmpty
                                  ? NetworkImage(func.fotoUrl!)
                                  : null,
                              child: func.fotoUrl == null || func.fotoUrl!.isEmpty
                                  ? Text(
                                      func.nome.isNotEmpty
                                          ? func.nome[0].toUpperCase()
                                          : 'U',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: func.ativo
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? SigeColors.darkSurface : Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 9),

                        // Nome & Cargo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                func.nome,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: isDark
                                      ? SigeColors.darkTextPrimary
                                      : SigeColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                func.cargo ?? 'Vendedor',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? SigeColors.darkTextSecondary
                                      : SigeColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Pill de Mensagens Não Lidas (se houver)
                        if (unreadCount > 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.messageSquare, size: 9, color: Colors.white),
                                const SizedBox(width: 3),
                                Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],

                        // Indicador de Seleção
                        if (isSelected)
                          Icon(LucideIcons.chevronRight, size: 14, color: colorScheme.primary),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Termômetro de Carga Visual
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progressRatio,
                              minHeight: 4,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.06)
                                  : Colors.black.withOpacity(0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$cardCount clientes',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: gaugeColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ITEM ESPECIAL NO DOCK (Visão Geral & Fila IA)
  // ===========================================================================
  Widget _buildSpecialDockItem({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool isWarning = false,
    Widget? quickAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? iconColor.withOpacity(isDark ? 0.16 : 0.08)
            : (isWarning && count > 0
                ? const Color(0xFFFEF3C7).withOpacity(isDark ? 0.1 : 0.6)
                : Colors.transparent),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? iconColor
              : (isWarning && count > 0
                  ? const Color(0xFFF59E0B).withOpacity(0.5)
                  : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder)),
          width: isSelected ? 1.4 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? SigeColors.darkTextPrimary : SigeColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (quickAction != null) ...[
                  quickAction,
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? iconColor : iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(
    String label,
    String key,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final isSelected = _teamWorkloadFilter == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _teamWorkloadFilter = key),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HUD EXECUTIVO DO ATENDENTE (TOPO DO VIEWPORT)
  // ===========================================================================
  Widget _buildExecutiveHud(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    FuncionarioModel? selectedFuncionario,
    String filter,
    List<AtendimentoModel> allCards,
    List<AtendimentoModel> unassignedCards,
    List<FuncionarioModel> funcionarios,
  ) {
    if (filter == 'all') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.layoutGrid, size: 20, color: colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visão Panorâmica de Toda a Equipe',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Exibindo todos os ${allCards.length} atendimentos consolidados entre ${funcionarios.length} atendentes cadastrados.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            _buildHudMetricChip('Atendentes Ativos', '${funcionarios.where((f) => f.ativo).length}', colorScheme.primary),
            const SizedBox(width: 10),
            _buildHudMetricChip('Pipeline Total', '${allCards.length}', colorScheme.secondary),
          ],
        ),
      );
    }

    if (filter == 'unassigned') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7).withOpacity(isDark ? 0.12 : 0.5),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFFF59E0B).withOpacity(0.4),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.bot, size: 20, color: Color(0xFFD97706)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fila IA 24/7 • Triagem Omnichannel (Não Atribuídos)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${unassignedCards.length} novos clientes aguardando distribuição para os atendentes da equipe.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (unassignedCards.isNotEmpty) ...[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(LucideIcons.sparkles, size: 15),
                label: const Text('Distribuir em Round-Robin', style: TextStyle(fontSize: 12)),
                onPressed: () => _distributeUnassignedRoundRobin(unassignedCards, funcionarios),
              ),
              const SizedBox(width: 10),
            ],
            TextButton.icon(
              icon: const Icon(LucideIcons.x, size: 14),
              label: const Text('Voltar à Visão Geral', style: TextStyle(fontSize: 12)),
              onPressed: () => setState(() => _selectedSupervisorFilter = 'all'),
            ),
          ],
        ),
      );
    }

    // ATENDENTE ESPECÍFICO INSPECIONADO
    final sellerCards = allCards
        .where((c) => c.funcionarioResponsavelId == selectedFuncionario?.id)
        .toList();
    final unreadTotal = sellerCards.fold<int>(0, (sum, c) => sum + c.mensagensNaoLidas);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          // Avatar do Atendente
          CircleAvatar(
            radius: 20,
            backgroundImage: selectedFuncionario?.fotoUrl != null &&
                    selectedFuncionario!.fotoUrl!.isNotEmpty
                ? NetworkImage(selectedFuncionario.fotoUrl!)
                : null,
            child: selectedFuncionario?.fotoUrl == null ||
                    selectedFuncionario!.fotoUrl!.isEmpty
                ? Text(
                    selectedFuncionario?.nome.isNotEmpty == true
                        ? selectedFuncionario!.nome[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Identificação do Atendente
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      selectedFuncionario?.nome ?? 'Atendente',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.radio, size: 10, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'Funil Ao Vivo',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                  '${selectedFuncionario?.cargo ?? "Vendedor Comercial"} • Você pode arrastar leads deste funil para outros atendentes na barra lateral.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Métricas Rápidas
          _buildHudMetricChip('Leads no Funil', '${sellerCards.length}', colorScheme.primary),
          const SizedBox(width: 8),
          _buildHudMetricChip('Mensagens Pendentes', '$unreadTotal', unreadTotal > 0 ? const Color(0xFF10B981) : Colors.grey),
          const SizedBox(width: 12),

          // Ações do Gerente
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(LucideIcons.arrowRightLeft, size: 14),
            label: const Text('Remanejar Carteira', style: TextStyle(fontSize: 12)),
            onPressed: () => _showBatchReassignDialog(
              context,
              selectedFuncionario!,
              sellerCards,
              funcionarios,
            ),
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(LucideIcons.x, size: 16),
            tooltip: 'Voltar à Visão Panorâmica',
            onPressed: () => setState(() => _selectedSupervisorFilter = 'all'),
          ),
        ],
      ),
    );
  }

  Widget _buildHudMetricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: color.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AÇÕES & DIÁLOGOS DE REMANEJAMENTO
  // ===========================================================================

  /// Transferência instantânea por Drag & Drop direto sobre o card do atendente no radar
  Future<void> _handleDragAndDropReassign(
    AtendimentoModel card,
    FuncionarioModel targetFunc,
  ) async {
    await ref
        .read(atendimentoProvider(widget.tenantId).notifier)
        .reassignCard(
          card.id,
          targetFunc.id,
          newFuncionarioNome: targetFunc.nome,
          motivo: 'Remanejado via Drag & Drop no Cockpit do Gerente',
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Atendimento de ${card.clienteNome} transferido com sucesso para ${targetFunc.nome}!',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Distribuição inteligente em Round-Robin (equilibra a equipe)
  Future<void> _distributeUnassignedRoundRobin(
    List<AtendimentoModel> unassignedCards,
    List<FuncionarioModel> funcionarios,
  ) async {
    final activeFuncionarios = funcionarios.where((f) => f.ativo).toList();

    if (activeFuncionarios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum atendente ativo disponível para receber leads')),
      );
      return;
    }

    if (unassignedCards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há leads pendentes na Fila IA')),
      );
      return;
    }

    int distributedCount = 0;
    for (int i = 0; i < unassignedCards.length; i++) {
      final card = unassignedCards[i];
      final targetFunc = activeFuncionarios[i % activeFuncionarios.length];

      await ref
          .read(atendimentoProvider(widget.tenantId).notifier)
          .reassignCard(
            card.id,
            targetFunc.id,
            newFuncionarioNome: targetFunc.nome,
            motivo: 'Distribuição Automática Round-Robin pelo Gerente',
          );
      distributedCount++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sucesso! $distributedCount leads foram distribuídos igualmente entre ${activeFuncionarios.length} atendentes.',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Diálogo de Remanejamento em Lote / Alívio de Sobrecarga
  void _showBatchReassignDialog(
    BuildContext context,
    FuncionarioModel currentFunc,
    List<AtendimentoModel> sellerCards,
    List<FuncionarioModel> allFuncionarios,
  ) {
    FuncionarioModel? selectedTarget;
    final otherFuncionarios = allFuncionarios
        .where((f) => f.ativo && f.id != currentFunc.id)
        .toList();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(LucideIcons.arrowRightLeft, size: 20),
                const SizedBox(width: 8),
                Text('Equilibrar Carteira: ${currentFunc.nome}'),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currentFunc.nome} possui atualmente ${sellerCards.length} atendimentos sob gestão.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Escolha o colega para quem deseja transferir os leads excedentes:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<FuncionarioModel>(
                    decoration: const InputDecoration(
                      labelText: 'Novo Responsável',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: otherFuncionarios.map((f) {
                      return DropdownMenuItem(
                        value: f,
                        child: Text('${f.nome} (${f.cargo ?? "Vendedor"})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedTarget = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: selectedTarget == null || sellerCards.isEmpty
                    ? null
                    : () async {
                        Navigator.of(dialogCtx).pop();
                        // Transfere os 3 leads mais antigos para aliviar
                        final toMove = sellerCards.take(3).toList();
                        for (final card in toMove) {
                          await ref
                              .read(atendimentoProvider(widget.tenantId).notifier)
                              .reassignCard(
                                card.id,
                                selectedTarget!.id,
                                newFuncionarioNome: selectedTarget!.nome,
                                motivo: 'Rebalanceamento de Carteira pelo Gerente',
                              );
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${toMove.length} atendimentos transferidos para ${selectedTarget!.nome}!',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                child: const Text('Transferir Excedente'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Diálogo Individual de Remanejamento
  void _showReassignDialog(
    BuildContext context,
    AtendimentoModel card,
    List<FuncionarioModel> funcionarios,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.arrowRightLeft, size: 20),
            SizedBox(width: 8),
            Text('Remanejar Atendimento'),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${card.clienteNome}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (card.titulo.isNotEmpty)
                Text(
                  card.titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      card.funcionarioResponsavelId != null
                          ? LucideIcons.userCheck
                          : LucideIcons.bot,
                      size: 14,
                      color: card.funcionarioResponsavelId != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.amber[800],
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Atribuído atualmente a: ${card.funcionarioResponsavelNome ?? (card.funcionarioResponsavelId != null ? "ID: ${card.funcionarioResponsavelId}" : "Fila do Bot IA")}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              const Text(
                'Selecione o novo atendente responsável:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // Devolver para o Bot IA
                    ListTile(
                      dense: true,
                      leading: const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFFEF3C7),
                        child: Icon(LucideIcons.bot, size: 16, color: Color(0xFFB45309)),
                      ),
                      title: const Text('Fila do Bot IA (Não Atribuído)'),
                      subtitle: const Text('Devolve o lead para a fila omnichannel geral'),
                      onTap: () async {
                        Navigator.of(dialogCtx).pop();
                        await ref
                            .read(atendimentoProvider(widget.tenantId).notifier)
                            .reassignCard(
                              card.id,
                              null,
                              newFuncionarioNome: null,
                              motivo: 'Devolvido para a fila geral do Bot IA',
                            );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Atendimento enviado para a Fila IA!'),
                              backgroundColor: Color(0xFFD97706),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    // Lista de Vendedores Ativos
                    ...funcionarios.where((f) => f.ativo).map((func) {
                      final isCurrent = card.funcionarioResponsavelId == func.id;
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              func.fotoUrl != null && func.fotoUrl!.isNotEmpty
                                  ? NetworkImage(func.fotoUrl!)
                                  : null,
                          child: func.fotoUrl == null || func.fotoUrl!.isEmpty
                              ? Text(func.nome.isNotEmpty
                                  ? func.nome[0].toUpperCase()
                                  : 'U')
                              : null,
                        ),
                        title: Text(
                          func.nome,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          func.cargo ?? func.email ?? 'Atendente Comercial',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: isCurrent
                            ? const Chip(
                                label: Text('Atual', style: TextStyle(fontSize: 10)),
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                        onTap: isCurrent
                            ? null
                            : () async {
                                Navigator.of(dialogCtx).pop();
                                await ref
                                    .read(atendimentoProvider(widget.tenantId).notifier)
                                    .reassignCard(
                                      card.id,
                                      func.id,
                                      newFuncionarioNome: func.nome,
                                      motivo: 'Remanejado pelo Gerente',
                                    );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Atendimento transferido para ${func.nome}!'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

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
            'Defina as fases da jornada de atendimento para a sua equipe.',
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
            content: Text('Crie uma coluna primeiro antes de adicionar atendimentos')),
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
          // Se houver um vendedor selecionado, já atribui a ele! Caso contrário, vai pra Fila IA
          final assignedFuncId = (_selectedSupervisorFilter != 'all' &&
                  _selectedSupervisorFilter != 'unassigned')
              ? _selectedSupervisorFilter
              : null;

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
            funcionarioResponsavelId: assignedFuncId,
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

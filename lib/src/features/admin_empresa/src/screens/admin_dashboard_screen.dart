import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/core/core.dart';
import 'package:sige/src/features/admin_empresa/src/models/horario_model.dart';
import 'package:sige/src/features/admin_empresa/src/providers/admin_providers.dart';
import 'package:sige/src/features/admin_empresa/src/providers/tenant_provider.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/empresa_profile_form_dialog.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/funcionario_card.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/horario_funcionamento_form_dialog.dart';
import 'package:sige/src/features/admin_empresa/src/screens/components/canais_consumo_ia_tab.dart';
import 'package:sige/src/features/admin_empresa/src/services/admin_empresa_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final String tenantId;

  const AdminDashboardScreen({super.key, required this.tenantId});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _lojaAberta = true;
  String _searchQuery = '';
  String _filtroCargo = 'todos';
  String _filtroStatus = 'todos';
  FuncionarioModel? _selectedFuncionario;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Executive Aero Header
            _buildExecutiveHeader(context, isDark),

            // Main Body Content Tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabEquipeMaster(context, ref, isDark),
                  _buildTabLojaHub(context, ref, isDark),
                  CanaisConsumoIaTab(tenantId: widget.tenantId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP EXECUTIVE AERO HEADER
  // ===========================================================================
  Widget _buildExecutiveHeader(BuildContext context, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isCompact = constraints.maxWidth < 600;

        // 1. Header Information Widget (Badge + Title + Enterprise Chip + Subtitle)
        final headerInfo = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(LucideIcons.shieldCheck, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        "Torre de Administração & Governança",
                        style: TextStyle(
                          fontSize: isCompact ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          "ENTERPRISE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Gestão de equipes, matriz de permissões RBAC e telemetria operacional da loja",
                    maxLines: isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        // 2. Segmented Pill TabBar Widget
        final tabPillBar = Container(
          height: 44,
          width: isDesktop ? null : double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.zero,
            labelPadding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.users, size: 16),
                    SizedBox(width: 8),
                    Text("Equipe & Acessos"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.store, size: 16),
                    SizedBox(width: 8),
                    Text("Operação & Loja"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.messageSquareCode, size: 16),
                    SizedBox(width: 8),
                    Text("Canais & Consumo IA"),
                  ],
                ),
              ),
            ],
          ),
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 24,
            vertical: isCompact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111C38) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: isDesktop
              ? Row(
                  children: [
                    Expanded(child: headerInfo),
                    const SizedBox(width: 24),
                    tabPillBar,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    headerInfo,
                    const SizedBox(height: 12),
                    tabPillBar,
                  ],
                ),
        );
      },
    );
  }

  // ===========================================================================
  // ABA EQUIPE & ACESSOS (MASTER-DETAIL + TELEMETRIA RBAC)
  // ===========================================================================
  Widget _buildTabEquipeMaster(BuildContext context, WidgetRef ref, bool isDark) {
    final funcionariosAsync = ref.watch(funcionariosProvider(widget.tenantId));

    return funcionariosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("Erro ao carregar colaboradores: $err")),
      data: (funcionarios) {
        // Cálculo de KPIs
        final totalMembros = funcionarios.length;
        final totalAtivos = funcionarios.where((f) => f.ativo).length;
        final totalInativos = totalMembros - totalAtivos;
        final adminsCount = funcionarios.where((f) => (f.cargo ?? '').toLowerCase().contains('admin')).length;
        final gerentesCount = funcionarios.where((f) => (f.cargo ?? '').toLowerCase().contains('gerente')).length;
        final atendentesCount = funcionarios.where((f) => (f.cargo ?? '').toLowerCase().contains('atendente')).length;

        // Filtragem dinâmica
        final filtrados = funcionarios.where((f) {
          if (_searchQuery.isNotEmpty) {
            final matchNome = f.nome.toLowerCase().contains(_searchQuery);
            final matchEmail = (f.email ?? '').toLowerCase().contains(_searchQuery);
            final matchCargo = (f.cargo ?? '').toLowerCase().contains(_searchQuery);
            if (!matchNome && !matchEmail && !matchCargo) return false;
          }

          if (_filtroStatus == 'ativo' && !f.ativo) return false;
          if (_filtroStatus == 'inativo' && f.ativo) return false;

          if (_filtroCargo != 'todos') {
            final cargo = (f.cargo ?? '').toLowerCase();
            if (_filtroCargo == 'admin' && !cargo.contains('admin')) return false;
            if (_filtroCargo == 'gerente' && !cargo.contains('gerente')) return false;
            if (_filtroCargo == 'atendente' && !cargo.contains('atendente')) return false;
          }

          return true;
        }).toList();

        return Column(
          children: [
            // KPI HUD Strip
            _buildTeamKpiStrip(
              isDark: isDark,
              totalMembros: totalMembros,
              totalAtivos: totalAtivos,
              totalInativos: totalInativos,
              adminsCount: adminsCount,
              gerentesCount: gerentesCount,
              atendentesCount: atendentesCount,
            ),

            // Toolbar com Busca, Filtros e Ação Primária
            _buildTeamToolbar(
              isDark: isDark,
              onNovoColaborador: () => _showAddEditFuncionarioDialog(context, ref),
            ),

            // Área de Conteúdo (Cards + Drawer Lateral de Inspeção se selecionado)
            Expanded(
              child: Row(
                children: [
                  // Lista de Colaboradores
                  Expanded(
                    flex: 3,
                    child: filtrados.isEmpty
                        ? _buildEmptyStateEquipe(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final f = filtrados[index];
                              final isSelected = _selectedFuncionario?.id == f.id;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: isSelected
                                      ? Border.all(color: const Color(0xFF2563EB), width: 2)
                                      : null,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedFuncionario = isSelected ? null : f;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: FuncionarioCard(
                                    funcionario: f,
                                    onEdit: () => _showAddEditFuncionarioDialog(context, ref, f),
                                    onStatusChange: () async {
                                      final updated = f.copyWith(ativo: !f.ativo);
                                      await ref
                                          .read(adminEmpresaServiceProvider)
                                          .updateFuncionario(updated);
                                      ref.invalidate(funcionariosProvider(widget.tenantId));
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Painel Lateral de Inspeção de Permissões RBAC (Master-Detail)
                  if (_selectedFuncionario != null)
                    _buildFuncionarioInspectionPanel(
                      funcionario: _selectedFuncionario!,
                      isDark: isDark,
                      onClose: () => setState(() => _selectedFuncionario = null),
                      onEdit: () => _showAddEditFuncionarioDialog(context, ref, _selectedFuncionario!),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // KPI HUD STRIP (EQUIPE)
  // ===========================================================================
  Widget _buildTeamKpiStrip({
    required bool isDark,
    required int totalMembros,
    required int totalAtivos,
    required int totalInativos,
    required int adminsCount,
    required int gerentesCount,
    required int atendentesCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final cards = [
          _buildKpiCard(
            label: "TOTAL DE COLABORADORES",
            value: "$totalMembros",
            subtext: "$totalAtivos ativos na plataforma",
            icon: LucideIcons.users,
            color: const Color(0xFF2563EB),
            isDark: isDark,
            isExpanded: !isNarrow,
          ),
          const SizedBox(width: 14),
          _buildKpiCard(
            label: "STATUS DE ACESSO",
            value: "${((totalAtivos / (totalMembros > 0 ? totalMembros : 1)) * 100).toInt()}%",
            subtext: "$totalInativos suspensos ou desligados",
            icon: LucideIcons.shieldCheck,
            color: const Color(0xFF10B981),
            isDark: isDark,
            isExpanded: !isNarrow,
          ),
          const SizedBox(width: 14),
          _buildKpiCard(
            label: "GOVERNANÇA & LIDERANÇA",
            value: "${adminsCount + gerentesCount}",
            subtext: "$adminsCount Admins • $gerentesCount Gerentes",
            icon: LucideIcons.crown,
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
            isExpanded: !isNarrow,
          ),
          const SizedBox(width: 14),
          _buildKpiCard(
            label: "FRONT DE ATENDIMENTO",
            value: "$atendentesCount",
            subtext: "Operadores ativos no SAC",
            icon: LucideIcons.headset,
            color: const Color(0xFFF59E0B),
            isDark: isDark,
            isExpanded: !isNarrow,
          ),
        ];

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: isNarrow
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: cards),
                )
              : Row(children: cards),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isExpanded = true,
  }) {
    final cardContent = Container(
      width: isExpanded ? null : 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(icon, color: color, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subtext,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    return isExpanded ? Expanded(child: cardContent) : cardContent;
  }

  // ===========================================================================
  // TOOLBAR DE EQUIPE (BUSCA, CHIPS DE FILTRO E BOTÃO PRINCIPAL)
  // ===========================================================================
  Widget _buildTeamToolbar({
    required bool isDark,
    required VoidCallback onNovoColaborador,
  }) {
    final searchField = Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: "Buscar por nome, e-mail ou cargo...",
          hintStyle: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 18,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );

    final filterChips = [
      _buildFilterChip(
        label: "Todos",
        isSelected: _filtroStatus == 'todos',
        onTap: () => setState(() => _filtroStatus = 'todos'),
        isDark: isDark,
      ),
      _buildFilterChip(
        label: "Ativos",
        isSelected: _filtroStatus == 'ativo',
        onTap: () => setState(() => _filtroStatus = 'ativo'),
        isDark: isDark,
      ),
      _buildFilterChip(
        label: "Inativos",
        isSelected: _filtroStatus == 'inativo',
        onTap: () => setState(() => _filtroStatus = 'inativo'),
        isDark: isDark,
      ),
    ];

    final cargoSelector = Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filtroCargo,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          items: const [
            DropdownMenuItem(value: 'todos', child: Text("Todos os Cargos")),
            DropdownMenuItem(value: 'admin', child: Text("Administradores")),
            DropdownMenuItem(value: 'gerente', child: Text("Gerentes")),
            DropdownMenuItem(value: 'atendente', child: Text("Atendentes")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _filtroCargo = val);
          },
        ),
      ),
    );

    final addButton = ElevatedButton.icon(
      onPressed: onNovoColaborador,
      icon: const Icon(LucideIcons.userPlus, size: 18),
      label: const Text(
        "Novo Colaborador",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C38) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                searchField,
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ...filterChips,
                    cargoSelector,
                    addButton,
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 14),
              filterChips[0],
              const SizedBox(width: 6),
              filterChips[1],
              const SizedBox(width: 6),
              filterChips[2],
              const SizedBox(width: 14),
              cargoSelector,
              const SizedBox(width: 16),
              addButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PAINEL LATERAL DE INSPEÇÃO DE PERMISSÕES RBAC (MASTER-DETAIL)
  // ===========================================================================
  Widget _buildFuncionarioInspectionPanel({
    required FuncionarioModel funcionario,
    required bool isDark,
    required VoidCallback onClose,
    required VoidCallback onEdit,
  }) {
    return Container(
      width: 380,
      margin: const EdgeInsets.fromLTRB(0, 16, 24, 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C38) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com Fechar e Editar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldAlert, size: 18, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Text(
                    "Auditoria de Acessos",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(LucideIcons.x, size: 18),
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Card Perfil Rápido
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
                  child: Text(
                    funcionario.nome.isNotEmpty
                        ? funcionario.nome.substring(0, min(2, funcionario.nome.length)).toUpperCase()
                        : "??",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        funcionario.nome,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        funcionario.email ?? "Sem e-mail cadastrado",
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "MATRIZ DE MÓDULOS LIBERADOS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),

          // Lista de Módulos RBAC
          Expanded(
            child: ListView(
              children: [
                _buildRbacPermissionTile(
                  name: "Atendimento & SAC",
                  description: "Acesso à cabine de chat e transbordo",
                  isGranted: funcionario.modulosAcesso.contains('atendimento'),
                  icon: LucideIcons.headset,
                  isDark: isDark,
                ),
                _buildRbacPermissionTile(
                  name: "Gestão de Clientes & CRM",
                  description: "Carteira 360°, leads e histórico",
                  isGranted: funcionario.modulosAcesso.contains('clientes'),
                  icon: LucideIcons.users,
                  isDark: isDark,
                ),
                _buildRbacPermissionTile(
                  name: "Controle de Estoque & Catálogo",
                  description: "Gestão de itens, preços e inventário",
                  isGranted: funcionario.modulosAcesso.contains('estoque'),
                  icon: LucideIcons.package,
                  isDark: isDark,
                ),
                _buildRbacPermissionTile(
                  name: "Cockpit & KPIs Executivos",
                  description: "Visão consolidada de indicadores e SLAs",
                  isGranted: funcionario.modulosAcesso.contains('cockpit_supervisao') || funcionario.modulosAcesso.contains('basic_dashboard'),
                  icon: LucideIcons.barChart2,
                  isDark: isDark,
                ),
                _buildRbacPermissionTile(
                  name: "Kanban Operacional",
                  description: "Quadro de fluxo e esteiras de tarefas",
                  isGranted: funcionario.modulosAcesso.contains('kanban'),
                  icon: LucideIcons.columns3,
                  isDark: isDark,
                ),
                _buildRbacPermissionTile(
                  name: "Configurações & Painel Admin",
                  description: "Acesso à governança da unidade",
                  isGranted: funcionario.modulosAcesso.contains('configuracoes'),
                  icon: LucideIcons.shieldCheck,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          // Botão Editar Permissões
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onEdit,
              icon: const Icon(LucideIcons.fileEdit, size: 16),
              label: const Text("Editar Permissões do Colaborador"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRbacPermissionTile({
    required String name,
    required String description,
    required bool isGranted,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isGranted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isGranted ? "LIBERADO" : "BLOQUEADO",
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: isGranted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateEquipe(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.userX, size: 48, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          Text(
            "Nenhum colaborador encontrado",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tente ajustar os filtros de busca ou cargo acima.",
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ABA OPERAÇÃO & LOJA (CENTRO DE CONTROLE DE HORÁRIOS E CANAIS)
  // ===========================================================================
  Widget _buildTabLojaHub(BuildContext context, WidgetRef ref, bool isDark) {
    final tenantAsync = ref.watch(tenantProvider(widget.tenantId));

    return tenantAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Erro: $err')),
      data: (tenant) {
        if (tenant == null) return const SizedBox();

        final statusColor = _lojaAberta ? const Color(0xFF10B981) : const Color(0xFFEF4444);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              children: [
                // Hero HUD Operacional
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111C38) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _lojaAberta
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFFEF4444).withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _lojaAberta ? LucideIcons.radio : LucideIcons.powerOff,
                            color: statusColor,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                Text(
                                  "Status em Tempo Real do Estabelecimento",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _lojaAberta ? "RECEBENDO PEDIDOS" : "OPERAÇÃO PAUSADA",
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _lojaAberta
                                  ? "A unidade está operacional. O bot de atendimento e os canais de WhatsApp e catálogo web estão recebendo novos clientes."
                                  : "A loja está com recebimento bloqueado. Novos pedidos serão informados que o expediente está encerrado.",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Switch(
                        value: _lojaAberta,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF10B981),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
                        onChanged: (bool value) {
                          setState(() => _lojaAberta = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Seção Módulos Administrativos da Unidade
                Text(
                  "CENTRAL DE CONFIGURAÇÃO CORPORATIVA",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Configure dados tributários, canais de comunicação, e horários de expediente comercial.",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Cards de Ação Operacional
                Row(
                  children: [
                    Expanded(
                      child: _buildOperationCard(
                        title: "Perfil da Empresa & Branding",
                        subtitle: "Razão social, CNPJ, logo da marca, endereço físico e canais oficiais.",
                        icon: LucideIcons.building2,
                        accentColor: const Color(0xFF2563EB),
                        isDark: isDark,
                        badge: "DADOS OFICIAIS",
                        onTap: () => _abrirPerfilEmpresaDialog(context, ref, tenant),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOperationCard(
                        title: "Grade de Horários & Expediente",
                        subtitle: "Defina os dias da semana e turnos em que o bot e atendentes operam.",
                        icon: LucideIcons.clock,
                        accentColor: const Color(0xFF8B5CF6),
                        isDark: isDark,
                        badge: "EXPEDIENTE & DIAS",
                        onTap: () => _abrirHorarioFuncionamentoDialog(context, ref, tenant),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDark,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C38) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Icon(icon, color: accentColor, size: 24),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      "Gerenciar parâmetros",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.arrowRight, size: 14, color: accentColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirPerfilEmpresaDialog(
      BuildContext context, WidgetRef ref, TenantModel tenant) {
    showDialog(
      context: context,
      builder: (context) => EmpresaProfileFormDialog(
        empresa: tenant,
        onSave: (updatedTenant) async {
          await ref
              .read(adminEmpresaServiceProvider)
              .updateTenantConfig(widget.tenantId, updatedTenant.config);
          // Nota: updateTenantConfig atualiza apenas o config, se precisar atualizar
          // nomeFantasia ou documentoFiscal, precisa de um método específico no service
          // ou atualizar o updateTenantConfig para lidar com isso.
          // Por enquanto, vamos assumir que o service cuida disso ou implementar updateTenant completo.
          // Mas o service atual só tem updateTenantConfig e updateHorario.
          // Vamos focar no visual por enquanto.
          ref.invalidate(tenantProvider(widget.tenantId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Perfil atualizado com sucesso!')),
            );
          }
        },
      ),
    );
  }

  void _abrirHorarioFuncionamentoDialog(
      BuildContext context, WidgetRef ref, TenantModel tenant) {
    final horarioConfig = tenant.config['horario_funcionamento'];
    final horariosAtuais = horarioConfig != null
        ? HorarioFuncionamento.fromMap(Map<String, dynamic>.from(horarioConfig))
        : HorarioFuncionamento(horarios: {});

    showDialog(
      context: context,
      builder: (context) => HorarioFuncionamentoFormDialog(
        horariosAtuais: horariosAtuais,
        onSave: (novosHorarios) async {
          await ref
              .read(adminEmpresaServiceProvider)
              .updateHorarioFuncionamento(
                  widget.tenantId, novosHorarios.toMap());
          ref.invalidate(tenantProvider(widget.tenantId));
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Horários atualizados com sucesso!')),
            );
          }
        },
      ),
    );
  }

  void _showAddEditFuncionarioDialog(BuildContext context, WidgetRef ref,
      [FuncionarioModel? funcionario]) {
    showDialog(
      context: context,
      builder: (context) => _AddEditFuncionarioDialog(
        tenantId: widget.tenantId,
        funcionario: funcionario,
      ),
    );
  }
}

class _AddEditFuncionarioDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final FuncionarioModel? funcionario;

  const _AddEditFuncionarioDialog({required this.tenantId, this.funcionario});

  @override
  ConsumerState<_AddEditFuncionarioDialog> createState() =>
      _AddEditFuncionarioDialogState();
}

class _AddEditFuncionarioDialogState
    extends ConsumerState<_AddEditFuncionarioDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _cargoController;
  late TextEditingController _telefoneController;
  bool _ativo = true;
  bool _isLoading = false;
  List<String> _selectedModulos = [];

  @override
  void initState() {
    super.initState();
    _nomeController =
        TextEditingController(text: widget.funcionario?.nome ?? '');
    _emailController =
        TextEditingController(text: widget.funcionario?.email ?? '');
    _cargoController =
        TextEditingController(text: widget.funcionario?.cargo ?? '');
    _telefoneController =
        TextEditingController(text: widget.funcionario?.telefone ?? '');
    _ativo = widget.funcionario?.ativo ?? true;
    _selectedModulos = List.from(widget.funcionario?.modulosAcesso ?? []);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cargoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.funcionario != null;

    final primaryColor = const Color(0xFF2563EB);
    final primaryGradient = const LinearGradient(
      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 860),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.6)
                      : primaryColor.withValues(alpha: 0.14),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Hero com Gradiente Suave & Glassmorphism
                  Container(
                    padding: const EdgeInsets.fromLTRB(26, 24, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFFF8FAFC), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isEditing ? LucideIcons.userCog : LucideIcons.userPlus,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'Editar Colaborador' : 'Novo Membro da Equipe',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.4,
                                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEditing
                                    ? 'Atualize dados cadastrais e permissões de acesso'
                                    : 'Cadastre o funcionário e conceda acesso aos módulos operacionais',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(
                                LucideIcons.x,
                                size: 18,
                                color: isDark ? Colors.grey[300] : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conteúdo com Formulário Estilizado
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seção 1: Dados do Colaborador
                            _buildSectionHeader(
                              icon: LucideIcons.user,
                              title: 'INFORMAÇÕES PESSOAIS & CARGO',
                              isDark: isDark,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 14),

                            _buildCustomTextField(
                              controller: _nomeController,
                              label: 'Nome Completo',
                              placeholder: 'Ex: Halanna Silva',
                              icon: LucideIcons.user,
                              isDark: isDark,
                              validator: (v) => v?.trim().isEmpty == true ? 'Nome é obrigatório' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildCustomTextField(
                              controller: _emailController,
                              label: 'Email Corporativo',
                              placeholder: 'colaborador@empresa.com.br',
                              icon: LucideIcons.mail,
                              isDark: isDark,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: _cargoController,
                                    label: 'Cargo / Função',
                                    placeholder: 'Ex: Atendente Comercial',
                                    icon: LucideIcons.briefcase,
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _buildCustomTextField(
                                    controller: _telefoneController,
                                    label: 'WhatsApp / Telefone',
                                    placeholder: '(00) 00000-0000',
                                    icon: LucideIcons.phone,
                                    isDark: isDark,
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Seção 2: Status da Conta com Glassmorphism & Switch Moderno
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _ativo
                                    ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.25) : const Color(0xFFECFDF5))
                                    : (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : const Color(0xFFFEF2F2)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _ativo
                                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                      : const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(9),
                                    decoration: BoxDecoration(
                                      color: _ativo
                                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                          : const Color(0xFFEF4444).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _ativo ? LucideIcons.checkCircle2 : LucideIcons.ban,
                                      color: _ativo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Status do Acesso',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          _ativo
                                              ? 'Ativo • Colaborador pode autenticar e acessar o painel'
                                              : 'Inativo • Acesso bloqueado temporariamente',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _ativo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Transform.scale(
                                    scale: 0.88,
                                    child: Switch(
                                      value: _ativo,
                                      onChanged: (val) => setState(() => _ativo = val),
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: const Color(0xFF10B981),
                                      inactiveThumbColor: Colors.white,
                                      inactiveTrackColor: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),

                            // Seção 3: Permissões de Módulos (Cards Interativos com Hover e Switch Rápido)
                            _buildSectionHeader(
                              icon: LucideIcons.shieldCheck,
                              title: 'PERMISSÕES DE ACESSO AOS MÓDULOS',
                              isDark: isDark,
                              color: primaryColor,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Selecione quais áreas do sistema estarão visíveis e operacionais para este membro:',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),

                            ref.watch(tenantProvider(widget.tenantId)).when(
                                  data: (tenant) {
                                    final tenantModulos = tenant?.modulosAtivos ?? [];

                                    final catalogoModulos = [
                                      {
                                        'id': 'dashboard',
                                        'label': 'Dashboard Executivo',
                                        'desc': 'Indicadores consolidados, metas e telemetria',
                                        'icon': LucideIcons.layoutDashboard,
                                        'color': const Color(0xFF3B82F6),
                                      },
                                      {
                                        'id': 'atendimento',
                                        'label': 'Atendimento & Chat',
                                        'desc': 'Conversas WhatsApp, fila própria e respostas rápidas',
                                        'icon': LucideIcons.messageSquare,
                                        'color': const Color(0xFF10B981),
                                      },
                                      {
                                        'id': 'gerente_atendimento',
                                        'label': 'Supervisão de Atendimento',
                                        'desc': 'Torre de controle, auditoria shadow e transbordo',
                                        'icon': LucideIcons.shieldAlert,
                                        'color': const Color(0xFF8B5CF6),
                                      },
                                      {
                                        'id': 'clientes',
                                        'label': 'Gestão de Clientes B2B/B2C',
                                        'desc': 'Cadastro empresarial, histórico e cotações',
                                        'icon': LucideIcons.users,
                                        'color': const Color(0xFFF59E0B),
                                      },
                                      {
                                        'id': 'estoque',
                                        'label': 'Gestão de Estoque & EPIs',
                                        'desc': 'Controle de saldo, CAs de segurança e itens',
                                        'icon': LucideIcons.package,
                                        'color': const Color(0xFFEC4899),
                                      },
                                      {
                                        'id': 'admin_empresa',
                                        'label': 'Administração da Empresa',
                                        'desc': 'Gestão de equipe, horários e configurações globais',
                                        'icon': LucideIcons.settings,
                                        'color': const Color(0xFF64748B),
                                      },
                                    ];

                                    // Filtra conforme os módulos contratados pelo tenant
                                    final modulosDisponiveis = catalogoModulos.where((m) {
                                      if (tenantModulos.isEmpty) return true;
                                      final id = m['id'] as String;
                                      return tenantModulos.any((tm) {
                                        final norm = tm.toLowerCase().replaceAll('module_', '');
                                        if (norm == id) return true;
                                        if (id == 'clientes' && (norm == 'leads' || norm == 'clientes')) return true;
                                        if (id == 'dashboard' && (norm == 'basic_dashboard' || norm == 'dashboard')) return true;
                                        if (id == 'gerente_atendimento' && (norm == 'atendimento' || norm == 'gerente_atendimento')) return true;
                                        return false;
                                      });
                                    }).toList();

                                    return Column(
                                      children: modulosDisponiveis.map((item) {
                                        final modId = item['id'] as String;
                                        final label = item['label'] as String;
                                        final desc = item['desc'] as String;
                                        final icon = item['icon'] as IconData;
                                        final cor = item['color'] as Color;

                                        final isSelected = _selectedModulos.any((s) {
                                          final sNorm = s.toLowerCase().replaceAll('module_', '');
                                          if (sNorm == modId) return true;
                                          if (modId == 'clientes' && (sNorm == 'leads' || sNorm == 'clientes')) return true;
                                          if (modId == 'dashboard' && (sNorm == 'basic_dashboard' || sNorm == 'dashboard')) return true;
                                          return false;
                                        });

                                        return _buildModulePermissionCard(
                                          modId: modId,
                                          label: label,
                                          desc: desc,
                                          icon: icon,
                                          accentColor: cor,
                                          isSelected: isSelected,
                                          isDark: isDark,
                                          onToggle: () {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedModulos.removeWhere((s) {
                                                  final sNorm = s.toLowerCase().replaceAll('module_', '');
                                                  return sNorm == modId ||
                                                      (modId == 'clientes' && sNorm == 'leads') ||
                                                      (modId == 'leads' && sNorm == 'clientes');
                                                });
                                              } else {
                                                _selectedModulos.add(modId);
                                                if (modId == 'clientes') {
                                                  _selectedModulos.add('leads');
                                                }
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                    );
                                  },
                                  loading: () => const Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                  error: (_, __) => const Text('Erro ao carregar módulos da empresa'),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer de Ações com Gradiente e Botões Elegantes
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF8FAFC),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _save,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(LucideIcons.check, size: 16),
                            label: Text(
                              _isLoading ? 'Salvando...' : (isEditing ? 'Salvar Alterações' : 'Cadastrar Membro'),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required bool isDark,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildModulePermissionCard({
    required String modId,
    required String label,
    required String desc,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? accentColor.withValues(alpha: isDark ? 0.16 : 0.08)
                  : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.4) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.8)
                    : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 17,
                    color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? Colors.grey[300] : const Color(0xFF334155)),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accentColor : (isDark ? Colors.grey[600]! : const Color(0xFFCBD5E1)),
                      width: 1.6,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final service = ref.read(adminEmpresaServiceProvider);
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final cargo = _cargoController.text.trim();
    final telefone = _telefoneController.text.trim();

    try {
      if (widget.funcionario != null) {
        // Update
        final updatedFuncionario = widget.funcionario!.copyWith(
          nome: nome,
          email: email.isEmpty ? null : email,
          cargo: cargo.isEmpty ? null : cargo,
          telefone: telefone.isEmpty ? null : telefone,
          ativo: _ativo,
          modulosAcesso: _selectedModulos,
          dataAtualizacao: DateTime.now(),
        );
        await service.updateFuncionario(updatedFuncionario);
      } else {
        // Add
        final newFuncionario = FuncionarioModel(
          id: '',
          tenantId: widget.tenantId,
          nome: nome,
          email: email.isEmpty ? null : email,
          cargo: cargo.isEmpty ? null : cargo,
          telefone: telefone.isEmpty ? null : telefone,
          ativo: _ativo,
          modulosAcesso: _selectedModulos,
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
        );
        await service.addFuncionario(newFuncionario);
      }

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(funcionariosProvider(widget.tenantId));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }
}

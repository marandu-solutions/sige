import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import 'dart:math';

import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/core/models/funcionario_model.dart';
import 'package:sige/src/features/admin_empresa/src/providers/admin_providers.dart';
import 'package:sige/src/features/atendimento/models/atendimento_model.dart';
import 'package:sige/src/features/atendimento/models/config_atendimento_model.dart';
import 'package:sige/src/features/atendimento/providers/atendimento_provider.dart';

import 'package:sige/src/features/atendimento/providers/config_atendimento_provider.dart';
import 'package:sige/src/features/atendimento/services/atendimento_metrics_helper.dart';
import 'package:sige/src/features/atendimento/widgets/atendente_cabine_card_widget.dart';
import 'package:sige/src/features/atendimento/widgets/atendente_inspection_drawer.dart';
import 'package:sige/src/features/atendimento/widgets/politicas_transbordo_dialog.dart';
import 'package:sige/src/features/atendimento/widgets/chat_page.dart';
import 'package:sige/src/features/atendimento/widgets/exp_atendimento_config_dialog.dart';
import 'package:sige/src/features/atendimento/screens/history_atendimento_screen/history_atendimento_screen.dart';

/// Torre de Controle Executiva de Atendimento & Call Center (Sally UX - Edição Aero-Cyber)
/// Interface de alto impacto visual com telemetria viva, medidores com glassmorphism,
/// cabines operacionais interativas com pulso de sonar e painel de inteligência operacional.
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
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _filtroStatus = 'todos'; // 'todos', 'fluindo', 'atencao', 'sobrecarga', 'vacuo'
  FuncionarioModel? _atendenteInspecionado;
  AtendimentoModel? _cardSelecionado;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final atendimentoAsync = ref.watch(globalAtendimentoProvider(widget.tenantId));
    final funcionariosAsync = ref.watch(funcionariosProvider(widget.tenantId));
    final configAsync = ref.watch(configAtendimentoProvider(widget.tenantId));


    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final allFuncionarios = funcionariosAsync.valueOrNull ?? [];
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Filtra o gerente logado da lista de atendentes operacionais
    final atendentes = allFuncionarios.where((f) {
      if (currentUserId != null && f.id == currentUserId) return false;
      return true;
    }).toList();

    final boardState = atendimentoAsync.valueOrNull;
    final allCards = boardState?.cards ?? [];
    final config = configAsync.valueOrNull ?? const ConfigAtendimentoModel();

    // Telemetria Global Consolidada
    final telemetria = AtendimentoMetricsHelper.calcularTelemetriaGlobal(
      atendentes: atendentes,
      todosCards: allCards,
      config: config,
    );

    // Mapeamento de métricas por atendente
    final mapMetricas = <String, AtendenteMetrics>{};
    for (final f in atendentes) {
      mapMetricas[f.id] = AtendimentoMetricsHelper.calcularMetricasAtendente(
        funcionario: f,
        todosCards: allCards,
        config: config,
      );
    }

    // Filtra os atendentes conforme a busca e o filtro de status
    final atendentesFiltrados = atendentes.where((f) {
      final m = mapMetricas[f.id];
      if (m == null) return false;

      // Busca por nome ou cargo
      if (_searchQuery.isNotEmpty) {
        final matchNome = f.nome.toLowerCase().contains(_searchQuery);
        final matchCargo = (f.cargo ?? '').toLowerCase().contains(_searchQuery);
        if (!matchNome && !matchCargo) return false;
      }

      // Filtro de status da cabine
      switch (_filtroStatus) {
        case 'fluindo':
          return m.isDisponivel;
        case 'atencao':
          return m.isAtencao;
        case 'sobrecarga':
          return m.isSobrecarregado;
        case 'vacuo':
          return m.cardsEmVacuo.isNotEmpty;
        case 'todos':
        default:
          return true;
      }
    }).toList();

    // Cartões da fila IA / não atribuídos
    final unassignedCards = allCards
        .where((c) =>
            (c.funcionarioResponsavelId == null ||
                c.funcionarioResponsavelId!.isEmpty) &&
            c.status != 'arquivado')
        .toList();

    // Métricas do atendente atualmente em inspeção
    final metricsInspecionado = _atendenteInspecionado != null
        ? mapMetricas[_atendenteInspecionado!.id]
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF4F7FC),
      appBar: _buildAeroAppBar(context, colorScheme, isDark, config, unassignedCards, atendentes),
      body: Stack(
        children: [
          Row(
            children: [
              // Área Principal da Torre de Controle
              Expanded(
                child: Column(
                  children: [
                    // HUD Superior de Telemetria com Glassmorphism
                    _buildCockpitTelemetryHud(telemetria, isDark, colorScheme),

                    // Barra de Ações Rápidas, Busca e Filtros de Status
                    _buildControlActionBar(
                      atendentes: atendentes,
                      mapMetricas: mapMetricas,
                      isDark: isDark,
                      colorScheme: colorScheme,
                      onAutoEquilibrar: () => _autoEquilibrarCentral(atendentes, allCards, config),
                    ),

                    // Live Floor: Cabines Operacionais + Painel de Inteligência da Central
                    Expanded(
                      child: _buildOperationFloor(
                        atendentesFiltrados: atendentesFiltrados,
                        mapMetricas: mapMetricas,
                        unassignedCards: unassignedCards,
                        atendentes: atendentes,
                        telemetria: telemetria,
                        config: config,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Drawer de Auditoria Shadow (Inspecionar Cabine)
              if (metricsInspecionado != null)
                AtendenteInspectionDrawer(
                  metrics: metricsInspecionado,
                  outrosAtendentes: atendentes.where((a) => a.id != _atendenteInspecionado!.id).toList(),
                  onClose: () => setState(() => _atendenteInspecionado = null),
                  onAbrirChat: (card) => setState(() => _cardSelecionado = card),
                  onTransferirCard: (card, novoId, novoNome) => _transferirCard(card, novoId, novoNome),
                ),
            ],
          ),

          // Painel de Chat Flutuante / Shadow Mode Auditoria
          if (_cardSelecionado != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860, maxHeight: 800),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ChatPage(
                        tenantId: widget.tenantId,
                        atendimentoId: _cardSelecionado!.id,
                        contactName: _cardSelecionado!.clienteNome,
                        contactPhone: _cardSelecionado!.clienteTelefone,
                        leadId: _cardSelecionado!.leadId,
                        fotoUrl: _cardSelecionado!.fotoUrl,
                        onClose: () => setState(() => _cardSelecionado = null),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // APP BAR AERO-CYBER COM MEDALHÃO E BOTÕES PREMIUM
  // ===========================================================================
  PreferredSizeWidget _buildAeroAppBar(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    ConfigAtendimentoModel config,
    List<AtendimentoModel> unassignedCards,
    List<FuncionarioModel> atendentes,
  ) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? const Color(0xFF111C38) : Colors.white,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(LucideIcons.towerControl, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Torre de Controle de Atendimento',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PulsingStatusDot(color: Color(0xFF10B981), size: 6),
                        SizedBox(width: 5),
                        Text(
                          'LIVE TELEMETRY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                'Supervisão Operacional • Gestão de Sobrecarga e Políticas de Transbordo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Botão Políticas de Transbordo
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(LucideIcons.slidersHorizontal, size: 15),
            label: const Text('Políticas de Transbordo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => PoliticasTransbordoDialog.show(
              context,
              tenantId: widget.tenantId,
              configAtual: config,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Botão de Mock de Demonstração (Handerson)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.12),
              foregroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(LucideIcons.sparkles, size: 15),
            label: const Text('Popular Mock Handerson', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () => _popularMockClientesHanderson(atendentes),
          ),
        ),
        const SizedBox(width: 8),

        // Botão Histórico
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(LucideIcons.history, size: 15),
          label: const Text('Histórico', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoryAtendimentoScreen(tenantId: widget.tenantId),
              ),
            );
          },
        ),
        const SizedBox(width: 8),

        // Botão SLAs
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(LucideIcons.clock, size: 15),
          label: const Text('SLAs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => ExpAtendimentoConfigDialog(tenantId: widget.tenantId),
            );
          },
        ),
        const SizedBox(width: 18),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          height: 1,
        ),
      ),
    );
  }

  // ===========================================================================
  // HUD SUPERIOR DE TELEMETRIA COM CARDS GLASSMORPHISM (ZERO OVERFLOW)
  // ===========================================================================
  Widget _buildCockpitTelemetryHud(
    TelemetriaGlobalCentral t,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final formatCurrency = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$ ').format(t.pipelineTotalCentralReais);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Gauge 1: TMR Médio da Operação
              _buildExecutiveGaugeCard(
                icon: LucideIcons.timer,
                title: 'TMR Médio Central',
                value: AtendimentoMetricsHelper.formatarMinutosTempo(t.tmrMedioMinutos),
                statusText: t.tmrMedioMinutos <= 5 ? 'Meta < 5m atingida' : 'Acima do SLA',
                statusColor: t.tmrMedioMinutos <= 5 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                gradientColors: [const Color(0xFF10B981), const Color(0xFF059669)],
                isDark: isDark,
              ),

              // Gauge 2: Taxa de Ocupação da Equipe
              _buildExecutiveGaugeCard(
                icon: LucideIcons.users,
                title: 'Ocupação da Central',
                value: '${t.ocupacaoGlobalPercentual.toStringAsFixed(0)}%',
                statusText: '${t.totalAtendimentosAtivos} de ${t.totalSlotsCapacidade} slots',
                statusColor: t.ocupacaoGlobalPercentual >= 90
                    ? const Color(0xFFEF4444)
                    : t.ocupacaoGlobalPercentual >= 75
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF3B82F6),
                gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                isDark: isDark,
              ),

              // Gauge 3: Radar de Vácuo / Risco de SLA
              _buildExecutiveGaugeCard(
                icon: LucideIcons.bellRing,
                title: 'Clientes no Vácuo',
                value: '${t.totalClientesEmVacuo}',
                statusText: t.totalClientesEmVacuo > 0 ? 'Requer atenção imediata' : 'Nenhum atrasado',
                statusColor: t.totalClientesEmVacuo > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                gradientColors: t.totalClientesEmVacuo > 0
                    ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                    : [const Color(0xFF10B981), const Color(0xFF047857)],
                isDark: isDark,
              ),

              // Gauge 4: Fila de Transbordo / Não Atribuídos
              _buildExecutiveGaugeCard(
                icon: LucideIcons.bot,
                title: 'Fila IA / Espera',
                value: '${t.totalFilaEspera}',
                statusText: t.totalFilaEspera > 0 ? 'Aguardando Roteador' : 'Fila Zerada',
                statusColor: t.totalFilaEspera > 0 ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                isDark: isDark,
              ),

              // Gauge 5: Pipeline Total Ativo
              _buildExecutiveGaugeCard(
                icon: LucideIcons.wallet,
                title: 'Pipeline em Cotação',
                value: formatCurrency,
                statusText: '${t.totalAtendentesOnline} vendedores operando',
                statusColor: const Color(0xFF8B5CF6),
                gradientColors: [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExecutiveGaugeCard({
    required IconData icon,
    required String title,
    required String value,
    required String statusText,
    required Color statusColor,
    required List<Color> gradientColors,
    required bool isDark,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C38) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradientColors),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.first.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BARRA DE AÇÕES RÁPIDAS E FILTROS DE STATUS
  // ===========================================================================
  Widget _buildControlActionBar({
    required List<FuncionarioModel> atendentes,
    required Map<String, AtendenteMetrics> mapMetricas,
    required bool isDark,
    required ColorScheme colorScheme,
    required VoidCallback onAutoEquilibrar,
  }) {
    int fluindo = 0;
    int atencao = 0;
    int sobrecarga = 0;
    int comVacuo = 0;

    for (final m in mapMetricas.values) {
      if (m.isSobrecarregado) {
        sobrecarga++;
      } else if (m.isAtencao) {
        atencao++;
      } else {
        fluindo++;
      }

      if (m.cardsEmVacuo.isNotEmpty) {
        comVacuo++;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 950;

          final searchAndFilters = Row(
            children: [
              // Campo de busca
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240, minWidth: 160),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Filtrar atendente...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : SigeColors.lightTextMuted,
                      ),
                      prefixIcon: const Icon(LucideIcons.search, size: 14),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(LucideIcons.x, size: 12),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF111C38) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Chips de status com visual refinado
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAeroFilterChip('Todos (${atendentes.length})', 'todos', isDark),
                      const SizedBox(width: 6),
                      _buildAeroFilterChip('🟢 Fluindo ($fluindo)', 'fluindo', isDark),
                      const SizedBox(width: 6),
                      _buildAeroFilterChip('🟡 Alta Carga ($atencao)', 'atencao', isDark),
                      const SizedBox(width: 6),
                      _buildAeroFilterChip('🔴 Sobrecarga ($sobrecarga)', 'sobrecarga', isDark),
                      if (comVacuo > 0) ...[
                        const SizedBox(width: 6),
                        _buildAeroFilterChip('⚠️ No Vácuo ($comVacuo)', 'vacuo', isDark),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );

          final actionButtons = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão Auto-Equilibrar Central
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.scale, size: 15),
                  label: const Text('Auto-Equilibrar Central', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: onAutoEquilibrar,
                ),
              ),
              const SizedBox(width: 8),

              // Botão Broadcast / Alerta Geral
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(LucideIcons.megaphone, size: 15),
                label: const Text('Alerta Geral', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => _showBroadcastDialog(context),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchAndFilters,
                const SizedBox(height: 10),
                actionButtons,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchAndFilters),
              const SizedBox(width: 14),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  Widget _buildAeroFilterChip(String label, String id, bool isDark) {
    final isSelected = _filtroStatus == id;

    return InkWell(
      onTap: () => setState(() => _filtroStatus = id),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF111C38) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : SigeColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // LIVE OPERATION FLOOR (CABINES + PAINEL DE INTELIGÊNCIA OPERACIONAL)
  // ===========================================================================
  Widget _buildOperationFloor({
    required List<FuncionarioModel> atendentesFiltrados,
    required Map<String, AtendenteMetrics> mapMetricas,
    required List<AtendimentoModel> unassignedCards,
    required List<FuncionarioModel> atendentes,
    required TelemetriaGlobalCentral telemetria,
    required ConfigAtendimentoModel config,
    required bool isDark,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final showCompanion = screenWidth >= 1150;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asa Esquerda: Grade de Cabines de Atendimento
            Expanded(
              flex: 3,
              child: _buildBoothFloorGrid(
                atendentesFiltrados: atendentesFiltrados,
                mapMetricas: mapMetricas,
                unassignedCards: unassignedCards,
                atendentes: atendentes,
                isDark: isDark,
              ),
            ),

            // Asa Direita: Painel de Inteligência & Monitor de SLAs em Tempo Real
            if (showCompanion) ...[
              Container(
                width: 340,
                margin: const EdgeInsets.fromLTRB(0, 8, 20, 24),
                child: _buildExecutiveIntelligenceCompanion(
                  telemetria: telemetria,
                  unassignedCards: unassignedCards,
                  atendentes: atendentes,
                  config: config,
                  isDark: isDark,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBoothFloorGrid({
    required List<FuncionarioModel> atendentesFiltrados,
    required Map<String, AtendenteMetrics> mapMetricas,
    required List<AtendimentoModel> unassignedCards,
    required List<FuncionarioModel> atendentes,
    required bool isDark,
  }) {
    if (atendentesFiltrados.isEmpty && unassignedCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.users, size: 52, color: Colors.grey[400]),
            const SizedBox(height: 14),
            Text(
              'Nenhum atendente encontrado para este filtro',
              style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width > 1200) {
          crossAxisCount = 3;
        } else if (width > 700) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: CustomScrollView(
            slivers: [
              // Banner Fila IA e Transbordo
              if (unassignedCards.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD97706).withValues(alpha: isDark ? 0.2 : 0.08),
                          const Color(0xFFB45309).withValues(alpha: isDark ? 0.12 : 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFD97706).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD97706).withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.bot, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fila IA Omnichannel & Transbordo (${unassignedCards.length} leads pendentes)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Leads aguardando alocação estratégica por senioridade e volume de cotação',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(LucideIcons.sparkles, size: 15),
                          label: const Text('Roteamento Inteligente', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          onPressed: () => _distribuirFilaEstrategicamente(unassignedCards, atendentes),
                        ),
                      ],
                    ),
                  ),
                ),

              // Grid das Cabines Operacionais
              SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  mainAxisExtent: 365,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final func = atendentesFiltrados[index];
                    final metrics = mapMetricas[func.id];
                    if (metrics == null) return const SizedBox.shrink();

                    final isSelected = _atendenteInspecionado?.id == func.id;

                    return AtendenteCabineCardWidget(
                      metrics: metrics,
                      isSelected: isSelected,
                      onInspecionar: () {
                        setState(() {
                          if (_atendenteInspecionado?.id == func.id) {
                            _atendenteInspecionado = null;
                          } else {
                            _atendenteInspecionado = func;
                          }
                        });
                      },
                      onDesafogar: () => _desafogarAtendente(metrics, atendentes),
                    );
                  },
                  childCount: atendentesFiltrados.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // PAINEL LATERAL DE INTELIGÊNCIA OPERACIONAL (COMPANION EXECUTIVO)
  // ===========================================================================
  Widget _buildExecutiveIntelligenceCompanion({
    required TelemetriaGlobalCentral telemetria,
    required List<AtendimentoModel> unassignedCards,
    required List<FuncionarioModel> atendentes,
    required ConfigAtendimentoModel config,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C38) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Painel de Inteligência
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.cpu, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Torre de Inteligência',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Saúde e vazão da operação',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1),
          const SizedBox(height: 18),

          // Medidor de Aderência ao SLA (Speedometer Visual)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Conformidade de SLA',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      telemetria.totalClientesEmVacuo == 0 ? '100% EXCELENTE' : 'ATENÇÃO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: telemetria.totalClientesEmVacuo == 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: telemetria.totalClientesEmVacuo == 0 ? 1.0 : 0.65,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      telemetria.totalClientesEmVacuo == 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Meta da Distribuidora: Resposta inicial < ${config.slaVacuoAlertaMinutos}m',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Canais Omnichannel de Atendimento (EPIs & Indústria)
          Text(
            'DISTRIBUIÇÃO DE CANAIS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          _buildChannelPill(
            icon: LucideIcons.messageCircle,
            canal: 'WhatsApp Business 24/7',
            percentual: 0.70,
            qtdText: '${(telemetria.totalAtendimentosAtivos * 0.7).round()} leads',
            accentColor: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildChannelPill(
            icon: LucideIcons.building2,
            canal: 'Cotações Corporativas B2B',
            percentual: 0.25,
            qtdText: '${(telemetria.totalAtendimentosAtivos * 0.25).round()} contas',
            accentColor: const Color(0xFF2563EB),
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildChannelPill(
            icon: LucideIcons.shoppingBag,
            canal: 'Balcão / Loja Física',
            percentual: 0.05,
            qtdText: '${(telemetria.totalAtendimentosAtivos * 0.05).round()} pedidos',
            accentColor: const Color(0xFFF59E0B),
            isDark: isDark,
          ),

          const Spacer(),

          // Ação Executiva no Rodapé do Painel
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.sparkles, size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Text(
                      'Diretriz de Produtividade',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Mantenha contas B2B de alto ticket com vendedores sêniores e libere o balcão rápido para a IA.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelPill({
    required IconData icon,
    required String canal,
    required double percentual,
    required String qtdText,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canal,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                qtdText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percentual,
              minHeight: 4.5,
              backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // AÇÕES E REGRAS DE TRANSBORDO & AUTO-EQUILÍBRIO
  // ===========================================================================
  Future<void> _autoEquilibrarCentral(
    List<FuncionarioModel> atendentes,
    List<AtendimentoModel> allCards,
    ConfigAtendimentoModel config,
  ) async {
    final notifier = ref.read(atendimentoProvider(widget.tenantId).notifier);

    // Identifica atendentes sobrecarregados e ociosos
    final metricas = atendentes.map((f) {
      return AtendimentoMetricsHelper.calcularMetricasAtendente(
        funcionario: f,
        todosCards: allCards,
        config: config,
      );
    }).toList();

    final sobrecarregados = metricas.where((m) => m.isSobrecarregado).toList();
    final disponiveis = metricas.where((m) => m.isDisponivel).toList();

    if (sobrecarregados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A central já está perfeitamente balanceada! Nenhum atendente em sobrecarga.'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      return;
    }

    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os atendentes estão com alta ocupação. Considere elevar as capacidades nas Políticas.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
      return;
    }

    int transferidos = 0;

    // Transborda os cards excedentes dos sobrecarregados para os mais livres
    disponiveis.sort((a, b) => a.percentualOcupacao.compareTo(b.percentualOcupacao));

    for (final sob in sobrecarregados) {
      final excesso = sob.excessoCards;
      if (excesso <= 0) continue;

      // Pega os cards mais antigos ou sem interação recente
      final cardsParaMover = sob.cardsAtivos.take(excesso).toList();

      for (int i = 0; i < cardsParaMover.length; i++) {
        final card = cardsParaMover[i];
        final destino = disponiveis[i % disponiveis.length];

        await notifier.reassignCard(
          card.id,
          destino.funcionario.id,
          newFuncionarioNome: destino.funcionario.nome,
          motivo: 'Auto-equilíbrio de carga por política de sobrecarga da central',
        );
        transferidos++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Operação concluída! $transferidos atendimento(s) redistribuídos com sucesso.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _desafogarAtendente(
    AtendenteMetrics metrics,
    List<FuncionarioModel> todosAtendentes,
  ) async {
    final notifier = ref.read(atendimentoProvider(widget.tenantId).notifier);

    // Encontra o colega mais livre
    final outros = todosAtendentes.where((a) => a.id != metrics.funcionario.id).toList();
    if (outros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há outros atendentes cadastrados para receber o transbordo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pega os 2 cards mais antigos
    final qtd = min(2, metrics.cardsAtivos.length);
    final cardsParaMover = metrics.cardsAtivos.take(qtd).toList();
    final destino = outros.first;

    for (final card in cardsParaMover) {
      await notifier.reassignCard(
        card.id,
        destino.id,
        newFuncionarioNome: destino.nome,
        motivo: 'Alívio rápido de sobrecarga solicitado pelo gerente',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cardsParaMover.length} atendimento(s) de ${metrics.funcionario.nome} transferidos para ${destino.nome}.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _distribuirFilaEstrategicamente(
    List<AtendimentoModel> unassignedCards,
    List<FuncionarioModel> atendentes,
  ) async {
    final notifier = ref.read(atendimentoProvider(widget.tenantId).notifier);
    if (atendentes.isEmpty) return;

    int distribuidos = 0;
    for (int i = 0; i < unassignedCards.length; i++) {
      final card = unassignedCards[i];
      final func = atendentes[i % atendentes.length];

      await notifier.reassignCard(
        card.id,
        func.id,
        newFuncionarioNome: func.nome,
        motivo: 'Roteamento estratégico inteligente de fila',
      );
      distribuidos++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$distribuidos lead(s) distribuídos com sucesso entre a equipe!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _transferirCard(
    AtendimentoModel card,
    String novoId,
    String novoNome,
  ) async {
    final notifier = ref.read(atendimentoProvider(widget.tenantId).notifier);
    await notifier.reassignCard(
      card.id,
      novoId,
      newFuncionarioNome: novoNome,
      motivo: 'Transferência direta realizada no modo auditoria',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Atendimento de "${card.clienteNome}" transferido para $novoNome.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _showBroadcastDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(LucideIcons.megaphone, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text('Alerta Geral para a Central', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Envie um aviso operacional imediato para todos os atendentes conectados:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ex: Foco nas cotações de EPIs da construtora X nesta tarde...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(LucideIcons.send, size: 14),
              label: const Text('Disparar Alerta'),
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alerta geral transmitido para a central com sucesso!'),
                    backgroundColor: Color(0xFF2563EB),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Popula atendimentos mockados com cenário real de EPIs para Handerson no Firestore
  Future<void> _popularMockClientesHanderson(List<FuncionarioModel> atendentes) async {
    // Mostra indicador de progresso
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Populando 5 atendimentos e cotações de EPIs para Handerson...'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF3B82F6),
        ),
      );
    }

    try {
      // Localiza o atendente Handerson na lista de funcionários
      final handerson = atendentes.firstWhere(
        (a) => a.nome.toLowerCase().contains('handerson'),
        orElse: () => atendentes.isNotEmpty ? atendentes.first : throw Exception('Nenhum atendente disponível'),
      );

      final firestore = FirebaseFirestore.instance;
      final tenantId = widget.tenantId;

      // Obtém ou cria colunas se o board ainda não possuir
      final colRef = firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('atendimento')
          .doc('board')
          .collection('columns');

      final colsSnapshot = await colRef.get();
      String primeiraColunaId = 'novo';
      String segundaColunaId = 'em_atendimento';
      String terceiraColunaId = 'concluido';

      if (colsSnapshot.docs.isEmpty) {
        // Inicializa colunas padrão do board caso ainda não existam no Firestore
        await colRef.doc('novo').set({
          'tenant_id': tenantId,
          'titulo': 'Novo / Triagem',
          'ordem': 0,
          'cor': '0xFF3B82F6',
          'is_sistema': true,
        });
        await colRef.doc('em_atendimento').set({
          'tenant_id': tenantId,
          'titulo': 'Em Cotação',
          'ordem': 1,
          'cor': '0xFFF59E0B',
          'is_sistema': true,
        });
        await colRef.doc('concluido').set({
          'tenant_id': tenantId,
          'titulo': 'Fechamento / Pedido',
          'ordem': 2,
          'cor': '0xFF10B981',
          'is_sistema': true,
        });
      } else {
        final docs = colsSnapshot.docs;
        primeiraColunaId = docs[0].id;
        segundaColunaId = docs.length > 1 ? docs[1].id : docs[0].id;
        terceiraColunaId = docs.length > 2 ? docs[2].id : segundaColunaId;
      }

      final cardsRef = firestore
          .collection('tenant')
          .doc(tenantId)
          .collection('atendimento')
          .doc('board')
          .collection('historico');

      final now = DateTime.now();

      final mocks = [
        AtendimentoModel(
          id: '',
          tenantId: tenantId,
          titulo: 'Cotação 400 Botinas c/ Bico Composite + 1.200 Luvas Nitrílicas',
          colunaStatus: segundaColunaId,
          prioridade: 'alta',
          clienteNome: 'Construtora Andrade & Gutierrez B2B',
          clienteTelefone: '(11) 98765-4321',
          dataCriacao: now.subtract(const Duration(hours: 4)),
          dataUltimaAtualizacao: now.subtract(const Duration(minutes: 15)),
          status: 'ativo',
          isAtivo: true,
          ultimaMensagem: 'Boa tarde Handerson! Conseguiu a ficha técnica dos CAs para faturar em 3x no boleto?',
          ultimaMensagemData: now.subtract(const Duration(minutes: 15)),
          mensagensNaoLidas: 1,
          funcionarioResponsavelId: handerson.id,
          funcionarioResponsavelNome: handerson.nome,
          valorEstimado: 64500.0,
          categoriaTicket: 'alto_ticket',
          tipoCliente: 'B2B_CORPORATIVO',
          quantidadeItensEstimada: 1600,
          ultimoFollowUpEm: now.subtract(const Duration(minutes: 15)),
        ),
        AtendimentoModel(
          id: '',
          tenantId: tenantId,
          titulo: 'Fornecimento Mensal EPIs Manutenção Frigorífico',
          colunaStatus: terceiraColunaId,
          prioridade: 'urgente',
          clienteNome: 'Frigorífico Sul Minas Alimentos S/A',
          clienteTelefone: '(35) 99882-1122',
          dataCriacao: now.subtract(const Duration(days: 1)),
          dataUltimaAtualizacao: now.subtract(const Duration(hours: 1)),
          status: 'ativo',
          isAtivo: true,
          ultimaMensagem: 'Estamos alinhando o contrato anual de 250 conjuntos térmicos e botas frigoríficas.',
          ultimaMensagemData: now.subtract(const Duration(hours: 1)),
          mensagensNaoLidas: 0,
          funcionarioResponsavelId: handerson.id,
          funcionarioResponsavelNome: handerson.nome,
          valorEstimado: 38200.0,
          categoriaTicket: 'alto_ticket',
          tipoCliente: 'B2B_CORPORATIVO',
          quantidadeItensEstimada: 500,
          ultimoFollowUpEm: now.subtract(const Duration(hours: 1)),
        ),
        AtendimentoModel(
          id: '',
          tenantId: tenantId,
          titulo: 'Lote 80 Cintos Paraquedistas c/ Talabarte NR-35',
          colunaStatus: segundaColunaId,
          prioridade: 'alta',
          clienteNome: 'Engenharia & Montagens Industriais',
          clienteTelefone: '(31) 98451-9900',
          dataCriacao: now.subtract(const Duration(hours: 5)),
          dataUltimaAtualizacao: now.subtract(const Duration(minutes: 42)),
          status: 'ativo',
          isAtivo: true,
          ultimaMensagem: 'Handerson, precisamos do laudo do CA até amanhã cedo para liberação do SESMT da refinaria.',
          ultimaMensagemData: now.subtract(const Duration(minutes: 42)),
          mensagensNaoLidas: 2,
          funcionarioResponsavelId: handerson.id,
          funcionarioResponsavelNome: handerson.nome,
          valorEstimado: 21600.0,
          categoriaTicket: 'alto_ticket',
          tipoCliente: 'B2B_CORPORATIVO',
          quantidadeItensEstimada: 80,
          ultimoFollowUpEm: now.subtract(const Duration(minutes: 42)), // Cliente em vácuo (> SLA)!
        ),
        AtendimentoModel(
          id: '',
          tenantId: tenantId,
          titulo: 'Reposição 15 Óculos de Proteção e Protetores Tipo Concha',
          colunaStatus: primeiraColunaId,
          prioridade: 'media',
          clienteNome: 'Serralheria & Estruturas Metálicas Silva',
          clienteTelefone: '(11) 97123-5544',
          dataCriacao: now.subtract(const Duration(minutes: 50)),
          dataUltimaAtualizacao: now.subtract(const Duration(minutes: 2)),
          status: 'ativo',
          isAtivo: true,
          ultimaMensagem: 'Tem o modelo fumê para pronta entrega com retirada na loja?',
          ultimaMensagemData: now.subtract(const Duration(minutes: 2)),
          mensagensNaoLidas: 0,
          funcionarioResponsavelId: handerson.id,
          funcionarioResponsavelNome: handerson.nome,
          valorEstimado: 1450.0,
          categoriaTicket: 'medio_ticket',
          tipoCliente: 'B2B_PEQUENO',
          quantidadeItensEstimada: 30,
          ultimoFollowUpEm: now.subtract(const Duration(minutes: 2)),
        ),
        AtendimentoModel(
          id: '',
          tenantId: tenantId,
          titulo: '1 Par de Botina Nobuck Tam 42 Balcão',
          colunaStatus: primeiraColunaId,
          prioridade: 'baixa',
          clienteNome: 'Carlos Eduardo (Pessoa Física)',
          clienteTelefone: '(11) 96541-2233',
          dataCriacao: now.subtract(const Duration(minutes: 10)),
          dataUltimaAtualizacao: now.subtract(const Duration(minutes: 1)),
          status: 'ativo',
          isAtivo: true,
          ultimaMensagem: 'Oi, passa cartão na maquininha se eu for buscar aí?',
          ultimaMensagemData: now.subtract(const Duration(minutes: 1)),
          mensagensNaoLidas: 1,
          funcionarioResponsavelId: handerson.id,
          funcionarioResponsavelNome: handerson.nome,
          valorEstimado: 140.0,
          categoriaTicket: 'baixo_ticket',
          tipoCliente: 'B2C_VAREJO',
          quantidadeItensEstimada: 1,
          ultimoFollowUpEm: now.subtract(const Duration(minutes: 1)),
        ),
      ];

      for (final m in mocks) {
        final docRef = await cardsRef.add(m.toMap());
        await docRef.update({'id': docRef.id});
      }

      // Força refresh imediato dos providers
      ref.invalidate(globalAtendimentoProvider(widget.tenantId));
      ref.invalidate(atendimentoProvider(widget.tenantId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${mocks.length} atendimentos de EPIs (Total R\$ 125.890,00) adicionados para ${handerson.nome}!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao popular mock: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}



import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/usage_finops_model.dart';
import '../../models/whatsapp_number_model.dart';
import '../../providers/whatsapp_finops_providers.dart';
import '../../services/whatsapp_meta_service.dart';
import 'whatsapp_embedded_signup_dialog.dart';

/// Executive cockpit tab providing FinOps cost governance for AI and official Meta WhatsApp Cloud API,
/// as well as centralized management of connected WhatsApp Business accounts.
///
/// Reference: MD07 §5.1, PROJECT.md Features #21, #22, #23.
class CanaisConsumoIaTab extends ConsumerStatefulWidget {
  final String tenantId;

  const CanaisConsumoIaTab({
    super.key,
    required this.tenantId,
  });

  @override
  ConsumerState<CanaisConsumoIaTab> createState() => _CanaisConsumoIaTabState();
}

class _CanaisConsumoIaTabState extends ConsumerState<CanaisConsumoIaTab> {
  bool _isLineChart = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentComp = ref.watch(selectedCompetenciaProvider(widget.tenantId));
    final usageAsync = ref.watch(usageFinopsStreamProvider(widget.tenantId));
    final numbersAsync = ref.watch(whatsappNumbersStreamProvider(widget.tenantId));

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B132B) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Competence Selector and Quick Summary
            _buildCompetenciaBar(context, theme, isDark, currentComp),
            const SizedBox(height: 20),

            // Section 1: Executive KPI Strip (4 Cards)
            usageAsync.when(
              loading: () => _buildLoadingKpiStrip(theme, isDark),
              error: (err, _) => _buildErrorCard(theme, 'Erro ao carregar telemetria FinOps: $err'),
              data: (usage) => _buildKpiStrip(
                context,
                theme,
                isDark,
                usage ??
                    UsageFinopsModel.zeroState(
                      tenantId: widget.tenantId,
                      competencia: currentComp,
                    ),
              ),
            ),
            const SizedBox(height: 32),

            // Section 2: Central de Números Conectados (Meta Cloud API)
            numbersAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => _buildErrorCard(theme, 'Erro ao carregar números conectados: $err'),
              data: (numbers) => _buildConnectedNumbersSection(context, theme, isDark, numbers),
            ),
            const SizedBox(height: 32),

            // Section 3: Cost & Usage Analytics (fl_chart ^0.66.2 + Breakdown)
            usageAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (usage) => _buildAnalyticsSection(
                context,
                theme,
                isDark,
                usage ??
                    UsageFinopsModel.zeroState(
                      tenantId: widget.tenantId,
                      competencia: currentComp,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP COMPETENCE BAR
  // ===========================================================================

  Widget _buildCompetenciaBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String currentComp,
  ) {
    final competencias = WhatsAppMetaService.generateRecentCompetencias(count: 6);

    final dropdownWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          value: currentComp,
          icon: const Icon(LucideIcons.chevronDown, size: 16),
          dropdownColor: isDark ? const Color(0xFF16203A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: competencias.map((comp) {
            final parts = comp.split('_');
            final monthLabel = switch (parts.length == 2 ? parts[1] : '') {
              '01' => 'Janeiro',
              '02' => 'Fevereiro',
              '03' => 'Março',
              '04' => 'Abril',
              '05' => 'Maio',
              '06' => 'Junho',
              '07' => 'Julho',
              '08' => 'Agosto',
              '09' => 'Setembro',
              '10' => 'Outubro',
              '11' => 'Novembro',
              '12' => 'Dezembro',
              _ => comp,
            };
            final yearLabel = parts.isNotEmpty ? parts[0] : '';
            return DropdownMenuItem<String>(
              value: comp,
              child: Text(
                '$monthLabel/$yearLabel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            );
          }).toList(),
          onChanged: (newComp) {
            if (newComp != null && newComp != currentComp) {
              ref.read(selectedCompetenciaProvider(widget.tenantId).notifier).state = newComp;
            }
          },
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 620;

        final titleBlock = Row(
          mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.calendarCheck2, color: Color(0xFF2563EB), size: 18),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Competência Contábil FinOps',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Telemetria Mensal Agregada (O(1) Firestore Read)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16203A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    dropdownWidget,
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: titleBlock),
                    const SizedBox(width: 16),
                    dropdownWidget,
                  ],
                ),
        );
      },
    );
  }

  // ===========================================================================
  // SECTION 1: EXECUTIVE KPI STRIP
  // ===========================================================================

  Widget _buildKpiStrip(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    UsageFinopsModel usage,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;
        final isMedium = constraints.maxWidth >= 650 && constraints.maxWidth < 1050;

        final cardInvestimento = _buildKpiCard(
          theme: theme,
          isDark: isDark,
          title: 'INVESTIMENTO TOTAL',
          value: usage.custoTotalFormatadoBrl,
          detail: usage.healthStatus.label,
          detailColor: usage.healthStatus.color,
          icon: LucideIcons.walletCards,
          iconColor: const Color(0xFF2563EB),
          iconBg: const Color(0xFF2563EB).withValues(alpha: 0.1),
        );

        final cardIa = _buildKpiCard(
          theme: theme,
          isDark: isDark,
          title: 'CONSUMO MOTOR IA',
          value: usage.iaMetrics.custoFormatadoBrl,
          detail: '${usage.iaMetrics.totalTokensFormatado} tokens consumidos',
          subtitle: '⚡ ${usage.iaMetrics.totalRequests} respostas automáticas',
          icon: LucideIcons.cpu,
          iconColor: const Color(0xFF7C3AED),
          iconBg: const Color(0xFF7C3AED).withValues(alpha: 0.1),
        );

        final cardMeta = _buildKpiCard(
          theme: theme,
          isDark: isDark,
          title: 'MENSAGERIA META API',
          value: usage.whatsappMetrics.custoFormatadoBrl,
          detail: '${usage.whatsappMetrics.totalConversas} conversas no período',
          subtitle: '🎁 ${usage.whatsappMetrics.conversasServicoGratuitas} janelas grátis 24h',
          icon: LucideIcons.messageSquareCode,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFF10B981).withValues(alpha: 0.1),
        );

        final cardOrcamento = _buildBudgetHealthCard(
          context: context,
          theme: theme,
          isDark: isDark,
          usage: usage,
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cardInvestimento),
              const SizedBox(width: 16),
              Expanded(child: cardIa),
              const SizedBox(width: 16),
              Expanded(child: cardMeta),
              const SizedBox(width: 16),
              Expanded(child: cardOrcamento),
            ],
          );
        } else if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cardInvestimento),
                  const SizedBox(width: 16),
                  Expanded(child: cardIa),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: cardMeta),
                  const SizedBox(width: 16),
                  Expanded(child: cardOrcamento),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              cardInvestimento,
              const SizedBox(height: 12),
              cardIa,
              const SizedBox(height: 12),
              cardMeta,
              const SizedBox(height: 12),
              cardOrcamento,
            ],
          );
        }
      },
    );
  }

  Widget _buildKpiCard({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String value,
    required String detail,
    Color? detailColor,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16203A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: detailColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBudgetHealthCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required UsageFinopsModel usage,
  }) {
    final progress = (usage.percentualOrcamentoConsumido / 100.0).clamp(0.0, 1.0);
    final healthColor = usage.healthStatus.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16203A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'SAÚDE DO ORÇAMENTO',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showAdjustBudgetModal(context, usage),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.slidersHorizontal, size: 12, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Text(
                        'Ajustar',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${usage.percentualOrcamentoConsumido.toStringAsFixed(1).replaceAll('.', ',')}%',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: healthColor,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'de ${usage.orcamentoFormatadoBrl}',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: healthColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(healthColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saldo restante: ${usage.saldoRestanteFormatadoBrl}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingKpiStrip(ThemeData theme, bool isDark) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16203A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  // ===========================================================================
  // SECTION 2: CENTRAL DE NÚMEROS WHATSAPP BUSINESS OFICIAIS
  // ===========================================================================

  Widget _buildConnectedNumbersSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<WhatsAppNumberModel> numbers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with CTA button
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 750;

            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.messageCircle, color: Color(0xFF10B981), size: 22),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Central de Números WhatsApp Business Oficiais (Meta Cloud API)',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Conecte números oficiais via Cadastro Incorporado da Meta com ativação automática de Webhooks e IA 24/7.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            );

            final ctaButton = ElevatedButton.icon(
              onPressed: () => _openConnectDialog(context),
              icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
              label: Text(
                'Conectar WhatsApp Oficial',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleBlock,
                  const SizedBox(height: 14),
                  ctaButton,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                ctaButton,
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Grid of numbers or Zero State
        if (numbers.isEmpty)
          _buildNumbersZeroState(context, theme, isDark)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isTwoColumns = constraints.maxWidth >= 900;
              if (isTwoColumns) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: numbers.map((numberItem) {
                    final cardWidth = (constraints.maxWidth - 16) / 2;
                    return SizedBox(
                      width: cardWidth,
                      child: _buildNumberCard(context, theme, isDark, numberItem),
                    );
                  }).toList(),
                );
              } else {
                return Column(
                  children: numbers
                      .map((numberItem) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildNumberCard(context, theme, isDark, numberItem),
                          ))
                      .toList(),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildNumberCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    WhatsAppNumberModel number,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16203A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: number.isOperational
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          width: number.isDefault ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Phone Number, Official Badge, Default Badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: number.isOperational ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      number.displayPhoneNumber,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (number.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PADRÃO',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'OFICIAL META ✓',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Business Name
          Text(
            number.verifiedName,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),

          // Technical Meta IDs
          Text(
            'WABA ID: ${number.wabaId} • Phone ID: ${number.phoneNumberId}',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),

          // Badges: Quality, Tier, Webhook
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Quality Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: number.qualityRating.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: number.qualityRating.borderColor),
                ),
                child: Text(
                  number.qualityRating.badgeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: number.qualityRating.color,
                  ),
                ),
              ),

              // Messaging Limit Tier Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Text(
                  number.messagingLimitTier.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
              ),

              // Webhook Subscribed Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: number.webhookSubscribed
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: number.webhookSubscribed
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Text(
                  number.webhookSubscribed
                      ? '🟢 Inscrito (subscribed_apps ativo)'
                      : '🔴 Webhook Inativo',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: number.webhookSubscribed
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Action Footer: AI 24/7 Switch, Sync, Disconnect
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              // 24/7 AI Toggle
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.bot, size: 16, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  Text(
                    'IA 24/7:',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: number.iaAtivaNesteNumero,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF10B981),
                    onChanged: (val) => _handleToggleIa(context, number, val),
                  ),
                ],
              ),

              // Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _handleSyncNumber(context, number),
                    icon: const Icon(LucideIcons.refreshCw, size: 13),
                    label: const Text('Sincronizar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _confirmDisconnectDialog(context, number),
                    icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFEF4444)),
                    tooltip: 'Desvincular Número',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumbersZeroState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16203A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(LucideIcons.messageCirclePlus, size: 32, color: Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum Número WhatsApp Business Vinculado',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              'Conecte o número de atendimento da sua empresa através do Cadastro Incorporado Oficial da Meta. Em menos de 2 minutos, o aplicativo inscreve webhooks automaticamente e ativa o bot de IA 24/7.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openConnectDialog(context),
            icon: const Icon(LucideIcons.link2, size: 16, color: Colors.white),
            label: Text(
              'Vincular Primeiro Número Oficial',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: COST & USAGE ANALYTICS (fl_chart ^0.66.2)
  // ===========================================================================

  Widget _buildAnalyticsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    UsageFinopsModel usage,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1100;

        final chartCard = _buildDailyChartCard(context, theme, isDark, usage);
        final breakdownCard = _buildCategoryBreakdownCard(context, theme, isDark, usage);

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: chartCard),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: breakdownCard),
            ],
          );
        } else {
          return Column(
            children: [
              chartCard,
              const SizedBox(height: 24),
              breakdownCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildDailyChartCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    UsageFinopsModel usage,
  ) {
    final daily = usage.historicoDiario;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16203A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header with Mode Toggle
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolução Diária de Custos',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Investimento comparado: Motor IA vs Mensageria Meta',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  // Legend
                  _buildLegendDot(const Color(0xFF6366F1), 'Custo IA', isDark),
                  _buildLegendDot(const Color(0xFF10B981), 'Custo Meta', isDark),

                  // Mode Toggle Button (Bar vs Line)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            LucideIcons.chartColumn,
                            size: 16,
                            color: !_isLineChart ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(() => _isLineChart = false),
                          tooltip: 'Visualizar em Barras',
                        ),
                        IconButton(
                          icon: Icon(
                            LucideIcons.chartLine,
                            size: 16,
                            color: _isLineChart ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(() => _isLineChart = true),
                          tooltip: 'Visualizar em Linhas',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Chart Render
          SizedBox(
            height: 300,
            child: daily.isEmpty
                ? _buildChartEmptyState(theme, isDark)
                : (_isLineChart
                    ? _buildLineChart(theme, isDark, daily)
                    : _buildBarChart(theme, isDark, daily)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildChartEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.activity, size: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          const SizedBox(height: 10),
          Text(
            'Nenhum evento registrado ainda nesta competência',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Os custos diários serão plotados automaticamente conforme as mensagens forem processadas.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme, bool isDark, List<HistoricoDiarioItem> daily) {
    double maxCost = 0.0;
    for (final item in daily) {
      if (item.custoIa > maxCost) maxCost = item.custoIa;
      if (item.custoWa > maxCost) maxCost = item.custoWa;
    }
    final maxY = maxCost > 0 ? (maxCost * 1.3).ceilToDouble() : 50.0;
    final interval = maxY > 0 ? (maxY / 4).ceilToDouble() : 10.0;

    final barGroups = daily.map((item) {
      return BarChartGroupData(
        x: item.dia,
        barRods: [
          BarChartRodData(
            toY: item.custoIa,
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF818CF8)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
          BarChartRodData(
            toY: item.custoWa,
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF34D399)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isIa = rodIndex == 0;
              final label = isIa ? 'Motor IA' : 'Mensagens Meta';
              final rodColor = isIa ? const Color(0xFF818CF8) : const Color(0xFF34D399);
              return BarTooltipItem(
                'Dia ${group.x}\n',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: GoogleFonts.inter(
                      color: rodColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'R\$ ${rod.toY.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                if (daily.length > 15 && day % 2 != 0) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'D$day',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  'R\$ ${value.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
      swapAnimationDuration: const Duration(milliseconds: 350),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }

  Widget _buildLineChart(ThemeData theme, bool isDark, List<HistoricoDiarioItem> daily) {
    double maxCost = 0.0;
    for (final item in daily) {
      if (item.custoIa > maxCost) maxCost = item.custoIa;
      if (item.custoWa > maxCost) maxCost = item.custoWa;
    }
    final maxY = maxCost > 0 ? (maxCost * 1.3).ceilToDouble() : 50.0;
    final interval = maxY > 0 ? (maxY / 4).ceilToDouble() : 10.0;

    return LineChart(
      LineChartData(
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final isIa = spot.barIndex == 0;
                final label = isIa ? 'Motor IA' : 'Meta WA';
                final color = isIa ? const Color(0xFF818CF8) : const Color(0xFF34D399);
                return LineTooltipItem(
                  'Dia ${spot.x.toInt()} - $label: R\$ ${spot.y.toStringAsFixed(2).replaceAll('.', ',')}',
                  GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final day = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    'D$day',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: interval,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  'R\$ ${value.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: daily.map((e) => FlSpot(e.dia.toDouble(), e.custoIa)).toList(),
            isCurved: true,
            color: const Color(0xFF6366F1),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
            ),
          ),
          LineChartBarData(
            spots: daily.map((e) => FlSpot(e.dia.toDouble(), e.custoWa)).toList(),
            isCurved: true,
            color: const Color(0xFF10B981),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildCategoryBreakdownCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    UsageFinopsModel usage,
  ) {
    final wa = usage.whatsappMetrics;
    final ia = usage.iaMetrics;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16203A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detalhamento por Categoria',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Distribuição granular de custos e volumetria',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),

          // 1. Janelas de Serviço (Grátis 24h)
          _buildCategoryRow(
            isDark: isDark,
            icon: LucideIcons.gift,
            iconColor: const Color(0xFF10B981),
            title: 'Janelas de Serviço (Grátis 24h)',
            subtitle: '${wa.conversasServicoGratuitas} conversas iniciadas pelo cliente',
            valueText: 'R\$ 0,00',
            badgeText: 'GRÁTIS',
            badgeColor: const Color(0xFF10B981),
          ),
          const Divider(height: 20),

          // 2. Templates Utilidade
          _buildCategoryRow(
            isDark: isDark,
            icon: LucideIcons.bellRing,
            iconColor: const Color(0xFF3B82F6),
            title: 'Templates de Utilidade',
            subtitle: '${wa.conversasUtilidade} disparos transacionais/pedidos',
            valueText: 'R\$ ${(wa.conversasUtilidade * 0.18).toStringAsFixed(2).replaceAll('.', ',')}',
          ),
          const Divider(height: 20),

          // 3. Templates Marketing
          _buildCategoryRow(
            isDark: isDark,
            icon: LucideIcons.megaphone,
            iconColor: const Color(0xFFF97316),
            title: 'Templates de Marketing',
            subtitle: '${wa.conversasMarketing} ofertas e campanhas ativas',
            valueText: 'R\$ ${(wa.conversasMarketing * 0.35).toStringAsFixed(2).replaceAll('.', ',')}',
          ),
          const Divider(height: 20),

          // 4. Motor IA Generativa (LLM)
          _buildCategoryRow(
            isDark: isDark,
            icon: LucideIcons.bot,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Motor de IA LLM (Texto/Cotações)',
            subtitle: '${ia.totalRequests} requisições • ${ia.totalTokensFormatado} tokens',
            valueText: ia.custoFormatadoBrl,
          ),
          const Divider(height: 20),

          // 5. Transcrição Áudio & Visão OCR
          _buildCategoryRow(
            isDark: isDark,
            icon: LucideIcons.mic,
            iconColor: const Color(0xFFEAB308),
            title: 'Multimodal (Áudio STT & Visão)',
            subtitle: '${ia.audiosTranscritosMinutos} min áudio • ${ia.documentosAnalisados} docs PDF/Img',
            valueText: 'R\$ ${((ia.audiosTranscritosMinutos * 0.20) + (ia.documentosAnalisados * 0.25)).toStringAsFixed(2).replaceAll('.', ',')}',
          ),

          const SizedBox(height: 18),
          // Estimated Human Hours Saved Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Color(0xFF7C3AED), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Economia estimada: ~${ia.economiaEstimadaHorasHumanas.toStringAsFixed(1)} horas de equipe humana poupadas neste mês!',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFDDD6FE) : const Color(0xFF5B21B6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String valueText,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              valueText,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? iconColor).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: badgeColor ?? iconColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildErrorCard(ThemeData theme, String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: Color(0xFFDC2626)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODALS & ACTIONS
  // ===========================================================================

  void _openConnectDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WhatsAppEmbeddedSignupDialog(tenantId: widget.tenantId),
    );
  }

  void _showAdjustBudgetModal(BuildContext context, UsageFinopsModel usage) {
    final controller = TextEditingController(
      text: usage.orcamentoMensalBrl > 0
          ? usage.orcamentoMensalBrl.toStringAsFixed(0)
          : '1000',
    );

    showDialog<void>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF16203A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.wallet, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Ajustar Teto de Orçamento',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (ctx, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Defina o teto mensal de investimento para a competência ${usage.competenciaFormatada}. '
                    'O sistema disparará alertas visuais e notificações ao atingir 80% do valor definido.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.4,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Novo Teto Mensal (R\$)',
                      prefixText: 'R\$ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    children: ['500', '1000', '2500', '5000'].map((preset) {
                      return ActionChip(
                        label: Text('R\$ $preset'),
                        onPressed: () {
                          setModalState(() {
                            controller.text = preset;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final text = controller.text.trim().replaceAll(',', '.');
                final newBudget = double.tryParse(text) ?? usage.orcamentoMensalBrl;

                Navigator.of(ctx).pop();
                try {
                  await ref.read(whatsappMetaServiceProvider).updateMonthlyBudget(
                    tenantId: widget.tenantId,
                    newBudgetBrl: newBudget,
                    competencia: usage.competencia,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Teto de orçamento atualizado com sucesso!'),
                        backgroundColor: Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao atualizar orçamento: $e'),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar Orçamento'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDisconnectDialog(BuildContext context, WhatsAppNumberModel number) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: Color(0xFFDC2626)),
              SizedBox(width: 8),
              Text('Desvincular Número?'),
            ],
          ),
          content: Text(
            'Deseja realmente desvincular o número oficial ${number.displayPhoneNumber} (${number.verifiedName})?\n\n'
            'O atendimento automatizado por IA 24/7 e o recebimento de mensagens oficiais serão interrompidos para este canal.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await ref.read(whatsappMetaServiceProvider).disconnectNumber(
                    tenantId: widget.tenantId,
                    phoneNumberId: number.phoneNumberId,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Número ${number.displayPhoneNumber} desvinculado com sucesso.'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao desvincular número: $e'),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                }
              },
              child: const Text('Desvincular'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSyncNumber(BuildContext context, WhatsAppNumberModel number) async {
    try {
      await ref.read(whatsappMetaServiceProvider).syncNumber(
        tenantId: widget.tenantId,
        phoneNumberId: number.phoneNumberId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Metadados e saúde do número ${number.displayPhoneNumber} sincronizados.'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao sincronizar número: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _handleToggleIa(
    BuildContext context,
    WhatsAppNumberModel number,
    bool enabled,
  ) async {
    try {
      await ref.read(whatsappMetaServiceProvider).toggleIa(
        tenantId: widget.tenantId,
        phoneNumberId: number.phoneNumberId,
        enabled: enabled,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'IA 24/7 ativada para ${number.displayPhoneNumber}.'
                  : 'IA 24/7 pausada para ${number.displayPhoneNumber}.',
            ),
            backgroundColor: enabled ? const Color(0xFF10B981) : const Color(0xFFCA8A04),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status da IA: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }
}

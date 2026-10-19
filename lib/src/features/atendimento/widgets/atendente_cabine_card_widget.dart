import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import 'package:sige/src/core/theme/sige_colors.dart';
import 'package:sige/src/features/atendimento/services/atendimento_metrics_helper.dart';

/// Ponto de status com animação de pulso sonar em tempo real
class PulsingStatusDot extends StatefulWidget {
  final Color color;
  final double size;

  const PulsingStatusDot({
    super.key,
    required this.color,
    this.size = 12,
  });

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );

    _fadeAnimation = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: _fadeAnimation.value),
                  ),
                ),
              );
            },
          ),
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Termômetro de capacidade com slots segmentados estilo cabine aeroespacial
class SegmentedCapacityBar extends StatelessWidget {
  final int totalAtivos;
  final int capacidadeMaxima;
  final bool isSobrecarregado;
  final Color statusColor;

  const SegmentedCapacityBar({
    super.key,
    required this.totalAtivos,
    required this.capacidadeMaxima,
    required this.isSobrecarregado,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSlots = max(1, capacidadeMaxima);
    final slotsPreenchidos = min(totalAtivos, totalSlots);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(totalSlots, (index) {
            final isFilled = index < slotsPreenchidos;

            // Graduação de cor dos slots: verde nos primeiros, amarelo no final, vermelho se sobrecarregado
            Color slotColor;
            if (isSobrecarregado) {
              slotColor = const Color(0xFFEF4444);
            } else if (index >= totalSlots * 0.75) {
              slotColor = const Color(0xFFF59E0B);
            } else {
              slotColor = const Color(0xFF10B981);
            }

            return Expanded(
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200 + (index * 40)),
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isFilled
                      ? slotColor
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0)),
                  boxShadow: isFilled
                      ? [
                          BoxShadow(
                            color: slotColor.withValues(alpha: 0.4),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Cabine Operacional do Vendedor com design Aero-Cyber, hover interativo e telemetria fina
class AtendenteCabineCardWidget extends StatefulWidget {
  final AtendenteMetrics metrics;
  final VoidCallback onInspecionar;
  final VoidCallback onDesafogar;
  final bool isSelected;

  const AtendenteCabineCardWidget({
    super.key,
    required this.metrics,
    required this.onInspecionar,
    required this.onDesafogar,
    this.isSelected = false,
  });

  @override
  State<AtendenteCabineCardWidget> createState() =>
      _AtendenteCabineCardWidgetState();
}

class _AtendenteCabineCardWidgetState extends State<AtendenteCabineCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final f = widget.metrics.funcionario;
    final faturamentoFormatado = NumberFormat.compactCurrency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
    ).format(widget.metrics.pipelineTotalReais);

    // Status de cor e estado
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;
    final LinearGradient statusGradient;

    if (widget.metrics.isSobrecarregado) {
      statusColor = const Color(0xFFEF4444);
      statusLabel = 'SOBRECARGA';
      statusIcon = LucideIcons.alertOctagon;
      statusGradient = const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      );
    } else if (widget.metrics.isAtencao) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'ALTA CARGA';
      statusIcon = LucideIcons.alertTriangle;
      statusGradient = const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      );
    } else {
      statusColor = const Color(0xFF10B981);
      statusLabel = 'OPERANDO BEM';
      statusIcon = LucideIcons.checkCircle;
      statusGradient = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -5.0, 0.0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF131D2E),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF9FAFB),
                  ],
          ),
          border: Border.all(
            color: widget.isSelected
                ? const Color(0xFF2563EB)
                : widget.metrics.isSobrecarregado
                    ? const Color(0xFFEF4444).withValues(alpha: 0.7)
                    : _isHovered
                        ? const Color(0xFF2563EB).withValues(alpha: 0.5)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : const Color(0xFFE2E8F0)),
            width: widget.isSelected || widget.metrics.isSobrecarregado || _isHovered ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.metrics.isSobrecarregado
                  ? const Color(0xFFEF4444).withValues(alpha: _isHovered ? 0.25 : 0.12)
                  : _isHovered
                      ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.25 : 0.12)
                      : Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: _isHovered ? 20 : 12,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onInspecionar,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Topo: Avatar + Nome + Pulso Sonar + Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: statusGradient,
                            ),
                            child: CircleAvatar(
                              radius: 23,
                              backgroundColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              backgroundImage: f.fotoUrl != null && f.fotoUrl!.isNotEmpty
                                  ? NetworkImage(f.fotoUrl!)
                                  : null,
                              child: f.fotoUrl == null || f.fotoUrl!.isEmpty
                                  ? Text(
                                      f.nome.isNotEmpty
                                          ? f.nome.substring(0, min(2, f.nome.length)).toUpperCase()
                                          : 'AT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
                                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: -6,
                            bottom: -6,
                            child: PulsingStatusDot(
                              color: statusColor,
                              size: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    f.nome,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      letterSpacing: -0.2,
                                      color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.metrics.totalVipCards > 0) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.star, size: 9, color: Colors.white),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${widget.metrics.totalVipCards} VIP',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              f.cargo ?? 'Vendedor Comercial',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: isDark ? 0.16 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 4.5),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Barra de Capacidade Segmentada (Estilo Cockpit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(LucideIcons.gauge, size: 13, color: statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Carga Operacional',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.grey[300] : SigeColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${widget.metrics.totalAtivos} / ${widget.metrics.capacidadeMaxima} slots'
                                '${widget.metrics.excessoCards > 0 ? " (+${widget.metrics.excessoCards} transbordo)" : ""}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SegmentedCapacityBar(
                          totalAtivos: widget.metrics.totalAtivos,
                          capacidadeMaxima: widget.metrics.capacidadeMaxima,
                          isSobrecarregado: widget.metrics.isSobrecarregado,
                          statusColor: statusColor,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Grid de Telemetria Interna: TMR Médio e Pipeline
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricPill(
                          icon: LucideIcons.timer,
                          label: 'TMR Médio',
                          value: AtendimentoMetricsHelper.formatarMinutosTempo(widget.metrics.tmrMedioMinutos),
                          accentColor: widget.metrics.tmrMedioMinutos > 10
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF3B82F6),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricPill(
                          icon: LucideIcons.wallet,
                          label: 'Pipeline Cotação',
                          value: faturamentoFormatado,
                          accentColor: const Color(0xFF10B981),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),

                  // Alerta de Vácuo (Se houver)
                  if (widget.metrics.cardsEmVacuo.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFEF4444).withValues(alpha: 0.15),
                            const Color(0xFFDC2626).withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.flame, size: 14, color: Color(0xFFEF4444)),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              '${widget.metrics.cardsEmVacuo.length} cliente(s) no vácuo (> SLA)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Botões de Ação com Elevação Suave
                  Row(
                    children: [
                      if (widget.metrics.totalAtivos > 0)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: widget.metrics.isSobrecarregado
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: widget.onDesafogar,
                              icon: const Icon(LucideIcons.zap, size: 13),
                              label: Text(
                                widget.metrics.isSobrecarregado ? 'Desafogar Já' : 'Aliviar',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.metrics.isSobrecarregado
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF2563EB).withValues(alpha: 0.12),
                                foregroundColor: widget.metrics.isSobrecarregado
                                    ? Colors.white
                                    : const Color(0xFF2563EB),
                                elevation: widget.metrics.isSobrecarregado ? 2 : 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.metrics.totalAtivos > 0) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onInspecionar,
                          icon: const Icon(LucideIcons.scanEye, size: 13),
                          label: const Text(
                            'Inspecionar',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.white,
                            foregroundColor: isDark ? Colors.white : SigeColors.lightTextPrimary,
                            side: BorderSide(
                              color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: accentColor),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : SigeColors.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

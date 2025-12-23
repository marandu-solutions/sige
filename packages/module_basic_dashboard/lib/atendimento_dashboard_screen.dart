import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AtendimentoDashboardScreen extends StatefulWidget {
  const AtendimentoDashboardScreen({super.key});

  @override
  State<AtendimentoDashboardScreen> createState() =>
      _AtendimentoDashboardScreenState();
}

class _AtendimentoDashboardScreenState
    extends State<AtendimentoDashboardScreen> {
  // Mock Data
  int _touchedIndex = -1;

  final List<
      ({
        String name,
        double value,
        Color color,
        IconData icon,
        String? assetIcon
      })> _leadOrigins = [
    (
      name: 'WhatsApp',
      value: 45,
      color: const Color(0xFF25D366),
      icon: LucideIcons.messageCircle,
      assetIcon: null
    ),
    (
      name: 'Instagram',
      value: 25,
      color: const Color(0xFFE1306C),
      icon: LucideIcons.instagram,
      assetIcon: null
    ),
    (
      name: 'TikTok',
      value: 15,
      color: Colors.black,
      icon: LucideIcons.music,
      assetIcon: 'packages/module_basic_dashboard/assets/icons/tiktok.png'
    ),
    (
      name: 'Site',
      value: 10,
      color: Colors.blue,
      icon: LucideIcons.globe,
      assetIcon: null
    ),
    (
      name: 'Outros',
      value: 5,
      color: Colors.grey,
      icon: LucideIcons.moreHorizontal,
      assetIcon: null
    ),
  ];

  String _selectedPeriod = 'Últimos 30 dias';
  final List<String> _periods = [
    'Hoje',
    'Últimos 7 dias',
    'Últimos 30 dias',
    'Este ano'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildKPIRow(theme),
            const SizedBox(height: 24),
            _buildChartsRow(theme),
            const SizedBox(height: 24),
            _buildSecondaryChartsRow(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard de Atendimento',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Visão geral do desempenho omnichanel',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPeriod,
              items: _periods.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: GoogleFonts.inter(fontSize: 14)),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    // _selectedPeriod = newValue; // Read-only for mock
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKPIRow(ThemeData theme) {
    final kpis = [
      (
        title: 'Total de Leads',
        value: '1,248',
        change: '+12.5%',
        isPositive: true,
        icon: LucideIcons.users,
        color: Colors.blue
      ),
      (
        title: 'Vendas Convertidas',
        value: '186',
        change: '+5.2%',
        isPositive: true,
        icon: LucideIcons.shoppingBag,
        color: Colors.green
      ),
      (
        title: 'Tempo Médio Resposta',
        value: '4m 12s',
        change: '-8.4%',
        isPositive: true,
        icon: LucideIcons.clock,
        color: Colors.orange
      ),
      (
        title: 'Satisfação (CSAT)',
        value: '4.8/5',
        change: '+0.1',
        isPositive: true,
        icon: LucideIcons.smile,
        color: Colors.purple
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildKPICardFromData(theme, kpis[0])),
                const SizedBox(width: 16),
                Expanded(child: _buildKPICardFromData(theme, kpis[1])),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildKPICardFromData(theme, kpis[2])),
                const SizedBox(width: 16),
                Expanded(child: _buildKPICardFromData(theme, kpis[3])),
              ],
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: _buildKPICardFromData(theme, kpis[0])),
          const SizedBox(width: 16),
          Expanded(child: _buildKPICardFromData(theme, kpis[1])),
          const SizedBox(width: 16),
          Expanded(child: _buildKPICardFromData(theme, kpis[2])),
          const SizedBox(width: 16),
          Expanded(child: _buildKPICardFromData(theme, kpis[3])),
        ],
      );
    });
  }

  Widget _buildKPICardFromData(ThemeData theme, dynamic data) {
    return _buildKPICard(
      theme,
      title: data.title,
      value: data.value,
      change: data.change,
      isPositive: data.isPositive,
      icon: data.icon,
      color: data.color,
    );
  }

  Widget _buildKPICard(
    ThemeData theme, {
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 14,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsRow(ThemeData theme) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 1000) {
        return Column(
          children: [
            _buildSalesOverTimeChart(theme),
            const SizedBox(height: 24),
            _buildLeadOriginChart(theme),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildSalesOverTimeChart(theme),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: _buildLeadOriginChart(theme),
          ),
        ],
      );
    });
  }

  Widget _buildSecondaryChartsRow(ThemeData theme) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 1000) {
        return Column(
          children: [
            _buildResponseTimeByChannelChart(theme),
            const SizedBox(height: 24),
            _buildAgentPerformanceList(theme),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildResponseTimeByChannelChart(theme),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildAgentPerformanceList(theme),
          ),
        ],
      );
    });
  }

  Widget _buildSalesOverTimeChart(ThemeData theme) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Text(
                'Volume de Leads vs Vendas',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  _buildLegendItem(Colors.blueAccent, 'Leads'),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.greenAccent, 'Vendas'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = [
                          'Seg',
                          'Ter',
                          'Qua',
                          'Qui',
                          'Sex',
                          'Sáb',
                          'Dom'
                        ];
                        if (value.toInt() < 0 ||
                            value.toInt() >= titles.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            titles[value.toInt()],
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeGroupData(0, 45, 12),
                  _makeGroupData(1, 60, 18),
                  _makeGroupData(2, 55, 15),
                  _makeGroupData(3, 70, 22),
                  _makeGroupData(4, 85, 28),
                  _makeGroupData(5, 40, 10),
                  _makeGroupData(6, 35, 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: Colors.blueAccent,
          width: 12,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: y2,
          color: Colors.greenAccent,
          width: 12,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildLeadOriginChart(ThemeData theme) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Text(
                'Origem dos Leads',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.moreHorizontal, size: 20),
                onPressed: () {},
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: _showingSections(theme),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _touchedIndex != -1
                          ? '${_leadOrigins[_touchedIndex].value.toInt()}%'
                          : '100%',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _touchedIndex != -1
                          ? _leadOrigins[_touchedIndex].name
                          : 'Total',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _leadOrigins.map((origin) {
              return _buildLegendItem(origin.color, origin.name);
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _showingSections(ThemeData theme) {
    return List.generate(_leadOrigins.length, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 20.0 : 14.0;
      final radius = isTouched ? 70.0 : 60.0;
      final widgetSize = isTouched ? 45.0 : 35.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      final origin = _leadOrigins[i];

      return PieChartSectionData(
        color: origin.color,
        value: origin.value,
        title: '${origin.value.toInt()}%',
        radius: radius,
        titleStyle: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: shadows,
        ),
        badgeWidget: _Badge(
          origin.icon,
          assetIcon: origin.assetIcon,
          size: widgetSize,
          borderColor: origin.color,
          backgroundColor: theme.cardColor,
        ),
        badgePositionPercentageOffset: .98,
      );
    });
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildResponseTimeByChannelChart(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tempo Médio de Resposta por Canal (min)',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = [
                          'WhatsApp',
                          'Instagram',
                          'TikTok',
                          'Site',
                          'Email'
                        ];
                        if (value.toInt() < 0 ||
                            value.toInt() >= titles.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            titles[value.toInt()],
                            style: GoogleFonts.inter(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(x: 0, barRods: [
                    BarChartRodData(
                        toY: 2, color: const Color(0xFF25D366), width: 20)
                  ]),
                  BarChartGroupData(x: 1, barRods: [
                    BarChartRodData(
                        toY: 15, color: const Color(0xFFE1306C), width: 20)
                  ]),
                  BarChartGroupData(x: 2, barRods: [
                    BarChartRodData(
                        toY: 12, color: const Color(0xFF000000), width: 20)
                  ]),
                  BarChartGroupData(x: 3, barRods: [
                    BarChartRodData(toY: 5, color: Colors.blue, width: 20)
                  ]),
                  BarChartGroupData(x: 4, barRods: [
                    BarChartRodData(toY: 18, color: Colors.orange, width: 20)
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentPerformanceList(ThemeData theme) {
    final agents = [
      {
        'name': 'Ana Silva',
        'leads': 145,
        'conversion': '18%',
        'rating': 4.9,
        'avatar': 'https://i.pravatar.cc/150?u=1'
      },
      {
        'name': 'Carlos Souza',
        'leads': 120,
        'conversion': '15%',
        'rating': 4.7,
        'avatar': 'https://i.pravatar.cc/150?u=2'
      },
      {
        'name': 'Beatriz Costa',
        'leads': 98,
        'conversion': '22%',
        'rating': 4.8,
        'avatar': 'https://i.pravatar.cc/150?u=3'
      },
      {
        'name': 'João Pedro',
        'leads': 85,
        'conversion': '12%',
        'rating': 4.5,
        'avatar': 'https://i.pravatar.cc/150?u=4'
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Text(
                'Desempenho da Equipe',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: agents.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final agent = agents[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(agent['avatar'] as String),
                ),
                title: Text(
                  agent['name'] as String,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${agent['leads']} atendimentos',
                  style: GoogleFonts.inter(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Conv: ${agent['conversion']}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          agent['rating'].toString(),
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.icon, {
    this.assetIcon,
    required this.size,
    required this.borderColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final String? assetIcon;
  final double size;
  final Color borderColor;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: Center(
        child: assetIcon != null
            ? Image.asset(
                assetIcon!,
                width: size * 0.6,
                height: size * 0.6,
                color: borderColor == Colors.black ? null : borderColor,
              )
            : Icon(
                icon,
                size: size * 0.6,
                color: borderColor,
              ),
      ),
    );
  }
}

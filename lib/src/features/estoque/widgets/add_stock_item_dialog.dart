import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/sige_colors.dart';
import '../models/stock_item_model.dart';
import '../providers/stock_provider.dart';

/// Modal Moderno, Lindo e Impactante para Criação e Edição de Insumos & EPIs Homologados (NR-06)
/// Refatorado pela UX Designer Sally (BMad UX) com:
/// - Header dinâmico com avatar que reage à classificação de EPI
/// - Navegador em pílula customizado com micro-animação
/// - Calculadora de margem de lucro e markup em tempo real
/// - Gerador inteligente de SKU automático com 1 clique
/// - Seletor visual de situação de CA e tipos de proteção com chips temáticos
/// - Régua visual da automação de pós-venda NR-06 (WhatsApp D-30, D-15 e D-0)
/// - Compatibilidade total com temas Claro e Escuro sem conflito de contraste
class AddStockItemDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final StockItemModel? item;
  final void Function(StockItemModel)? onSave;

  const AddStockItemDialog({
    super.key,
    required this.tenantId,
    this.item,
    this.onSave,
  });

  @override
  ConsumerState<AddStockItemDialog> createState() => _AddStockItemDialogState();
}

class _AddStockItemDialogState extends ConsumerState<AddStockItemDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // Controladores Gerais
  late TextEditingController _nomeController;
  late TextEditingController _skuController;
  late TextEditingController _categoriaController;
  late TextEditingController _eanController;
  late TextEditingController _quantidadeController;
  late TextEditingController _unidadeController;
  late TextEditingController _precoCustoController;
  late TextEditingController _precoVendaController;
  late TextEditingController _nivelAlertaController;
  late TextEditingController _localizacaoController;

  // Controladores EPI
  bool _isEpi = false;
  late TextEditingController _caNumeroController;
  DateTime? _caValidade;
  String _caSituacao = 'VALIDO';
  late TextEditingController _diasVidaUtilController;
  late TextEditingController _tipoProtecaoController;
  late TextEditingController _fabricanteController;
  late TextEditingController _normasController;

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  final List<String> _unidades = [
    'UN',
    'PAR',
    'KG',
    'LT',
    'MT',
    'CX',
    'PACOTE',
    'CJ'
  ];

  final List<Map<String, dynamic>> _categoriasConfig = [
    {'nome': 'EPIs', 'icon': Icons.verified_user_rounded},
    {'nome': 'Proteção Auditiva', 'icon': Icons.hearing_rounded},
    {'nome': 'Proteção Respiratória', 'icon': Icons.masks_rounded},
    {'nome': 'Proteção Ocular', 'icon': Icons.visibility_rounded},
    {'nome': 'Proteção de Membros Superiores (Luvas)', 'icon': Icons.front_hand_rounded},
    {'nome': 'Proteção de Membros Inferiores (Calçados)', 'icon': Icons.roller_skating_rounded},
    {'nome': 'Trabalho em Altura', 'icon': Icons.paragliding_rounded},
    {'nome': 'Vestimentas e Uniformes', 'icon': Icons.checkroom_rounded},
    {'nome': 'Ferramentas & Insumos', 'icon': Icons.build_rounded},
    {'nome': 'Geral', 'icon': Icons.inventory_2_rounded},
  ];

  final List<Map<String, dynamic>> _tiposProtecaoChips = [
    {'label': 'Auditiva', 'icon': Icons.hearing_rounded},
    {'label': 'Respiratória', 'icon': Icons.masks_rounded},
    {'label': 'Visual e Facial', 'icon': Icons.visibility_rounded},
    {'label': 'Cabeça (Capacetes)', 'icon': Icons.sports_motorsports_rounded},
    {'label': 'Mãos e Braços (Luvas)', 'icon': Icons.front_hand_rounded},
    {'label': 'Pés e Pernas (Calçados)', 'icon': Icons.directions_walk_rounded},
    {'label': 'Contra Quedas (Altura)', 'icon': Icons.paragliding_rounded},
    {'label': 'Tronco e Corpo Inteiro', 'icon': Icons.accessibility_new_rounded},
  ];

  final List<String> _fabricantesPopulares = [
    '3M',
    'Delta Plus',
    'Kalipso',
    'Danny',
    'Volk',
    'Fujiwara',
    'Marluvas',
    'MSA',
  ];

  final List<String> _normasSugeridas = [
    'NR-06',
    'ABNT NBR 16076',
    'ANSI S12.6',
    'NBR 13698',
    'EN 388',
    'CA Ativo MTE',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    final i = widget.item;

    _nomeController = TextEditingController(text: i?.nomeProduto ?? '');
    _skuController = TextEditingController(text: i?.sku ?? '');
    _categoriaController =
        TextEditingController(text: i?.categoria ?? 'EPIs');
    _eanController = TextEditingController(text: i?.codigoBarrasEan ?? '');
    _quantidadeController =
        TextEditingController(text: i != null ? i.qtdAtual.toString() : '0');
    _unidadeController =
        TextEditingController(text: i?.unidadeMedida ?? 'UN');
    _precoCustoController = TextEditingController(
        text: i != null && i.precoCusto > 0
            ? i.precoCusto.toStringAsFixed(2).replaceAll('.', ',')
            : '');
    _precoVendaController = TextEditingController(
        text: i != null && i.precoVenda > 0
            ? i.precoVenda.toStringAsFixed(2).replaceAll('.', ',')
            : '');
    _nivelAlertaController = TextEditingController(
        text: i != null ? i.nivelAlerta.toStringAsFixed(0) : '10');
    _localizacaoController = TextEditingController(text: i?.localizacao ?? '');

    // EPI init
    _isEpi = i?.isEpi ?? true;
    _caNumeroController = TextEditingController(text: i?.caNumero ?? '');
    _caValidade = i?.caValidade;
    _caSituacao = i?.caSituacao ?? 'VALIDO';
    _diasVidaUtilController = TextEditingController(
        text: i?.diasVidaUtilUso != null ? i!.diasVidaUtilUso.toString() : '180');
    _tipoProtecaoController =
        TextEditingController(text: i?.tipoProtecao ?? 'Auditiva');
    _fabricanteController = TextEditingController(text: i?.fabricante ?? '');
    _normasController =
        TextEditingController(text: i?.normasAtendidas.isNotEmpty == true
            ? i!.normasAtendidas.join(', ')
            : 'NR-06');

    // Listeners para recálculo de margem em tempo real
    _precoCustoController.addListener(_onPriceChanged);
    _precoVendaController.addListener(_onPriceChanged);
  }

  void _onPriceChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _precoCustoController.removeListener(_onPriceChanged);
    _precoVendaController.removeListener(_onPriceChanged);
    _nomeController.dispose();
    _skuController.dispose();
    _categoriaController.dispose();
    _eanController.dispose();
    _quantidadeController.dispose();
    _unidadeController.dispose();
    _precoCustoController.dispose();
    _precoVendaController.dispose();
    _nivelAlertaController.dispose();
    _localizacaoController.dispose();
    _caNumeroController.dispose();
    _diasVidaUtilController.dispose();
    _tipoProtecaoController.dispose();
    _fabricanteController.dispose();
    _normasController.dispose();
    super.dispose();
  }

  /// Gera um SKU profissional automaticamente com base no nome e categoria
  void _autoGenerateSku() {
    final prefix = _isEpi ? 'EPI' : 'INS';
    String catCode = 'GER';
    final cat = _categoriaController.text.toUpperCase();
    if (cat.contains('AUDITIV')) {
      catCode = 'AUD';
    } else if (cat.contains('RESPIR')) {
      catCode = 'RESP';
    } else if (cat.contains('OCUL') || cat.contains('VISUAL')) {
      catCode = 'OCUL';
    } else if (cat.contains('LUV') || cat.contains('MEMBROS SUP')) {
      catCode = 'LUV';
    } else if (cat.contains('CALC') || cat.contains('PES')) {
      catCode = 'BOT';
    } else if (cat.contains('ALTURA')) {
      catCode = 'ALT';
    } else if (cat.contains('UNIFORM')) {
      catCode = 'VEST';
    } else if (cat.contains('FERRAM')) {
      catCode = 'FERR';
    }

    final rand = Random().nextInt(900) + 100;
    final generated = '$prefix-$catCode-$rand';

    setState(() {
      _skuController.text = generated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('SKU gerado: $generated'),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: SigeColors.primaryDefault,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Incrementa ou decrementa a quantidade com animação
  void _stepQuantity(double delta) {
    final current =
        double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ?? 0.0;
    final next = (current + delta).clamp(0.0, 999999.0);
    setState(() {
      _quantidadeController.text =
          next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
    });
  }

  Future<void> _pickCaValidade() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _caValidade ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2045),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: SigeColors.primaryDefault,
              primary: SigeColors.primaryDefault,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _caValidade = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      if (_nomeController.text.trim().isEmpty ||
          _skuController.text.trim().isEmpty) {
        _tabController.animateTo(0);
      }
      return;
    }

    final double qtd = double.tryParse(_quantidadeController.text) ?? 0.0;
    final double precoCusto = double.tryParse(
            _precoCustoController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;
    final double precoVenda = double.tryParse(
            _precoVendaController.text.replaceAll('.', '').replaceAll(',', '.')) ??
        0.0;
    final double alerta =
        double.tryParse(_nivelAlertaController.text) ?? 5.0;
    final int? diasVida = int.tryParse(_diasVidaUtilController.text);

    List<String> normas = [];
    if (_normasController.text.trim().isNotEmpty) {
      normas = _normasController.text
          .split(',')
          .map((n) => n.trim())
          .where((n) => n.isNotEmpty)
          .toList();
    }

    final savedItem = StockItemModel(
      id: widget.item?.id ?? '',
      tenantId: widget.tenantId,
      nomeProduto: _nomeController.text.trim(),
      sku: _skuController.text.trim(),
      qtdAtual: qtd,
      unidadeMedida: _unidadeController.text.trim().toUpperCase(),
      precoVenda: precoVenda,
      precoCusto: precoCusto,
      nivelAlerta: alerta,
      estoqueMinimo: alerta,
      categoria: _categoriaController.text.trim(),
      codigoBarrasEan: _eanController.text.trim().isEmpty
          ? null
          : _eanController.text.trim(),
      localizacao: _localizacaoController.text.trim().isEmpty
          ? null
          : _localizacaoController.text.trim(),
      isEpi: _isEpi,
      caNumero: _isEpi && _caNumeroController.text.trim().isNotEmpty
          ? _caNumeroController.text.trim()
          : null,
      caValidade: _isEpi ? _caValidade : null,
      caSituacao: _caSituacao,
      normasAtendidas: _isEpi ? normas : [],
      diasVidaUtilUso: _isEpi ? diasVida : null,
      fabricante: _isEpi && _fabricanteController.text.trim().isNotEmpty
          ? _fabricanteController.text.trim()
          : null,
      tipoProtecao: _isEpi && _tipoProtecaoController.text.trim().isNotEmpty
          ? _tipoProtecaoController.text.trim()
          : null,
      criadoEm: widget.item?.criadoEm ?? DateTime.now(),
      atualizadoEm: DateTime.now(),
    );

    final notifier = ref.read(stockProvider(widget.tenantId).notifier);
    if (widget.item == null || widget.item!.id.isEmpty) {
      notifier.addItem(savedItem);
    } else {
      notifier.updateItem(savedItem);
    }

    if (widget.onSave != null) {
      widget.onSave!(savedItem);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.item != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          width: 720,
          constraints: const BoxConstraints(maxHeight: 780),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2230) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : SigeColors.primaryDefault.withValues(alpha: 0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.22),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              children: [
                // Header Enriquecido e Dinâmico
                _buildHeader(isDark, isEdit),

                // Seletor em Pílula (Segmented Pill Controller)
                _buildSegmentedTabSelector(isDark),

                // Form Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGeneralTab(isDark),
                        _buildEpiTab(isDark),
                      ],
                    ),
                  ),
                ),

                // Rodapé Moderno com Ações e Destaque
                _buildFooter(isDark, isEdit),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // HEADER
  // =========================================================================
  Widget _buildHeader(bool isDark, bool isEdit) {
    final iconColor = _isEpi ? SigeColors.secondaryDefault : SigeColors.primaryDefault;
    final gradientColors = _isEpi
        ? [const Color(0xFF059669), const Color(0xFF10B981)]
        : [const Color(0xFF3F51B5), const Color(0xFF6366F1)];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161925) : SigeColors.lightBg,
        border: Border(
          bottom: BorderSide(
            color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar Dinâmico com Glow Animado
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _isEpi ? Icons.verified_user_rounded : Icons.inventory_2_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Título e Subtítulo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        isEdit ? 'Editar Insumo / EPI' : 'Novo Insumo & EPI Homologado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: isDark
                              ? SigeColors.darkTextPrimary
                              : SigeColors.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Badge de Classificação Atual
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isEpi
                            ? SigeColors.secondaryDefault.withValues(alpha: 0.15)
                            : SigeColors.primaryDefault.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isEpi
                              ? SigeColors.secondaryDefault.withValues(alpha: 0.4)
                              : SigeColors.primaryDefault.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isEpi
                                ? Icons.shield_rounded
                                : Icons.category_rounded,
                            size: 13,
                            color: _isEpi
                                ? SigeColors.secondaryDefault
                                : SigeColors.primaryDefault,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _isEpi ? 'EPI NR-06' : 'Insumo Geral',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isEpi
                                  ? SigeColors.secondaryDefault
                                  : SigeColors.primaryDefault,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  isEdit
                      ? 'Atualize parâmetros comerciais, níveis de reposição ou certificação'
                      : 'Cadastre dados comerciais, controle de estoque e conformidade NR-06',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark
                        ? SigeColors.darkTextSecondary
                        : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Botão Fechar Estilizado
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark
                      ? SigeColors.darkTextSecondary
                      : SigeColors.lightTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // NAVEGADOR EM PÍLULA (SEGMENTED TABS)
  // =========================================================================
  Widget _buildSegmentedTabSelector(bool isDark) {
    final currentIndex = _tabController.index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2230) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? SigeColors.darkBorder.withValues(alpha: 0.6)
                : SigeColors.lightBorder,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131622) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? SigeColors.darkBorder : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            // Aba 1: Geral & Comercial
            Expanded(
              child: _buildTabPillItem(
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.tune_rounded,
                title: '1. Geral & Comercial',
                badgeText: _nomeController.text.isNotEmpty &&
                        _skuController.text.isNotEmpty
                    ? 'OK'
                    : null,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 6),
            // Aba 2: Homologação EPI (NR-06)
            Expanded(
              child: _buildTabPillItem(
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.verified_user_rounded,
                title: '2. Homologação EPI (NR-06)',
                badgeText: _isEpi ? 'ATIVO' : 'OPCIONAL',
                isBadgeAccent: _isEpi,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPillItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String title,
    String? badgeText,
    bool isBadgeAccent = false,
    required bool isDark,
  }) {
    final isSelected = index == currentIndex;

    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? SigeColors.primaryDefault : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: isDark
                        ? SigeColors.primaryDefault.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? Colors.white : SigeColors.primaryDefault)
                  : (isDark
                      ? SigeColors.darkTextSecondary
                      : SigeColors.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? (isDark ? Colors.white : SigeColors.primaryDefault)
                      : (isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isBadgeAccent
                      ? (isSelected
                          ? Colors.white.withValues(alpha: 0.25)
                          : SigeColors.secondaryDefault.withValues(alpha: 0.18))
                      : (isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06))),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: isBadgeAccent
                        ? (isSelected ? Colors.white : SigeColors.secondaryDefault)
                        : (isSelected
                            ? (isDark ? Colors.white : SigeColors.primaryDefault)
                            : (isDark
                                ? SigeColors.darkTextMuted
                                : SigeColors.lightTextSecondary)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ABA 1: GERAL & COMERCIAL
  // =========================================================================
  Widget _buildGeneralTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campo: Nome do Produto
          TextFormField(
            controller: _nomeController,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : SigeColors.lightTextPrimary,
            ),
            decoration: _inputDecor(
              label: 'Nome do Produto / Insumo / EPI *',
              hint: 'Ex: Protetor Auditivo Plug Silicone 16dB em Caixa',
              icon: Icons.drive_file_rename_outline_rounded,
              isDark: isDark,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'O nome do produto é obrigatório' : null,
          ),
          const SizedBox(height: 18),

          // SKU & EAN com Auto-Gerador com 1 clique
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: TextFormField(
                  controller: _skuController,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  ),
                  decoration: _inputDecor(
                    label: 'SKU / Código Interno *',
                    hint: 'Ex: EPI-AUD-492',
                    icon: Icons.qr_code_2_rounded,
                    isDark: isDark,
                    suffixIcon: Tooltip(
                      message: 'Gerar código SKU automático',
                      child: IconButton(
                        icon: const Icon(
                          Icons.auto_awesome_rounded,
                          color: SigeColors.primaryDefault,
                          size: 20,
                        ),
                        onPressed: _autoGenerateSku,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'SKU é obrigatório' : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _eanController,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  ),
                  decoration: _inputDecor(
                    label: 'Código EAN / Barras',
                    hint: '7891234567890',
                    icon: Icons.view_week_outlined,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Categoria & Unidade de Medida com Dropdowns Modernos
          Row(
            children: [
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  initialValue: _categoriasConfig.any(
                          (c) => c['nome'] == _categoriaController.text)
                      ? _categoriaController.text
                      : _categoriasConfig.first['nome'] as String,
                  dropdownColor:
                      isDark ? const Color(0xFF1E2230) : Colors.white,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  ),
                  decoration: _inputDecor(
                    label: 'Categoria do Item',
                    icon: Icons.category_rounded,
                    isDark: isDark,
                  ),
                  items: _categoriasConfig.map((cat) {
                    final String nome = cat['nome'];
                    final IconData iconData = cat['icon'];
                    return DropdownMenuItem<String>(
                      value: nome,
                      child: Row(
                        children: [
                          Icon(iconData, size: 17, color: SigeColors.primaryDefault),
                          const SizedBox(width: 8),
                          Text(nome, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _categoriaController.text = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _unidades.contains(_unidadeController.text)
                      ? _unidadeController.text
                      : _unidades.first,
                  dropdownColor:
                      isDark ? const Color(0xFF1E2230) : Colors.white,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  ),
                  decoration: _inputDecor(
                    label: 'Unidade',
                    icon: Icons.straighten_rounded,
                    isDark: isDark,
                  ),
                  items: _unidades
                      .map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _unidadeController.text = val;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quantidade Inicial & Nível de Alerta (Estoque de Segurança)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _quantidadeController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                      ),
                      decoration: _inputDecor(
                        label: 'Quantidade Inicial *',
                        hint: '0',
                        icon: Icons.tag_rounded,
                        isDark: isDark,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                              onPressed: () => _stepQuantity(-1),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              onPressed: () => _stepQuantity(1),
                            ),
                          ],
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe a qtd';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    // Atalhos Rápidos de Qtd
                    Wrap(
                      spacing: 6,
                      children: [10, 50, 100].map((step) {
                        return InkWell(
                          onTap: () => _stepQuantity(step.toDouble()),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+$step',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? SigeColors.darkTextSecondary
                                    : SigeColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nivelAlertaController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                      ),
                      decoration: _inputDecor(
                        label: 'Estoque Mínimo (Alerta) *',
                        hint: '10',
                        icon: Icons.warning_amber_rounded,
                        isDark: isDark,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Informe o alerta';
                        if (double.tryParse(v) == null) return 'Inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dispara aviso no painel quando atingir este patamar',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? SigeColors.darkTextMuted
                            : SigeColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Estrutura de Preços (Custo e Venda)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _precoCustoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  ),
                  decoration: _inputDecor(
                    label: 'Preço de Custo (R\$)',
                    hint: '0,00',
                    icon: Icons.shopping_bag_outlined,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _precoVendaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  ),
                  decoration: _inputDecor(
                    label: 'Preço de Venda (R\$)',
                    hint: '0,00',
                    icon: Icons.monetization_on_outlined,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),

          // Calculadora de Lucro e Margem em Tempo Real (Live Profit Strip)
          _buildLiveProfitStrip(isDark),
          const SizedBox(height: 18),

          // Localização no Almoxarifado / Prateleira (Opcional)
          TextFormField(
            controller: _localizacaoController,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : SigeColors.lightTextPrimary,
            ),
            decoration: _inputDecor(
              label: 'Localização no Almoxarifado (Opcional)',
              hint: 'Ex: Corredor B, Prateleira 03, Caixa 12',
              icon: Icons.warehouse_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 22),

          // Card Hero: Classificação EPI (NR-06)
          _buildEpiHeroToggleCard(isDark),
        ],
      ),
    );
  }

  // =========================================================================
  // CALCULADORA DE MARGEM EM TEMPO REAL
  // =========================================================================
  Widget _buildLiveProfitStrip(bool isDark) {
    final custo = double.tryParse(_precoCustoController.text
            .replaceAll('.', '')
            .replaceAll(',', '.')) ??
        0.0;
    final venda = double.tryParse(_precoVendaController.text
            .replaceAll('.', '')
            .replaceAll(',', '.')) ??
        0.0;

    if (custo <= 0 && venda <= 0) {
      return const SizedBox.shrink();
    }

    final lucro = venda - custo;
    final margemPercent = venda > 0 ? (lucro / venda) * 100 : 0.0;
    final markupPercent = custo > 0 ? (lucro / custo) * 100 : 0.0;

    final isProfit = lucro >= 0;
    final Color badgeColor = isProfit
        ? (margemPercent >= 30
            ? SigeColors.success
            : const Color(0xFFF59E0B))
        : SigeColors.danger;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? badgeColor.withValues(alpha: 0.1)
            : badgeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            color: badgeColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lucro Projetado por Unidade',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? SigeColors.darkTextSecondary
                            : SigeColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      'R\$ ${lucro.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Margem: ${margemPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '|  Markup: ${markupPercent >= 0 ? '+' : ''}${markupPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? SigeColors.darkTextSecondary
                              : SigeColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // CARD HERO: CLASSIFICAÇÃO EPI
  // =========================================================================
  Widget _buildEpiHeroToggleCard(bool isDark) {
    return InkWell(
      onTap: () {
        setState(() {
          _isEpi = !_isEpi;
          if (_isEpi) {
            _tabController.animateTo(1);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: _isEpi
              ? SigeColors.secondaryDefault.withValues(alpha: 0.1)
              : (isDark ? const Color(0xFF161925) : SigeColors.lightBg),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isEpi
                ? SigeColors.secondaryDefault.withValues(alpha: 0.5)
                : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder),
            width: _isEpi ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isEpi
                    ? SigeColors.secondaryDefault.withValues(alpha: 0.2)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isEpi ? Icons.shield_rounded : Icons.shield_outlined,
                color: _isEpi
                    ? SigeColors.secondaryDefault
                    : (isDark
                        ? SigeColors.darkTextSecondary
                        : SigeColors.lightTextSecondary),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Classificar este item como EPI (NR-06)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? SigeColors.darkTextPrimary
                              : SigeColors.lightTextPrimary,
                        ),
                      ),
                      if (_isEpi) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SigeColors.secondaryDefault,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ATIVO',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Habilita rastreio de Certificado de Aprovação (CA), vida útil e régua WhatsApp (D-30, D-15 e D-0)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isEpi,
              activeThumbColor: Colors.white,
              activeTrackColor: SigeColors.secondaryDefault,
              onChanged: (val) {
                setState(() {
                  _isEpi = val;
                  if (val) {
                    _tabController.animateTo(1);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // ABA 2: HOMOLOGAÇÃO EPI (NR-06)
  // =========================================================================
  Widget _buildEpiTab(bool isDark) {
    if (!_isEpi) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : SigeColors.lightBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark
                        ? SigeColors.darkBorder
                        : SigeColors.lightBorder,
                  ),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 42,
                  color: isDark
                      ? SigeColors.darkTextSecondary
                      : SigeColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Classificação NR-06 Desativada',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 440,
                child: Text(
                  'Este produto está registrado como insumo comum. Ative a classificação de EPI para gerenciar Certificado de Aprovação (CA), validade, fabricante homologado e alertas automáticos via WhatsApp.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? SigeColors.darkTextSecondary
                        : SigeColors.lightTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEpi = true;
                  });
                },
                icon: const Icon(Icons.add_moderator_rounded, size: 18),
                label: const Text('Ativar Homologação EPI (NR-06)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SigeColors.secondaryDefault,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Informativo: Régua Preventiva de Pós-Venda
          _buildPreventiveOmnichannelBanner(isDark),
          const SizedBox(height: 20),

          // Número do CA & Situação do CA
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _caNumeroController,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                  ),
                  decoration: _inputDecor(
                    label: 'Número do CA (MTE) *',
                    hint: 'Ex: 41234',
                    icon: Icons.badge_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) {
                    if (_isEpi && (v == null || v.trim().isEmpty)) {
                      return 'Número do CA é obrigatório para EPI';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Situação do Certificado (MTE)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? SigeColors.darkTextSecondary
                            : SigeColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Seletor em Pílulas Visuais de Situação do CA
                    _buildCaStatusSelector(isDark),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Data de Validade do CA & Vida Útil após Entrega
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Validade do CA
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: _pickCaValidade,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF161925)
                              : SigeColors.lightBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? SigeColors.darkBorder
                                : SigeColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 22,
                              color: SigeColors.primaryDefault,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Validade do CA (MTE) *',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? SigeColors.darkTextSecondary
                                          : SigeColors.lightTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _caValidade != null
                                        ? _dateFormat.format(_caValidade!)
                                        : 'Selecione a data...',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: _caValidade != null
                                          ? (isDark
                                              ? Colors.white
                                              : SigeColors.lightTextPrimary)
                                          : (isDark
                                              ? SigeColors.darkTextMuted
                                              : SigeColors.lightTextMuted),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, size: 24),
                          ],
                        ),
                      ),
                    ),
                    if (_caValidade != null) ...[
                      const SizedBox(height: 4),
                      _buildDaysRemainingTag(_caValidade!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Vida Útil após Entrega
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _diasVidaUtilController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                      ),
                      decoration: _inputDecor(
                        label: 'Vida Útil após Entrega (Dias) *',
                        hint: '180',
                        icon: Icons.hourglass_top_rounded,
                        isDark: isDark,
                      ),
                      validator: (v) {
                        if (_isEpi && (v == null || int.tryParse(v) == null)) {
                          return 'Informe os dias de vida útil';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    // Presets de Vida Útil
                    Wrap(
                      spacing: 6,
                      children: [
                        {'label': '30d (Descartável)', 'val': '30'},
                        {'label': '90d', 'val': '90'},
                        {'label': '180d (Semestral)', 'val': '180'},
                        {'label': '365d (Anual)', 'val': '365'},
                      ].map((preset) {
                        final isSelected =
                            _diasVidaUtilController.text == preset['val'];
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _diasVidaUtilController.text = preset['val']!;
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SigeColors.primaryDefault.withValues(alpha: 0.15)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.04)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? SigeColors.primaryDefault
                                    : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              preset['label']!,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? SigeColors.primaryDefault
                                    : (isDark
                                        ? SigeColors.darkTextSecondary
                                        : SigeColors.lightTextSecondary),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Seletor Visual de Tipo de Proteção
          Text(
            'Tipo de Proteção (NR-06)',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? SigeColors.darkTextPrimary
                  : SigeColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildProtectionTypeCloud(isDark),
          const SizedBox(height: 20),

          // Fabricante Homologado com Sugestões Rápidas
          TextFormField(
            controller: _fabricanteController,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : SigeColors.lightTextPrimary,
            ),
            decoration: _inputDecor(
              label: 'Fabricante Homologado',
              hint: 'Ex: 3M do Brasil, Delta Plus, Kalipso',
              icon: Icons.business_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _fabricantesPopulares.map((fab) {
              final isCurrent = _fabricanteController.text == fab;
              return InkWell(
                onTap: () {
                  setState(() {
                    _fabricanteController.text = fab;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? SigeColors.primaryDefault.withValues(alpha: 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent
                          ? SigeColors.primaryDefault
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    fab,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? SigeColors.primaryDefault
                          : (isDark
                              ? SigeColors.darkTextSecondary
                              : SigeColors.lightTextSecondary),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Normas Técnicas Atendidas
          TextFormField(
            controller: _normasController,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : SigeColors.lightTextPrimary,
            ),
            decoration: _inputDecor(
              label: 'Normas Técnicas Atendidas (separadas por vírgula)',
              hint: 'Ex: NR-06, ABNT NBR 16076, ANSI S12.6',
              icon: Icons.gavel_rounded,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _normasSugeridas.map((norma) {
              final alreadyIn = _normasController.text.contains(norma);
              return InkWell(
                onTap: () {
                  setState(() {
                    if (!alreadyIn) {
                      if (_normasController.text.trim().isEmpty) {
                        _normasController.text = norma;
                      } else {
                        _normasController.text =
                            '${_normasController.text.trim()}, $norma';
                      }
                    }
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: alreadyIn
                        ? SigeColors.secondaryDefault.withValues(alpha: 0.15)
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.04)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: alreadyIn
                          ? SigeColors.secondaryDefault
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (alreadyIn) ...[
                        const Icon(Icons.check_rounded,
                            size: 12, color: SigeColors.secondaryDefault),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        norma,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              alreadyIn ? FontWeight.bold : FontWeight.w500,
                          color: alreadyIn
                              ? SigeColors.secondaryDefault
                              : (isDark
                                  ? SigeColors.darkTextSecondary
                                  : SigeColors.lightTextSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BANNER DE RÉGUA PREVENTIVA OMNICHANNEL
  // =========================================================================
  Widget _buildPreventiveOmnichannelBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF0F2B20),
                  const Color(0xFF132035),
                ]
              : [
                  const Color(0xFFECFDF5),
                  const Color(0xFFEFF6FF),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFF10B981).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SigeColors.secondaryDefault.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: SigeColors.secondaryDefault,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Régua Preventiva de Pós-Venda NR-06 (WhatsApp & CRM)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      'Alertas automáticos disparados aos clientes e responsáveis de segurança',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? SigeColors.darkTextSecondary
                            : SigeColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Linha do tempo dos disparos automáticos
          Row(
            children: [
              _buildCadencePill(
                  label: 'D-30',
                  desc: 'Aviso de reposição',
                  color: const Color(0xFF3B82F6),
                  isDark: isDark),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              _buildCadencePill(
                  label: 'D-15',
                  desc: 'Troca imediata',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              _buildCadencePill(
                  label: 'D-0',
                  desc: 'Vencimento NR-06',
                  color: SigeColors.danger,
                  isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCadencePill({
    required String label,
    required String desc,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.12)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              desc,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? SigeColors.darkTextSecondary
                    : SigeColors.lightTextSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SELETOR VISUAL DE SITUAÇÃO DO CA
  // =========================================================================
  Widget _buildCaStatusSelector(bool isDark) {
    final statuses = [
      {'val': 'VALIDO', 'label': 'VÁLIDO', 'color': SigeColors.success},
      {'val': 'EM_RENOVACAO', 'label': 'RENOVAÇÃO', 'color': const Color(0xFFF59E0B)},
      {'val': 'VENCIDO', 'label': 'VENCIDO', 'color': SigeColors.danger},
      {'val': 'SUSPENSO', 'label': 'SUSPENSO', 'color': const Color(0xFF64748B)},
    ];

    return Wrap(
      spacing: 6,
      children: statuses.map((item) {
        final isSelected = _caSituacao == item['val'];
        final color = item['color'] as Color;

        return InkWell(
          onTap: () {
            setState(() {
              _caSituacao = item['val'] as String;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? color
                  : (isDark
                      ? const Color(0xFF161925)
                      : SigeColors.lightBg),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? color
                    : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.check_rounded,
                        size: 14, color: Colors.white),
                  ),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? SigeColors.darkTextSecondary
                            : SigeColors.lightTextSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDaysRemainingTag(DateTime date) {
    final diff = date.difference(DateTime.now()).inDays;
    final isExpired = diff < 0;
    final color = isExpired
        ? SigeColors.danger
        : (diff <= 60 ? const Color(0xFFF59E0B) : SigeColors.success);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.error_outline_rounded : Icons.schedule_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'Vencido há ${-diff} dias' : 'Expira em $diff dias',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SELETOR EM NUVEM DE TIPOS DE PROTEÇÃO
  // =========================================================================
  Widget _buildProtectionTypeCloud(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _tiposProtecaoChips.map((chip) {
        final label = chip['label'] as String;
        final icon = chip['icon'] as IconData;
        final isSelected = _tipoProtecaoController.text == label ||
            _tipoProtecaoController.text.contains(label.split(' ').first);

        return InkWell(
          onTap: () {
            setState(() {
              _tipoProtecaoController.text = label;
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? SigeColors.secondaryDefault.withValues(alpha: 0.15)
                  : (isDark
                      ? const Color(0xFF161925)
                      : SigeColors.lightBg),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? SigeColors.secondaryDefault
                    : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? SigeColors.secondaryDefault
                      : (isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : SigeColors.secondaryDefault)
                        : (isDark
                            ? SigeColors.darkTextSecondary
                            : SigeColors.lightTextSecondary),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================================
  // RODAPÉ COM AÇÕES E SALVAMENTO
  // =========================================================================
  Widget _buildFooter(bool isDark, bool isEdit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161925) : SigeColors.lightBg,
        border: Border(
          top: BorderSide(
            color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Botão Cancelar
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 16),
            label: const Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? SigeColors.darkTextSecondary
                  : SigeColors.lightTextSecondary,
              side: BorderSide(
                color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Spacer(),

          // Botão de Avanço Rápido para EPI se estiver na Tab 0
          if (_tabController.index == 0 && _isEpi) ...[
            TextButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Text('Avançar para Homologação'),
              label: const Icon(Icons.arrow_forward_rounded, size: 16),
              style: TextButton.styleFrom(
                foregroundColor: SigeColors.primaryDefault,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Botão Primário Cadastrar / Salvar
          ElevatedButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_circle_rounded, size: 18),
            label: Text(
              isEdit ? 'Salvar Alterações' : 'Cadastrar Item',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEpi
                  ? SigeColors.secondaryDefault
                  : SigeColors.primaryDefault,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              shadowColor: (_isEpi
                      ? SigeColors.secondaryDefault
                      : SigeColors.primaryDefault)
                  .withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // DECORAÇÃO DE INPUT MODERNA E RESPONSIVA
  // =========================================================================
  InputDecoration _inputDecor({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        fontSize: 13,
        color: isDark
            ? SigeColors.darkTextSecondary
            : SigeColors.lightTextSecondary,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
      ),
      prefixIcon: Icon(
        icon,
        size: 19,
        color: isDark
            ? SigeColors.darkTextSecondary
            : SigeColors.lightTextSecondary,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF161925) : SigeColors.lightBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: _isEpi
              ? SigeColors.secondaryDefault
              : SigeColors.primaryDefault,
          width: 1.8,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/sige_colors.dart';
import '../models/stock_item_model.dart';
import '../providers/stock_provider.dart';

/// Modal dialog moderno para criação e edição de insumos e EPIs com homologação NR-06
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

  final List<String> _unidades = ['UN', 'PAR', 'KG', 'LT', 'MT', 'CX', 'PACOTE'];
  final List<String> _categorias = [
    'EPIs',
    'Proteção Auditiva',
    'Proteção Respiratória',
    'Proteção Ocular',
    'Proteção de Membros Superiores (Luvas)',
    'Proteção de Membros Inferiores (Calçados)',
    'Trabalho em Altura',
    'Vestimentas e Uniformes',
    'Ferramentas & Insumos',
    'Geral',
  ];

  final List<String> _tiposProtecao = [
    'Auditiva',
    'Respiratória',
    'Visual e Facial',
    'Cabeça (Capacetes)',
    'Mãos e Braços (Luvas)',
    'Pés e Pernas (Calçados)',
    'Tronco e Corpo Inteiro',
    'Contra Quedas (Altura)',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        TextEditingController(text: i?.normasAtendidas.join(', ') ?? 'NR-06');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _skuController.dispose();
    _categoriaController.dispose();
    _eanController.dispose();
    _quantidadeController.dispose();
    _unidadeController.dispose();
    _precoCustoController.dispose();
    _precoVendaController.dispose();
    _nivelAlertaController.dispose();
    _caNumeroController.dispose();
    _diasVidaUtilController.dispose();
    _tipoProtecaoController.dispose();
    _fabricanteController.dispose();
    _normasController.dispose();
    super.dispose();
  }

  Future<void> _pickCaValidade() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _caValidade ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      setState(() {
        _caValidade = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

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
      child: Container(
        width: 680,
        constraints: const BoxConstraints(maxHeight: 740),
        decoration: BoxDecoration(
          color: isDark ? SigeColors.darkCardBg : SigeColors.lightCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header do Dialog
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkBg : SigeColors.lightBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          SigeColors.primaryDefault,
                          SigeColors.primaryDefault.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Editar Produto / Insumo' : 'Novo Insumo & EPI Homologado',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isEdit
                              ? 'Altere parâmetros de estoque, custos ou certificação'
                              : 'Cadastre dados comerciais, controle de estoque e conformidade NR-06',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? SigeColors.darkTextSecondary
                                : SigeColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: SigeColors.primaryDefault,
              unselectedLabelColor: isDark
                  ? SigeColors.darkTextSecondary
                  : SigeColors.lightTextSecondary,
              indicatorColor: SigeColors.primaryDefault,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.tune_rounded, size: 18),
                  text: '1. Geral & Comercial',
                ),
                Tab(
                  icon: Icon(Icons.verified_user_rounded, size: 18),
                  text: '2. Homologação EPI (NR-06)',
                ),
              ],
            ),

            // Form Body
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

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? SigeColors.darkBg : SigeColors.lightBg,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancelar'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(isEdit ? 'Salvar Alterações' : 'Cadastrar Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SigeColors.primaryDefault,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do Produto
          TextFormField(
            controller: _nomeController,
            decoration: _inputDecor(
              label: 'Nome do Produto / EPI *',
              hint: 'Ex: Protetor Auditivo Plug Silicone 16dB',
              icon: Icons.label_important_outline_rounded,
              isDark: isDark,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nome é obrigatório' : null,
          ),
          const SizedBox(height: 16),

          // SKU & Código de Barras EAN
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _skuController,
                  decoration: _inputDecor(
                    label: 'SKU / Código Interno *',
                    hint: 'Ex: EPI-PROT-001',
                    icon: Icons.qr_code_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'SKU é obrigatório' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _eanController,
                  decoration: _inputDecor(
                    label: 'Código EAN / Barras',
                    hint: 'Ex: 7891234567890',
                    icon: Icons.barcode_reader,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Categoria & Unidade de Medida
          Row(
            children: [
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<String>(
                  value: _categorias.contains(_categoriaController.text)
                      ? _categoriaController.text
                      : _categorias.first,
                  decoration: _inputDecor(
                    label: 'Categoria',
                    icon: Icons.category_rounded,
                    isDark: isDark,
                  ),
                  items: _categorias
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _categoriaController.text = val;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _unidades.contains(_unidadeController.text)
                      ? _unidadeController.text
                      : _unidades.first,
                  decoration: _inputDecor(
                    label: 'Unidade',
                    icon: Icons.straighten_rounded,
                    isDark: isDark,
                  ),
                  items: _unidades
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
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
          const SizedBox(height: 16),

          // Quantidade e Nível de Alerta
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecor(
                    label: 'Quantidade Inicial *',
                    hint: '0',
                    icon: Icons.tag_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe a qtd';
                    if (double.tryParse(v) == null) return 'Inválido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _nivelAlertaController,
                  keyboardType: TextInputType.number,
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
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preços de Custo e Venda
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _precoCustoController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecor(
                    label: 'Preço de Custo (R\$)',
                    hint: '0,00',
                    icon: Icons.shopping_bag_outlined,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _precoVendaController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
          const SizedBox(height: 20),

          // Switch rápido de classificação EPI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _isEpi
                  ? SigeColors.primaryDefault.withValues(alpha: 0.08)
                  : (isDark ? SigeColors.darkBg : SigeColors.lightBg),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isEpi
                    ? SigeColors.primaryDefault.withValues(alpha: 0.4)
                    : (isDark ? SigeColors.darkBorder : SigeColors.lightBorder),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  color: _isEpi
                      ? SigeColors.primaryDefault
                      : (isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Classificar este item como EPI (NR-06)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Habilita rastreio de Certificado de Aprovação (CA), validade e CRM preventivo',
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
                Switch(
                  value: _isEpi,
                  activeTrackColor: SigeColors.primaryDefault,
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
        ],
      ),
    );
  }

  Widget _buildEpiTab(bool isDark) {
    if (!_isEpi) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined,
                  size: 56,
                  color: isDark
                      ? SigeColors.darkTextSecondary
                      : SigeColors.lightTextSecondary),
              const SizedBox(height: 16),
              const Text(
                'Item não configurado como EPI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ative a classificação de EPI na aba "Geral" para preencher o Certificado de Aprovação (CA) e parâmetros da NR-06.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEpi = true;
                  });
                },
                icon: const Icon(Icons.add_moderator_rounded, size: 18),
                label: const Text('Ativar Homologação EPI'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SigeColors.primaryDefault,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Informativo
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: SigeColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SigeColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: SigeColors.info, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Os campos de CA e validade são integrados com a régua preventiva automática de pós-venda via WhatsApp (D-30, D-15 e D-0).',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.blue[200] : Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Número do CA e Situação
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _caNumeroController,
                  decoration: _inputDecor(
                    label: 'Número do CA (MTE) *',
                    hint: 'Ex: 41234',
                    icon: Icons.badge_rounded,
                    isDark: isDark,
                  ),
                  validator: (v) {
                    if (_isEpi && (v == null || v.trim().isEmpty)) {
                      return 'CA é obrigatório para EPI';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _caSituacao,
                  decoration: _inputDecor(
                    label: 'Situação do CA',
                    icon: Icons.shield_rounded,
                    isDark: isDark,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'VALIDO', child: Text('VÁLIDO')),
                    DropdownMenuItem(value: 'VENCIDO', child: Text('VENCIDO')),
                    DropdownMenuItem(value: 'SUSPENSO', child: Text('SUSPENSO')),
                    DropdownMenuItem(
                        value: 'CANCELADO', child: Text('CANCELADO')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _caSituacao = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Validade do CA e Vida Útil
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickCaValidade,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: _inputDecor(
                      label: 'Data de Validade do CA *',
                      icon: Icons.calendar_today_rounded,
                      isDark: isDark,
                    ),
                    child: Text(
                      _caValidade != null
                          ? _dateFormat.format(_caValidade!)
                          : 'Selecione a data...',
                      style: TextStyle(
                        color: _caValidade != null
                            ? (isDark ? Colors.white : Colors.black87)
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _diasVidaUtilController,
                  keyboardType: TextInputType.number,
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
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tipo de Proteção e Fabricante Homologado
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _tiposProtecao.contains(_tipoProtecaoController.text)
                      ? _tipoProtecaoController.text
                      : _tiposProtecao.first,
                  decoration: _inputDecor(
                    label: 'Tipo de Proteção',
                    icon: Icons.health_and_safety_rounded,
                    isDark: isDark,
                  ),
                  items: _tiposProtecao
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _tipoProtecaoController.text = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _fabricanteController,
                  decoration: _inputDecor(
                    label: 'Fabricante Homologado',
                    hint: 'Ex: 3M, Delta Plus, Kalipso',
                    icon: Icons.business_rounded,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Normas Técnicas Atendidas
          TextFormField(
            controller: _normasController,
            decoration: _inputDecor(
              label: 'Normas Técnicas Atendidas (separadas por vírgula)',
              hint: 'Ex: NR-06, ABNT NBR 16076, ANSI S12.6',
              icon: Icons.gavel_rounded,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor({
    required String label,
    String? hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: isDark ? SigeColors.darkBg : SigeColors.lightBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? SigeColors.darkBorder : SigeColors.lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: SigeColors.primaryDefault,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/stock_item_model.dart';
import '../providers/stock_provider.dart';

/// Modal Moderno e Impactante de Movimentação de Estoque & Ficha de Entrega de EPI (Sally UX)
/// Apresenta seletor de movimento enriquecido, cálculo dinâmico de saldo projetado,
/// atalhos de incremento (stepper), régua preventiva NR-06 e alto contraste nos modos claro e escuro.
class StockMovementDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final StockItemModel item;

  const StockMovementDialog({
    super.key,
    required this.tenantId,
    required this.item,
  });

  @override
  ConsumerState<StockMovementDialog> createState() =>
      _StockMovementDialogState();
}

class _StockMovementDialogState extends ConsumerState<StockMovementDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _qtdController = TextEditingController(text: '1');
  final _motivoController = TextEditingController();
  final _loteController = TextEditingController();
  final _clienteNomeController = TextEditingController();
  final _clienteTelefoneController = TextEditingController();
  final _vidaUtilController = TextEditingController();

  String _tipoMovimento = 'ENTRADA';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isEpi) {
      _vidaUtilController.text = '${widget.item.diasVidaUtilUso ?? 60}';
    }
    _qtdController.addListener(() {
      setState(() {});
    });
    _vidaUtilController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _qtdController.dispose();
    _motivoController.dispose();
    _loteController.dispose();
    _clienteNomeController.dispose();
    _clienteTelefoneController.dispose();
    _vidaUtilController.dispose();
    super.dispose();
  }

  void _stepQuantity(double delta) {
    final current =
        double.tryParse(_qtdController.text.replaceAll(',', '.')) ?? 0.0;
    final next = (current + delta).clamp(1.0, 99999.0);
    setState(() {
      _qtdController.text =
          next % 1 == 0 ? next.toInt().toString() : next.toStringAsFixed(1);
    });
  }

  void _setMotivo(String text) {
    setState(() {
      _motivoController.text = text;
    });
  }

  Color _getTipoColor(String tipo) {
    switch (tipo) {
      case 'ENTRADA':
        return SigeColors.success;
      case 'SAIDA_VENDA':
        return const Color(0xFF3B82F6); // Blue
      case 'SAIDA_EPI':
        return const Color(0xFF8B5CF6); // Purple / Violet
      case 'AJUSTE_POSITIVO':
        return const Color(0xFF06B6D4); // Cyan
      case 'AJUSTE_NEGATIVO':
        return const Color(0xFFEF4444); // Danger / Red
      default:
        return SigeColors.primaryDefault;
    }
  }

  bool get _isEntradaOuIncremento =>
      _tipoMovimento == 'ENTRADA' || _tipoMovimento == 'AJUSTE_POSITIVO';

  double get _parsedQtd =>
      double.tryParse(_qtdController.text.replaceAll(',', '.')) ?? 0.0;

  double get _projectedStock {
    if (_isEntradaOuIncremento) {
      return widget.item.qtdAtual + _parsedQtd;
    } else {
      return widget.item.qtdAtual - _parsedQtd;
    }
  }

  Future<void> _salvarMovimentacao() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final qtd = double.parse(_qtdController.text.replaceAll(',', '.'));
      final vidaUtil = int.tryParse(_vidaUtilController.text) ?? 60;

      await ref.read(stockServiceProvider).registrarMovimentacao(
            tenantId: widget.tenantId,
            itemId: widget.item.id,
            tipo: _tipoMovimento,
            quantidade: qtd,
            motivo: _motivoController.text.trim(),
            loteCodigo: _loteController.text.trim().isNotEmpty
                ? _loteController.text.trim()
                : null,
            clienteNome: _clienteNomeController.text.trim().isNotEmpty
                ? _clienteNomeController.text.trim()
                : null,
            clienteTelefone: _clienteTelefoneController.text.trim().isNotEmpty
                ? _clienteTelefoneController.text.trim()
                : null,
            diasVidaUtil: vidaUtil,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tipoMovimento == 'SAIDA_EPI'
                        ? 'Ficha de Entrega de EPI registrada! Régua preventiva NR-06 ativada.'
                        : _tipoMovimento.contains('SAIDA') ||
                                _tipoMovimento == 'AJUSTE_NEGATIVO'
                            ? 'Baixa de estoque registrada com sucesso!'
                            : 'Entrada de estoque registrada com sucesso!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: _getTipoColor(_tipoMovimento),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar movimentação: $e'),
            backgroundColor: SigeColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = _getTipoColor(_tipoMovimento);

    return Dialog(
      backgroundColor: isDark ? SigeColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: activeColor.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header com Gradiente e Identidade do Item
                _buildHeader(isDark, activeColor),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seletor de Movimento em Cards Ricos (Substitui ChoiceChips)
                      _buildMovementTypeSelector(isDark),
                      const SizedBox(height: 18),

                      // Régua Visual de Saldo Projetado (Math Visualizer)
                      _buildProjectedBalanceStrip(isDark, activeColor),
                      const SizedBox(height: 20),

                      // Campo de Quantidade & Stepper Rápido
                      _buildQuantitySection(isDark, activeColor),
                      const SizedBox(height: 16),

                      // Código do Lote
                      _buildLoteField(isDark),
                      const SizedBox(height: 16),

                      // Seção Especializada de Ficha de Entrega de EPI (NR-06)
                      if (_tipoMovimento == 'SAIDA_EPI' ||
                          (_tipoMovimento == 'SAIDA_VENDA' && widget.item.isEpi)) ...[
                        _buildEpiDeliverySection(isDark),
                        const SizedBox(height: 16),
                      ],

                      // Motivo / Referência com Pílulas de Preenchimento Rápido
                      _buildMotivoSection(isDark),
                      const SizedBox(height: 24),

                      // Rodapé com Ações
                      _buildFooterActions(activeColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color activeColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
      decoration: BoxDecoration(
        color: isDark
            ? SigeColors.darkCardBg
            : activeColor.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? SigeColors.darkBorder
                : activeColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeColor,
                  activeColor.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _getMovementIcon(_tipoMovimento),
              color: Colors.white,
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
                    const Text(
                      'Movimentação de Estoque',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: activeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _getMovementLabelShort(_tipoMovimento),
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  widget.item.nomeProduto,
                  style: TextStyle(
                    color: isDark
                        ? SigeColors.darkTextSecondary
                        : SigeColors.lightTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              foregroundColor:
                  isDark ? Colors.white70 : SigeColors.lightTextSecondary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTypeSelector(bool isDark) {
    final options = [
      (
        key: 'ENTRADA',
        label: 'Entrada / Compra',
        badge: '+ Estoque',
        icon: Icons.south_west_rounded,
        color: SigeColors.success,
      ),
      (
        key: 'SAIDA_VENDA',
        label: 'Saída / Venda',
        badge: '- Venda',
        icon: Icons.north_east_rounded,
        color: const Color(0xFF3B82F6),
      ),
      if (widget.item.isEpi)
        (
          key: 'SAIDA_EPI',
          label: 'Ficha Entrega EPI',
          badge: 'NR-06',
          icon: Icons.health_and_safety_rounded,
          color: const Color(0xFF8B5CF6),
        ),
      (
        key: 'AJUSTE_POSITIVO',
        label: 'Ajuste Balanço (+)',
        badge: 'Inventário',
        icon: Icons.tune_rounded,
        color: const Color(0xFF06B6D4),
      ),
      (
        key: 'AJUSTE_NEGATIVO',
        label: 'Perda / Descarte (-)',
        badge: 'Baixa',
        icon: Icons.delete_sweep_rounded,
        color: const Color(0xFFEF4444),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione a Operação:',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = _tipoMovimento == opt.key;
            final optColor = opt.color;

            return InkWell(
              onTap: () => setState(() => _tipoMovimento = opt.key),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? optColor
                      : (isDark
                          ? SigeColors.darkCardBg
                          : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? optColor
                        : (isDark
                            ? SigeColors.darkBorder
                            : SigeColors.lightBorder),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: optColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : optColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      opt.label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark
                                ? SigeColors.darkTextPrimary
                                : SigeColors.lightTextPrimary),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.06)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        opt.badge,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white60 : SigeColors.lightTextSecondary),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProjectedBalanceStrip(bool isDark, Color activeColor) {
    final current = widget.item.qtdAtual;
    final projected = _projectedStock;
    final isNegative = projected < 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? SigeColors.darkCardBg
            : activeColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNegative
              ? SigeColors.danger
              : (isDark
                  ? SigeColors.darkBorder
                  : activeColor.withValues(alpha: 0.2)),
          width: isNegative ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Saldo Atual
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saldo Atual',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${current.toStringAsFixed(current % 1 == 0 ? 0 : 1)} ${widget.item.unidadeMedida}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              // Sinal Operacional
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isEntradaOuIncremento
                      ? Icons.add_rounded
                      : Icons.remove_rounded,
                  color: activeColor,
                  size: 16,
                ),
              ),

              // Quantidade Informada
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Movimento',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? SigeColors.darkTextSecondary
                          : SigeColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_isEntradaOuIncremento ? "+" : "-"}${_parsedQtd.toStringAsFixed(_parsedQtd % 1 == 0 ? 0 : 1)} ${widget.item.unidadeMedida}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: activeColor,
                    ),
                  ),
                ],
              ),

              // Ícone de Igual
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black26,
              ),

              // Saldo Projetado
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Saldo Projetado',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isNegative
                          ? SigeColors.danger
                          : (isDark
                              ? SigeColors.darkTextSecondary
                              : SigeColors.lightTextSecondary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${projected.toStringAsFixed(projected % 1 == 0 ? 0 : 1)} ${widget.item.unidadeMedida}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: isNegative
                          ? SigeColors.danger
                          : (_isEntradaOuIncremento
                              ? SigeColors.success
                              : (isDark ? Colors.white : SigeColors.lightTextPrimary)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (isNegative) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SigeColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 14, color: SigeColors.danger),
                  SizedBox(width: 6),
                  Text(
                    'Atenção: A movimentação excede o estoque físico disponível!',
                    style: TextStyle(
                      color: SigeColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantitySection(bool isDark, Color activeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quantidade:',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            // Stepper Rápido
            Wrap(
              spacing: 6,
              children: [
                _buildQuickStepChip('-1', () => _stepQuantity(-1), isDark),
                _buildQuickStepChip('+1', () => _stepQuantity(1), isDark),
                _buildQuickStepChip('+5', () => _stepQuantity(5), isDark),
                _buildQuickStepChip('+10', () => _stepQuantity(10), isDark),
                _buildQuickStepChip('+50', () => _stepQuantity(50), isDark),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _qtdController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Ex: 10',
            prefixIcon: const Icon(Icons.tag_rounded),
            suffixText: widget.item.unidadeMedida,
            suffixStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: activeColor,
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Informe a quantidade';
            }
            final parsed = double.tryParse(val.replaceAll(',', '.'));
            if (parsed == null || parsed <= 0) {
              return 'Quantidade deve ser maior que zero';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickStepChip(String label, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : SigeColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoteField(bool isDark) {
    return TextFormField(
      controller: _loteController,
      decoration: InputDecoration(
        labelText: 'Código do Lote (Opcional)',
        hintText: 'Ex: LOTE-2026-B12',
        prefixIcon: const Icon(Icons.qr_code_2_rounded),
        suffixIcon: IconButton(
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          tooltip: 'Gerar Lote Automático',
          onPressed: () {
            final now = DateTime.now();
            final code = 'LOT-${now.year}${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            setState(() => _loteController.text = code);
          },
        ),
      ),
    );
  }

  Widget _buildEpiDeliverySection(bool isDark) {
    final diasVida = int.tryParse(_vidaUtilController.text) ?? 60;
    final dataAlerta = DateTime.now().add(Duration(days: diasVida));
    final dataStr = DateFormat('dd/MM/yyyy').format(dataAlerta);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? SigeColors.darkCardBg
            : const Color(0xFF8B5CF6).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_chat_unread_rounded,
                  size: 16,
                  color: Color(0xFF8B5CF6),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ficha Digital & Régua de Atendimento NR-06',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                    Text(
                      'Alerta preventivo programado automaticamente via WhatsApp.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _clienteNomeController,
            decoration: const InputDecoration(
              labelText: 'Nome do Colaborador / Cliente *',
              hintText: 'Ex: Carlos Oliveira ou Construtora Norte',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            validator: (val) {
              if (_tipoMovimento == 'SAIDA_EPI' &&
                  (val == null || val.trim().isEmpty)) {
                return 'Informe o destinatário do EPI para a Ficha NR-06';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: TextFormField(
                  controller: _clienteTelefoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp para Alertas',
                    hintText: 'Ex: 84999887766',
                    prefixIcon: Icon(Icons.phone_iphone_rounded,
                        color: Color(0xFF25D366)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: TextFormField(
                  controller: _vidaUtilController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Vida Útil (Dias)',
                    hintText: 'Ex: 60',
                    prefixIcon: Icon(Icons.hourglass_top_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Previsão de Troca / Reabastecimento: $dataStr',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
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

  Widget _buildMotivoSection(bool isDark) {
    final quickMotivos = [
      'Nota Fiscal / Compra',
      'Venda ao Cliente',
      'Ficha de Entrega NR-06',
      'Ajuste de Balanço',
      'Avaria no Transporte',
      'Vencimento de Lote',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Motivo ou Documento de Referência *',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _motivoController,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Ex: NF-e 45291 / Pedido #891 / Reabastecimento semanal...',
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Icon(Icons.description_outlined),
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Informe o motivo da movimentação';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: quickMotivos.map((m) {
            return InkWell(
              onTap: () => _setMotivo(m),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark
                        ? SigeColors.darkBorder
                        : SigeColors.lightBorder,
                  ),
                ),
                child: Text(
                  m,
                  style: TextStyle(
                    fontSize: 11,
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
    );
  }

  Widget _buildFooterActions(Color activeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _salvarMovimentacao,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(_getMovementIcon(_tipoMovimento), size: 18),
          label: Text(
            _isLoading
                ? 'Processando...'
                : 'Confirmar ${_getMovementLabelShort(_tipoMovimento)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  IconData _getMovementIcon(String tipo) {
    switch (tipo) {
      case 'ENTRADA':
        return Icons.south_west_rounded;
      case 'SAIDA_VENDA':
        return Icons.north_east_rounded;
      case 'SAIDA_EPI':
        return Icons.health_and_safety_rounded;
      case 'AJUSTE_POSITIVO':
        return Icons.tune_rounded;
      case 'AJUSTE_NEGATIVO':
        return Icons.delete_sweep_rounded;
      default:
        return Icons.sync_alt_rounded;
    }
  }

  String _getMovementLabelShort(String tipo) {
    switch (tipo) {
      case 'ENTRADA':
        return 'Entrada';
      case 'SAIDA_VENDA':
        return 'Saída / Venda';
      case 'SAIDA_EPI':
        return 'Entrega EPI';
      case 'AJUSTE_POSITIVO':
        return 'Ajuste (+)';
      case 'AJUSTE_NEGATIVO':
        return 'Baixa (-)';
      default:
        return 'Movimento';
    }
  }
}

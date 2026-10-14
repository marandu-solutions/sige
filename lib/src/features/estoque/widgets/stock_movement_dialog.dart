import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/stock_item_model.dart';
import '../providers/stock_provider.dart';

/// Modal Ágil de Movimentação de Estoque & Ficha de Entrega de EPI
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

class _StockMovementDialogState extends ConsumerState<StockMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qtdController = TextEditingController();
  final _motivoController = TextEditingController();
  final _loteController = TextEditingController();
  final _clienteNomeController = TextEditingController();
  final _clienteTelefoneController = TextEditingController();
  final _vidaUtilController = TextEditingController();

  String _tipoMovimento = 'ENTRADA'; // 'ENTRADA', 'SAIDA_VENDA', 'SAIDA_EPI', 'AJUSTE_POSITIVO', 'AJUSTE_NEGATIVO'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.isEpi) {
      _vidaUtilController.text = '${widget.item.diasVidaUtilUso ?? 60}';
    }
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
            content: Text(
              _tipoMovimento.contains('SAIDA')
                  ? 'Saída registrada com sucesso!${widget.item.isEpi ? ' Régua preventiva ativada.' : ''}'
                  : 'Entrada registrada com sucesso!',
            ),
            backgroundColor: SigeColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar movimentação: $e'),
            backgroundColor: SigeColors.danger,
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.sync_alt_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Movimentação de Estoque',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              widget.item.nomeProduto,
                              style: theme.textTheme.bodySmall?.copyWith(
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
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Seletor de Tipo de Movimento
                  const Text('Tipo de Movimento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTipoChip('ENTRADA', 'Entrada / Compra', Icons.add_circle_outline),
                      _buildTipoChip('SAIDA_VENDA', 'Saída / Venda', Icons.remove_circle_outline),
                      if (widget.item.isEpi)
                        _buildTipoChip('SAIDA_EPI', 'Ficha Entrega EPI', Icons.badge_outlined),
                      _buildTipoChip('AJUSTE_POSITIVO', 'Ajuste Balanço (+)', Icons.tune),
                      _buildTipoChip('AJUSTE_NEGATIVO', 'Perda / Descarte (-)', Icons.delete_outline),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Quantidade e Lote
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          controller: _qtdController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Quantidade (${widget.item.unidadeMedida})',
                            hintText: 'Ex: 10',
                            prefixIcon: const Icon(Icons.numbers_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Informe a quantidade';
                            final parsed = double.tryParse(val.replaceAll(',', '.'));
                            if (parsed == null || parsed <= 0) return 'Qtd inválida';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          controller: _loteController,
                          decoration: const InputDecoration(
                            labelText: 'Código do Lote',
                            hintText: 'Ex: LOT-2026-09A',
                            prefixIcon: Icon(Icons.qr_code_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Campos Especializados para Ficha de Entrega de EPI / CRM
                  if (_tipoMovimento == 'SAIDA_EPI' || (_tipoMovimento == 'SAIDA_VENDA' && widget.item.isEpi)) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mark_chat_unread_rounded, size: 16, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Régua de Atendimento Omnichannel (NR-06)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _clienteNomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome do Cliente ou Colaborador',
                              hintText: 'Ex: Construtora Alpha / João Silva',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) {
                              if (_tipoMovimento == 'SAIDA_EPI' && (val == null || val.trim().isEmpty)) {
                                return 'Informe o destinatário do EPI';
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
                                    hintText: 'Ex: 11999887766',
                                    prefixIcon: Icon(Icons.phone_outlined),
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
                                    prefixIcon: Icon(Icons.timer_outlined),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Motivo / Observação
                  TextFormField(
                    controller: _motivoController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Motivo / Documento de Referência',
                      hintText: 'Ex: Pedido #104 / Nota Fiscal 8921 / Descarte avaria',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Informe o motivo da movimentação';
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Botões de Ação
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isLoading ? 'Processando...' : 'Confirmar'),
                        onPressed: _isLoading ? null : _salvarMovimentacao,
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

  Widget _buildTipoChip(String value, String label, IconData icon) {
    final isSelected = _tipoMovimento == value;
    final theme = Theme.of(context);

    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : theme.colorScheme.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _tipoMovimento = value);
      },
    );
  }
}

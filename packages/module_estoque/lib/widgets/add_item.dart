import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_estoque/models/stock_item_model.dart';
import 'package:module_estoque/providers/stock_provider.dart';

class AddEstoqueItemDialog extends ConsumerStatefulWidget {
  final StockItemModel? item;
  final String tenantId;

  const AddEstoqueItemDialog({super.key, this.item, required this.tenantId});

  @override
  ConsumerState<AddEstoqueItemDialog> createState() =>
      _AddEstoqueItemDialogState();
}

class _AddEstoqueItemDialogState extends ConsumerState<AddEstoqueItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _alertaController;
  late TextEditingController _skuController;
  late TextEditingController _precoController;
  String _unidade = 'un';

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.item?.nomeProduto ?? '');
    _quantidadeController =
        TextEditingController(text: widget.item?.qtdAtual.toString() ?? '0');
    _alertaController =
        TextEditingController(text: widget.item?.nivelAlerta.toString() ?? '0');
    _skuController = TextEditingController(text: widget.item?.sku ?? '');
    _precoController = TextEditingController(
        text: widget.item?.precoVenda.toString().replaceAll('.', ',') ?? '0,00');
    _unidade = widget.item?.unidadeMedida ?? 'un';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _alertaController.dispose();
    _skuController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final novoItem = StockItemModel(
        id: widget.item?.id ?? '',
        tenantId: widget.tenantId,
        nomeProduto: _nomeController.text,
        sku: _skuController.text,
        qtdAtual: double.tryParse(_quantidadeController.text) ?? 0.0,
        unidadeMedida: _unidade,
        precoVenda:
            double.tryParse(_precoController.text.replaceAll(',', '.')) ?? 0.0,
        nivelAlerta: double.tryParse(_alertaController.text) ?? 0.0,
      );

      final notifier = ref.read(stockProvider(widget.tenantId).notifier);

      if (widget.item == null) {
        notifier.addItem(novoItem);
      } else {
        notifier.updateItem(novoItem);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    return AlertDialog(
      title: Text(widget.item == null ? 'Adicionar Insumo' : 'Editar Insumo'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration:
                    inputDecoration.copyWith(labelText: 'Nome do Insumo'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: inputDecoration.copyWith(labelText: 'SKU'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantidadeController,
                      decoration:
                          inputDecoration.copyWith(labelText: 'Quantidade'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (double.tryParse(v!) ?? -1) < 0 ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: DropdownButtonFormField<String>(
                      value: _unidade,
                      decoration: inputDecoration,
                      items: ['un', 'kg', 'g', 'L', 'ml'].map((String value) {
                        return DropdownMenuItem<String>(
                            value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) =>
                          setState(() => _unidade = newValue!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _alertaController,
                      decoration:
                          inputDecoration.copyWith(labelText: 'Nível de Alerta'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          (double.tryParse(v!) ?? -1) < 0 ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _precoController,
                      decoration: inputDecoration.copyWith(
                          labelText: 'Preço de Venda',
                          prefixText: 'R\$ '),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        FilledButton(onPressed: _handleSave, child: const Text('Salvar')),
      ],
    );
  }
}

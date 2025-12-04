import 'package:flutter/material.dart';
import 'package:module_estoque/models/stock_item_model.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Dialog para adicionar novo item ao estoque
class AddStockItemDialog extends StatefulWidget {
  final String tenantId;
  final Function(StockItemModel) onSave;

  const AddStockItemDialog({
    super.key,
    required this.tenantId,
    required this.onSave,
  });

  @override
  State<AddStockItemDialog> createState() => _AddStockItemDialogState();
}

class _AddStockItemDialogState extends State<AddStockItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _precoController = TextEditingController();
  String _unidadeMedida = 'UN';

  @override
  void dispose() {
    _nomeController.dispose();
    _skuController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Adicionar Novo Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome do Produto',
                  prefixIcon: const Icon(LucideIcons.package),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do produto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(
                  labelText: 'SKU',
                  prefixIcon: const Icon(LucideIcons.tag),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o SKU';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantidadeController,
                      decoration: InputDecoration(
                        labelText: 'Quantidade',
                        prefixIcon: const Icon(LucideIcons.hash),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Insira a quantidade';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Quantidade inválida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _unidadeMedida,
                      decoration: const InputDecoration(
                        labelText: 'Unidade',
                      ),
                      items: ['UN', 'KG', 'LT', 'MT', 'CX']
                          .map((unidade) => DropdownMenuItem(
                                value: unidade,
                                child: Text(unidade),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _unidadeMedida = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoController,
                decoration: InputDecoration(
                  labelText: 'Preço de Venda',
                  prefixIcon: const Icon(LucideIcons.dollarSign),
                  prefixText: 'R\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o preço';
                  }
                  if (double.tryParse(value.replaceAll(',', '.')) == null) {
                    return 'Preço inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _saveItem,
          icon: const Icon(LucideIcons.save, size: 16),
          label: const Text('Salvar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final newItem = StockItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tenantId: widget.tenantId,
        nomeProduto: _nomeController.text,
        sku: _skuController.text,
        qtdAtual: double.parse(_quantidadeController.text),
        unidadeMedida: _unidadeMedida,
        precoVenda: double.parse(_precoController.text.replaceAll(',', '.')),
      );

      widget.onSave(newItem);
      Navigator.pop(context);
    }
  }
}

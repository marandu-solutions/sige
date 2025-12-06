/*import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../Model/estoque.dart';

class AddEstoqueItemDialog extends StatefulWidget {
  final EstoqueItem? item;
  final Function(EstoqueItem) onSave;

  const AddEstoqueItemDialog({this.item, required this.onSave});

  @override
  AddEstoqueItemDialogState createState() => AddEstoqueItemDialogState();
}

class AddEstoqueItemDialogState extends State<AddEstoqueItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _quantidadeController;
  late TextEditingController _alertaController;
  String _unidade = 'un';

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.item?.nome ?? '');
    _quantidadeController = TextEditingController(text: widget.item?.quantidade.toString() ?? '');
    _alertaController = TextEditingController(text: widget.item?.nivelAlerta.toString() ?? '');
    _unidade = widget.item?.unidade ?? 'un';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _alertaController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final novoItem = EstoqueItem(
        id: widget.item?.id ?? UniqueKey().toString(),
        nome: _nomeController.text,
        quantidade: double.tryParse(_quantidadeController.text) ?? 0.0,
        unidade: _unidade,
        nivelAlerta: double.tryParse(_alertaController.text) ?? 0.0,
      );
      widget.onSave(novoItem);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (código do diálogo mantido)
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
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: inputDecoration.copyWith(labelText: 'Nome do Insumo'),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantidadeController,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                      decoration: inputDecoration.copyWith(labelText: 'Quantidade'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (double.tryParse(v!) ?? -1) < 0 ? 'Inválido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: DropdownButtonFormField<String>(
                      value: _unidade,
                      decoration: inputDecoration,
                      items: ['un', 'kg', 'g', 'L', 'ml'].map((String value) {
                        return DropdownMenuItem<String>(value: value, child: Text(value));
                      }).toList(),
                      onChanged: (newValue) => setState(() => _unidade = newValue!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alertaController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: inputDecoration.copyWith(labelText: 'Nível de Alerta'),
                keyboardType: TextInputType.number,
                validator: (v) => (double.tryParse(v!) ?? -1) < 0 ? 'Inválido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _handleSave, child: const Text('Salvar')),
      ],
    );
  }
}*/
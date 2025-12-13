import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';

class AddEditAtendimentoColumnDialog extends StatefulWidget {
  final AtendimentoColumnModel? column;
  final Function(String title, Color color) onSave;
  final VoidCallback? onDelete;

  const AddEditAtendimentoColumnDialog({
    super.key,
    this.column,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<AddEditAtendimentoColumnDialog> createState() =>
      _AddEditAtendimentoColumnDialogState();
}

class _AddEditAtendimentoColumnDialogState
    extends State<AddEditAtendimentoColumnDialog> {
  late final TextEditingController _titleController;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.column?.title ?? '');
    _selectedColor = widget.column?.color ?? Colors.blue;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha uma cor'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('SELECIONAR'),
          ),
        ],
      ),
    );
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira um título')),
      );
      return;
    }
    widget.onSave(title, _selectedColor);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(widget.column == null ? 'Adicionar Coluna' : 'Editar Coluna'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título da coluna',
                hintText: 'Ex: Novos Atendimentos',
              ),
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
              title: const Text('Cor da coluna'),
              trailing: const Icon(Icons.color_lens),
              onTap: _showColorPicker,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.onDelete != null) ...[
          TextButton.icon(
            onPressed: () {
              // Fecha o diálogo de edição
              Navigator.of(context).pop();
              // Chama o callback de deleção que gerenciará a confirmação e movimentação de cards
              widget.onDelete!();
            },
            icon: const Icon(Icons.delete),
            label: const Text('Excluir'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
          ),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}

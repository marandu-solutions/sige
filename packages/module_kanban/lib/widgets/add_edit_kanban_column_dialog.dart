import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:module_kanban/models/kanban_column_model.dart';

class AddEditKanbanColumnDialog extends StatefulWidget {
  final KanbanColumnModel? column;
  final Function(String title, Color color) onSave;

  const AddEditKanbanColumnDialog({super.key, this.column, required this.onSave});

  @override
  State<AddEditKanbanColumnDialog> createState() =>
      _AddEditKanbanColumnDialogState();
}

class _AddEditKanbanColumnDialogState extends State<AddEditKanbanColumnDialog> {
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
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.column == null ? 'Nova Coluna' : 'Editar Coluna'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Título da Coluna'),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cor da Coluna:'),
              GestureDetector(
                onTap: _showColorPicker,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.onSave(_titleController.text, _selectedColor);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

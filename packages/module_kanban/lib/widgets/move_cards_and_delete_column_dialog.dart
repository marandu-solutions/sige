import 'package:flutter/material.dart';
import 'package:module_kanban/models/kanban_column_model.dart';

class MoveCardsAndDeleteColumnDialog extends StatefulWidget {
  final KanbanColumnModel columnToDelete;
  final int cardsCount;
  final List<KanbanColumnModel> otherColumns;
  final Function(String targetColumnId) onConfirm;

  const MoveCardsAndDeleteColumnDialog({
    super.key,
    required this.columnToDelete,
    required this.cardsCount,
    required this.otherColumns,
    required this.onConfirm,
  });

  @override
  State<MoveCardsAndDeleteColumnDialog> createState() =>
      _MoveCardsAndDeleteColumnDialogState();
}

class _MoveCardsAndDeleteColumnDialogState
    extends State<MoveCardsAndDeleteColumnDialog> {
  late String _selectedColumnId;

  @override
  void initState() {
    super.initState();
    _selectedColumnId = widget.otherColumns.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Excluir "${widget.columnToDelete.title}"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'A coluna "${widget.columnToDelete.title}" contém ${widget.cardsCount} card(s). Para excluí-la, mova os cards para outra coluna.'),
          const SizedBox(height: 20),
          const Text('Mover cards para:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedColumnId,
            items: widget.otherColumns
                .map((column) => DropdownMenuItem(
                      value: column.id,
                      child: Text(column.title),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedColumnId = value;
                });
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_selectedColumnId);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Mover e Excluir'),
        ),
      ],
    );
  }
}

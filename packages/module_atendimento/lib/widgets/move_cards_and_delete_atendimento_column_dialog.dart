import 'package:flutter/material.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';

class MoveCardsAndDeleteAtendimentoColumnDialog extends StatefulWidget {
  final AtendimentoColumnModel columnToDelete;
  final int cardsCount;
  final List<AtendimentoColumnModel> otherColumns;
  final Function(String targetColumnId) onConfirm;

  const MoveCardsAndDeleteAtendimentoColumnDialog({
    super.key,
    required this.columnToDelete,
    required this.cardsCount,
    required this.otherColumns,
    required this.onConfirm,
  });

  @override
  State<MoveCardsAndDeleteAtendimentoColumnDialog> createState() =>
      _MoveCardsAndDeleteAtendimentoColumnDialogState();
}

class _MoveCardsAndDeleteAtendimentoColumnDialogState
    extends State<MoveCardsAndDeleteAtendimentoColumnDialog> {
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
              'A coluna "${widget.columnToDelete.title}" contém ${widget.cardsCount} atendimento(s). Para excluí-la, mova os atendimentos para outra coluna.'),
          const SizedBox(height: 20),
          const Text('Mover atendimentos para:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedColumnId,
            items: widget.otherColumns
                .map((column) => DropdownMenuItem(
                      value: column.id,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: column.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(column.title),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedColumnId = value);
              }
            },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_selectedColumnId);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('EXCLUIR COLUNA'),
        ),
      ],
    );
  }
}

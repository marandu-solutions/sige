import 'package:flutter/material.dart';
import 'package:module_kanban/models/kanban_card_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

/// Dialog para adicionar novo cartão Kanban
class AddKanbanCardDialog extends StatefulWidget {
  final String tenantId;
  final Function(KanbanCardModel) onSave;

  const AddKanbanCardDialog({
    super.key,
    required this.tenantId,
    required this.onSave,
  });

  @override
  State<AddKanbanCardDialog> createState() => _AddKanbanCardDialogState();
}

class _AddKanbanCardDialogState extends State<AddKanbanCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _dataLimiteController = TextEditingController();
  String _colunaStatus = 'to_do';
  String _prioridade = 'media';
  DateTime? _dataLimite;

  @override
  void initState() {
    super.initState();
    _dataLimite = DateTime.now().add(const Duration(days: 7));
    _dataLimiteController.text = DateFormat('dd/MM/yyyy').format(_dataLimite!);
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _dataLimiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Adicionar Novo Cartão'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título do Cartão',
                  prefixIcon: Icon(LucideIcons.fileText),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o título do cartão';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _colunaStatus,
                decoration: const InputDecoration(
                  labelText: 'Coluna',
                  prefixIcon: Icon(LucideIcons.columns),
                ),
                items: [
                  DropdownMenuItem(value: 'to_do', child: Text('A Fazer')),
                  DropdownMenuItem(
                      value: 'in_progress', child: Text('Em Progresso')),
                  DropdownMenuItem(value: 'done', child: Text('Concluído')),
                ],
                onChanged: (value) {
                  setState(() {
                    _colunaStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _prioridade,
                decoration: const InputDecoration(
                  labelText: 'Prioridade',
                  prefixIcon: Icon(LucideIcons.flag),
                ),
                items: [
                  DropdownMenuItem(value: 'baixa', child: Text('Baixa')),
                  DropdownMenuItem(value: 'media', child: Text('Média')),
                  DropdownMenuItem(value: 'alta', child: Text('Alta')),
                ],
                onChanged: (value) {
                  setState(() {
                    _prioridade = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dataLimiteController,
                decoration: const InputDecoration(
                  labelText: 'Data Limite',
                  prefixIcon: Icon(LucideIcons.calendar),
                  suffixIcon: Icon(LucideIcons.calendarDays),
                ),
                readOnly: true,
                onTap: _selectDate,
                validator: (value) {
                  if (_dataLimite == null) {
                    return 'Por favor, selecione a data limite';
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
          onPressed: _saveCard,
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataLimite ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dataLimite) {
      setState(() {
        _dataLimite = picked;
        _dataLimiteController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final newCard = KanbanCardModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tenantId: widget.tenantId,
        titulo: _tituloController.text,
        colunaStatus: _colunaStatus,
        prioridade: _prioridade,
        dataLimite: _dataLimite!,
      );

      widget.onSave(newCard);
      Navigator.pop(context);
    }
  }
}

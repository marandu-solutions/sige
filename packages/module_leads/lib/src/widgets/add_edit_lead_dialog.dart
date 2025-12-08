import 'package:flutter/material.dart';
import 'package:module_leads/src/models/lead_model.dart';

class AddEditLeadDialog extends StatefulWidget {
  final String tenantId;
  final LeadModel? lead;
  final Function(LeadModel) onSave;

  const AddEditLeadDialog({
    super.key,
    required this.tenantId,
    this.lead,
    required this.onSave,
  });

  @override
  State<AddEditLeadDialog> createState() => _AddEditLeadDialogState();
}

class _AddEditLeadDialogState extends State<AddEditLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _origemController;
  late TextEditingController _observacoesController;
  String _status = 'Novo';

  final List<String> _statusOptions = [
    'Novo',
    'Em Andamento',
    'Convertido',
    'Perdido'
  ];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.lead?.nome ?? '');
    _emailController = TextEditingController(text: widget.lead?.email ?? '');
    _telefoneController =
        TextEditingController(text: widget.lead?.telefone ?? '');
    _origemController = TextEditingController(text: widget.lead?.origem ?? '');
    _observacoesController =
        TextEditingController(text: widget.lead?.observacoes ?? '');
    _status = widget.lead?.status ?? 'Novo';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _origemController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.lead == null ? 'Novo Lead' : 'Editar Lead'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _origemController,
                decoration: const InputDecoration(
                    labelText: 'Origem (Ex: Facebook, Site)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statusOptions
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacoesController,
                decoration: const InputDecoration(labelText: 'Observações'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final lead = LeadModel(
                id: widget.lead?.id ?? '',
                tenantId: widget.tenantId,
                nome: _nomeController.text.trim(),
                email: _emailController.text.trim(),
                telefone: _telefoneController.text.trim(),
                origem: _origemController.text.trim(),
                status: _status,
                dataCriacao: widget.lead?.dataCriacao ?? DateTime.now(),
                observacoes: _observacoesController.text.trim(),
              );
              widget.onSave(lead);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

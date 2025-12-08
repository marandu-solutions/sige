import 'package:flutter/material.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

/// Dialog para adicionar novo atendimento
class AddAtendimentoCardDialog extends StatefulWidget {
  final List<AtendimentoColumnModel> columns;
  final Function(String titulo, String clienteNome, String clienteTelefone,
      String clienteEmail, String prioridade, String colunaId) onSave;

  const AddAtendimentoCardDialog({
    super.key,
    required this.columns,
    required this.onSave,
  });

  @override
  State<AddAtendimentoCardDialog> createState() =>
      _AddAtendimentoCardDialogState();
}

class _AddAtendimentoCardDialogState extends State<AddAtendimentoCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _clienteNomeController = TextEditingController();
  final _clienteTelefoneController = TextEditingController();
  final _clienteEmailController = TextEditingController();
  String _colunaId = '';
  String _prioridade = 'media';

  @override
  void initState() {
    super.initState();
    _colunaId = widget.columns.isNotEmpty ? widget.columns.first.id : '';
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _clienteNomeController.dispose();
    _clienteTelefoneController.dispose();
    _clienteEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Adicionar Novo Atendimento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título do atendimento
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título do atendimento',
                  hintText: 'Ex: Suporte técnico para instalação',
                  prefixIcon: Icon(LucideIcons.tag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Nome do cliente
              TextFormField(
                controller: _clienteNomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do cliente',
                  hintText: 'Ex: João da Silva',
                  prefixIcon: Icon(LucideIcons.user),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o nome do cliente';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Telefone do cliente
              TextFormField(
                controller: _clienteTelefoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefone do cliente',
                  hintText: 'Ex: (11) 98765-4321',
                  prefixIcon: Icon(LucideIcons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o telefone do cliente';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email do cliente
              TextFormField(
                controller: _clienteEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email do cliente',
                  hintText: 'Ex: cliente@email.com',
                  prefixIcon: Icon(LucideIcons.mail),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Por favor, insira um email válido';
                    }
                  }
                  return null;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Coluna
              DropdownButtonFormField<String>(
                value: _colunaId,
                decoration: const InputDecoration(
                  labelText: 'Coluna',
                  prefixIcon: Icon(LucideIcons.columns),
                ),
                items: widget.columns
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
                    setState(() => _colunaId = value);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma coluna';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Prioridade
              DropdownButtonFormField<String>(
                value: _prioridade,
                decoration: const InputDecoration(
                  labelText: 'Prioridade',
                  prefixIcon: Icon(LucideIcons.alertCircle),
                ),
                items: const [
                  DropdownMenuItem(value: 'baixa', child: Text('Baixa')),
                  DropdownMenuItem(value: 'media', child: Text('Média')),
                  DropdownMenuItem(value: 'alta', child: Text('Alta')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _prioridade = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _tituloController.text.trim(),
                _clienteNomeController.text.trim(),
                _clienteTelefoneController.text.trim(),
                _clienteEmailController.text.trim(),
                _prioridade,
                _colunaId,
              );
              Navigator.of(context).pop();
            }
          },
          icon: const Icon(LucideIcons.check),
          label: const Text('ADICIONAR'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_atendimento/models/atendimento_column_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_leads/module_leads.dart';

/// Dialog para adicionar novo atendimento
class AddAtendimentoCardDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final List<AtendimentoColumnModel> columns;
  final Function(
      String titulo,
      String clienteNome,
      String clienteTelefone,
      String prioridade,
      String colunaId,
      String? leadId) onSave;

  const AddAtendimentoCardDialog({
    super.key,
    required this.tenantId,
    required this.columns,
    required this.onSave,
  });

  @override
  ConsumerState<AddAtendimentoCardDialog> createState() =>
      _AddAtendimentoCardDialogState();
}

class _AddAtendimentoCardDialogState
    extends ConsumerState<AddAtendimentoCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _clienteNomeController = TextEditingController();
  final _clienteTelefoneController = TextEditingController();
  String _colunaId = '';
  String _prioridade = 'media';
  String? _selectedLeadId;

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
    super.dispose();
  }

  void _onLeadSelected(LeadModel lead) {
    setState(() {
      _selectedLeadId = lead.id;
      _clienteNomeController.text = lead.nome;
      _clienteTelefoneController.text = lead.telefone;

      // Auto-fill title if empty
      if (_tituloController.text.isEmpty) {
        _tituloController.text = 'Atendimento - ${lead.nome}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leadsAsync = ref.watch(leadsProvider(widget.tenantId));

    return AlertDialog(
      title: const Text('Adicionar Novo Atendimento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Buscar Lead
              leadsAsync.when(
                data: (leads) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vincular Lead (Opcional)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Autocomplete<LeadModel>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<LeadModel>.empty();
                        }
                        return leads.where((LeadModel lead) {
                          return lead.nome.toLowerCase().contains(
                                  textEditingValue.text.toLowerCase()) ||
                              lead.telefone.contains(textEditingValue.text);
                        });
                      },
                      displayStringForOption: (LeadModel option) => option.nome,
                      onSelected: _onLeadSelected,
                      fieldViewBuilder: (context, textEditingController,
                          focusNode, onFieldSubmitted) {
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Buscar Lead',
                            hintText: 'Nome ou telefone...',
                            prefixIcon: Icon(LucideIcons.search),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              width: 300,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final LeadModel option =
                                      options.elementAt(index);
                                  return ListTile(
                                    title: Text(option.nome),
                                    subtitle: Text(option.telefone),
                                    onTap: () {
                                      onSelected(option);
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

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
                _prioridade,
                _colunaId,
                _selectedLeadId,
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

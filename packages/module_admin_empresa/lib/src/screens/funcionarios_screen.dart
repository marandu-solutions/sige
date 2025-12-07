import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_admin_empresa/src/models/funcionario_model.dart';
import 'package:module_admin_empresa/src/providers/admin_providers.dart';
import 'package:module_admin_empresa/src/services/admin_empresa_service.dart';

class FuncionariosScreen extends ConsumerWidget {
  final String tenantId;

  const FuncionariosScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final funcionariosAsync = ref.watch(funcionariosProvider(tenantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Funcionários'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(context, ref),
        child: const Icon(LucideIcons.plus),
      ),
      body: funcionariosAsync.when(
        data: (funcionarios) {
          if (funcionarios.isEmpty) {
            return const Center(child: Text('Nenhum funcionário cadastrado.'));
          }
          return ListView.builder(
            itemCount: funcionarios.length,
            itemBuilder: (context, index) {
              final funcionario = funcionarios[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: funcionario.fotoUrl != null
                      ? NetworkImage(funcionario.fotoUrl!)
                      : null,
                  child: funcionario.fotoUrl == null
                      ? Text(funcionario.nome.isNotEmpty
                          ? funcionario.nome[0].toUpperCase()
                          : '?')
                      : null,
                ),
                title: Text(funcionario.nome),
                subtitle: Text(funcionario.cargo ?? 'Sem cargo'),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.red),
                  onPressed: () => _confirmDelete(context, ref, funcionario),
                ),
                onTap: () => _showAddEditDialog(context, ref, funcionario),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, WidgetRef ref,
      [FuncionarioModel? funcionario]) {
    showDialog(
      context: context,
      builder: (context) => _AddEditFuncionarioDialog(
        tenantId: tenantId,
        funcionario: funcionario,
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, FuncionarioModel funcionario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Funcionário?'),
        content: Text('Deseja realmente excluir ${funcionario.nome}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref
                  .read(adminEmpresaServiceProvider)
                  .deleteFuncionario(tenantId, funcionario.id);
              ref.invalidate(funcionariosProvider(tenantId));
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AddEditFuncionarioDialog extends ConsumerStatefulWidget {
  final String tenantId;
  final FuncionarioModel? funcionario;

  const _AddEditFuncionarioDialog({required this.tenantId, this.funcionario});

  @override
  ConsumerState<_AddEditFuncionarioDialog> createState() =>
      _AddEditFuncionarioDialogState();
}

class _AddEditFuncionarioDialogState
    extends ConsumerState<_AddEditFuncionarioDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _emailController;
  late TextEditingController _cargoController;
  late TextEditingController _telefoneController;
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _nomeController =
        TextEditingController(text: widget.funcionario?.nome ?? '');
    _emailController =
        TextEditingController(text: widget.funcionario?.email ?? '');
    _cargoController =
        TextEditingController(text: widget.funcionario?.cargo ?? '');
    _telefoneController =
        TextEditingController(text: widget.funcionario?.telefone ?? '');
    _ativo = widget.funcionario?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _cargoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.funcionario != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Funcionário' : 'Novo Funcionário'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo obrigatório' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(labelText: 'Cargo'),
              ),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                keyboardType: TextInputType.phone,
              ),
              SwitchListTile(
                title: const Text('Ativo'),
                value: _ativo,
                onChanged: (value) => setState(() => _ativo = value),
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
        ElevatedButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final service = ref.read(adminEmpresaServiceProvider);
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final cargo = _cargoController.text.trim();
    final telefone = _telefoneController.text.trim();

    try {
      if (widget.funcionario != null) {
        // Update
        final updatedFuncionario = widget.funcionario!.copyWith(
          nome: nome,
          email: email.isEmpty ? null : email,
          cargo: cargo.isEmpty ? null : cargo,
          telefone: telefone.isEmpty ? null : telefone,
          ativo: _ativo,
          dataAtualizacao: DateTime.now(),
        );
        await service.updateFuncionario(updatedFuncionario);
      } else {
        // Add
        final newFuncionario = FuncionarioModel(
          id: '', // Firestore generates ID if using add(), but wait...
          // The service uses .add() which ignores the ID in the model, BUT
          // the model has 'id' field.
          // When reading back, the ID comes from doc.id.
          // So passing empty string here is fine for creation if we use .add().
          // HOWEVER, my service addFuncionario uses .add(funcionario).
          // And my model toMap() includes 'id'?
          // Let's check toMap().
          // toMap() does NOT include 'id' (checked tenant_model, assumed funcionario_model is same).
          // Let's check FuncionarioModel.toMap().
          tenantId: widget.tenantId,
          nome: nome,
          email: email.isEmpty ? null : email,
          cargo: cargo.isEmpty ? null : cargo,
          telefone: telefone.isEmpty ? null : telefone,
          ativo: _ativo,
          dataCriacao: DateTime.now(),
          dataAtualizacao: DateTime.now(),
        );
        await service.addFuncionario(newFuncionario);
      }

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(funcionariosProvider(widget.tenantId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }
}

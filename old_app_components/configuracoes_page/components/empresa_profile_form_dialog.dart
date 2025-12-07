// lib/pages/configuracoes/components/empresa_profile_form_dialog.dart
/*
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:siga/Model/empresa.dart';

class EmpresaProfileFormDialog extends StatefulWidget {
  final Empresa empresa; // Agora recebe o seu modelo Empresa REAL
  final Function(Empresa) onSave; // Callback para salvar os dados (recebe seu modelo real)

  const EmpresaProfileFormDialog({
    super.key,
    required this.empresa,
    required this.onSave,
  });

  @override
  State<EmpresaProfileFormDialog> createState() =>
      _EmpresaProfileFormDialogState();
}

class _EmpresaProfileFormDialogState extends State<EmpresaProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeEmpresaController; // Corrigido para nomeEmpresa
  late TextEditingController _proprietarioController;
  late TextEditingController _emailController;
  late TextEditingController _telefoneController;
  late TextEditingController _cpfController;

  @override
  void initState() {
    super.initState();
    _nomeEmpresaController = TextEditingController(text: widget.empresa.nomeEmpresa);
    _proprietarioController = TextEditingController(text: widget.empresa.proprietario);
    _emailController = TextEditingController(text: widget.empresa.email);
    _telefoneController = TextEditingController(text: widget.empresa.telefone);
    _cpfController = TextEditingController(text: widget.empresa.cpf);
  }

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _proprietarioController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  void _salvarPerfil() {
    if (_formKey.currentState!.validate()) {
      final updatedEmpresa = Empresa(
        id: widget.empresa.id, // Mantém o ID original (fundamental!)
        nomeEmpresa: _nomeEmpresaController.text,
        proprietario: _proprietarioController.text,
        email: _emailController.text,
        telefone: _telefoneController.text,
        cpf: _cpfController.text,
        createdAt: widget.empresa.createdAt, // Mantém o createdAt original
      );
      widget.onSave(updatedEmpresa);
      Navigator.of(context).pop(); // Fecha o diálogo
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AlertDialog(
      backgroundColor: cs.surface,
      surfaceTintColor: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(LucideIcons.building2, color: cs.primary),
          const SizedBox(width: 10),
          Text(
            "Editar Perfil da Empresa",
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nomeEmpresaController,
                decoration: _inputDecoration(
                  context,
                  labelText: "Nome da Empresa",
                  hintText: "Ex: Minha Loja de Doces",
                  icon: LucideIcons.store,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome da empresa.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Proprietário - Pode não ser editável diretamente aqui, dependendo da lógica do seu app
              TextFormField(
                controller: _proprietarioController,
                decoration: _inputDecoration(
                  context,
                  labelText: "Nome do Proprietário",
                  icon: LucideIcons.user,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do proprietário.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration(
                  context,
                  labelText: "E-mail",
                  icon: LucideIcons.mail,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o e-mail.';
                  }
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return 'E-mail inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: _inputDecoration(
                  context,
                  labelText: "Telefone",
                  hintText: "Ex: (XX) XXXX-XXXX",
                  icon: LucideIcons.phone,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o telefone.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cpfController,
                decoration: _inputDecoration(
                  context,
                  labelText: "CPF do Proprietário",
                  hintText: "Ex: 000.000.000-00",
                  icon: LucideIcons.creditCard,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o CPF.';
                  }
                  // Adicione validação de CPF mais robusta se necessário
                  return null;
                },
              ),
              // Remover campos de Endereço, CNPJ e Logo, pois não estão no seu modelo Empresa
              // const SizedBox(height: 16),
              // TextFormField( /* Endereço */ ),
              // const SizedBox(height: 16),
              // TextFormField( /* CNPJ */ ),
              // const SizedBox(height: 16),
              // TextFormField( /* Logo URL */ ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Cancelar",
            style: textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        FilledButton(
          onPressed: _salvarPerfil,
          child: Text(
            "Salvar",
            style: textTheme.labelLarge?.copyWith(color: cs.onPrimary),
          ),
        ),
      ],
    );
  }

  // Função auxiliar para padronizar o InputDecoration (mantida a mesma)
  InputDecoration _inputDecoration(
    BuildContext context, {
    required String labelText,
    String? hintText,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: icon != null ? Icon(icon, color: cs.onSurfaceVariant) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.2),
      labelStyle: TextStyle(color: cs.onSurfaceVariant),
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.6)),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_admin_empresa/src/models/tenant_model.dart';

class EmpresaProfileFormDialog extends StatefulWidget {
  final TenantModel empresa;
  final Function(TenantModel) onSave;

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
  late TextEditingController _nomeFantasiaController;
  late TextEditingController _documentoFiscalController;

  @override
  void initState() {
    super.initState();
    _nomeFantasiaController =
        TextEditingController(text: widget.empresa.nomeFantasia);
    _documentoFiscalController =
        TextEditingController(text: widget.empresa.documentoFiscal);
  }

  @override
  void dispose() {
    _nomeFantasiaController.dispose();
    _documentoFiscalController.dispose();
    super.dispose();
  }

  void _salvarPerfil() {
    if (_formKey.currentState!.validate()) {
      final updatedEmpresa = widget.empresa.copyWith(
        nomeFantasia: _nomeFantasiaController.text,
        documentoFiscal: _documentoFiscalController.text,
      );
      widget.onSave(updatedEmpresa);
      Navigator.of(context).pop();
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
                controller: _nomeFantasiaController,
                decoration: _inputDecoration(
                  context,
                  labelText: "Nome Fantasia",
                  hintText: "Ex: Minha Loja",
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
              TextFormField(
                controller: _documentoFiscalController,
                decoration: _inputDecoration(
                  context,
                  labelText: "Documento Fiscal",
                  hintText: "Ex: 00.000.000/0000-00",
                  icon: LucideIcons.fileText,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o documento fiscal.';
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

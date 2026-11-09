import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/core/core.dart';


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
        nomeFantasia: _nomeFantasiaController.text.trim(),
        documentoFiscal: _documentoFiscalController.text.trim(),
      );
      widget.onSave(updatedEmpresa);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF2563EB);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.6)
                      : primaryColor.withValues(alpha: 0.14),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(26, 24, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                            : [const Color(0xFFF8FAFC), Colors.white],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.building2, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Perfil da Empresa',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: -0.4,
                                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Edite o nome fantasia, identificação fiscal e branding',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Icon(
                                LucideIcons.x,
                                size: 18,
                                color: isDark ? Colors.grey[300] : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildField(
                            controller: _nomeFantasiaController,
                            label: 'Nome Fantasia da Empresa',
                            hint: 'Ex: EPI Forte Equipamentos Ltda',
                            icon: LucideIcons.store,
                            isDark: isDark,
                            validator: (v) => v?.trim().isEmpty == true ? 'Insira o nome da empresa' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            controller: _documentoFiscalController,
                            label: 'Documento Fiscal (CNPJ / CPF)',
                            hint: 'Ex: 12.345.678/0001-90',
                            icon: LucideIcons.fileText,
                            isDark: isDark,
                            validator: (v) => v?.trim().isEmpty == true ? 'Insira o documento fiscal' : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions Footer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131D2E) : const Color(0xFFF8FAFC),
                      border: Border(
                        top: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.grey[300] : SigeColors.lightTextSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _salvarPerfil,
                            icon: const Icon(LucideIcons.check, size: 16),
                            label: const Text('Salvar Alterações', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.grey[300] : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[500] : const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
      ],
    );
  }
}



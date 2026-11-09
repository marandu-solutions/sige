import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sige/src/features/admin_empresa/src/models/funcionario_model.dart';


class FuncionarioCard extends StatefulWidget {
  final FuncionarioModel funcionario;
  final VoidCallback onEdit;
  final VoidCallback onStatusChange;

  const FuncionarioCard({
    super.key,
    required this.funcionario,
    required this.onEdit,
    required this.onStatusChange,
  });

  @override
  State<FuncionarioCard> createState() => _FuncionarioCardState();
}

class _FuncionarioCardState extends State<FuncionarioCard> {
  bool _isHovered = false;

  Color _getCargoColor(String cargo) {
    switch (cargo.toLowerCase()) {
      case 'admin':
      case 'administrador':
        return const Color(0xFF2563EB); // Azul Royal
      case 'gerente':
      case 'supervisor':
        return const Color(0xFF8B5CF6); // Roxo Executivo
      case 'atendente':
      case 'comercial':
      case 'vendedor':
        return const Color(0xFF10B981); // Esmeralda Atendimento
      case 'estoquista':
      case 'operador':
        return const Color(0xFFF59E0B); // Âmbar Operacional
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final f = widget.funcionario;
    final isAtivo = f.ativo;

    final cargoStr = (f.cargo != null && f.cargo!.trim().isNotEmpty)
        ? f.cargo!.trim()
        : 'Colaborador';
    final cargoColor = _getCargoColor(cargoStr);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: _isHovered
            ? Matrix4.translationValues(0.0, -3.0, 0.0)
            : Matrix4.identity(),
        margin: const EdgeInsets.only(bottom: 14.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1E293B),
                    const Color(0xFF131D2E),
                  ]
                : [
                    Colors.white,
                    const Color(0xFFF8FAFC),
                  ],
          ),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF2563EB).withValues(alpha: 0.5)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0)),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isAtivo
                  ? (_isHovered
                      ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.22 : 0.12)
                      : Colors.black.withValues(alpha: isDark ? 0.35 : 0.04))
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: _isHovered ? 18 : 10,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: widget.onEdit,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
              child: Row(
                children: [
                  // Avatar com Pulso ou Gradiente de Cargo
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isAtivo
                                ? [cargoColor, cargoColor.withValues(alpha: 0.6)]
                                : [Colors.grey[400]!, Colors.grey[600]!],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          backgroundImage: f.fotoUrl != null && f.fotoUrl!.isNotEmpty
                              ? NetworkImage(f.fotoUrl!)
                              : null,
                          child: f.fotoUrl == null || f.fotoUrl!.isEmpty
                              ? Text(
                                  f.nome.isNotEmpty
                                      ? f.nome.substring(0, f.nome.length >= 2 ? 2 : 1).toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                    color: isAtivo
                                        ? (isDark ? Colors.white : cargoColor)
                                        : Colors.grey[500],
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isAtivo ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Informações Principais
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                f.nome,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15.5,
                                  letterSpacing: -0.2,
                                  color: isDark ? Colors.white : SigeColors.lightTextPrimary,
                                  decoration: isAtivo ? null : TextDecoration.lineThrough,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Badge do Cargo com Design Aero
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: cargoColor.withValues(alpha: isDark ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: cargoColor.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                cargoStr.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                  color: isDark ? Colors.white : cargoColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.mail, size: 13, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                f.email ?? 'Email não informado',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (f.telefone != null && f.telefone!.isNotEmpty) ...[
                              const SizedBox(width: 14),
                              Icon(LucideIcons.phone, size: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                f.telefone!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.grey[400] : SigeColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (f.modulosAcesso.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: f.modulosAcesso.take(4).map((mod) {
                              final norm = mod.toLowerCase().replaceAll('module_', '');
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  norm,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Ações Rápidas em Linha (Editar e Status Toggle)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar Colaborador',
                        onPressed: widget.onEdit,
                        icon: const Icon(LucideIcons.edit3, size: 17),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF1F5F9),
                          foregroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: isAtivo ? 'Desativar Acesso' : 'Reativar Acesso',
                        onPressed: widget.onStatusChange,
                        icon: Icon(
                          isAtivo ? LucideIcons.userX : LucideIcons.userCheck,
                          size: 17,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: isAtivo
                              ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                              : const Color(0xFF10B981).withValues(alpha: 0.12),
                          foregroundColor: isAtivo ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          padding: const EdgeInsets.all(8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


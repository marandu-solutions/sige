import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:module_admin_empresa/src/models/funcionario_model.dart';

class FuncionarioCard extends StatelessWidget {
  final FuncionarioModel funcionario;
  final VoidCallback onEdit;
  final VoidCallback onStatusChange;

  const FuncionarioCard({
    super.key,
    required this.funcionario,
    required this.onEdit,
    required this.onStatusChange,
  });

  Color _getCargoChipColor(String cargo, ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      switch (cargo.toLowerCase()) {
        case 'admin':
          return Colors.blue.shade800;
        case 'gerente':
          return Colors.orange.shade800;
        case 'operador':
          return Colors.green.shade800;
        default:
          return Colors.grey.shade700;
      }
    } else {
      switch (cargo.toLowerCase()) {
        case 'admin':
          return theme.colorScheme.primaryContainer;
        case 'gerente':
          return theme.colorScheme.tertiaryContainer;
        case 'operador':
          return theme.colorScheme.secondaryContainer.withOpacity(0.7);
        default:
          return theme.colorScheme.surfaceVariant;
      }
    }
  }

  Color _getCargoChipTextColor(String cargo, ThemeData theme) {
    if (theme.brightness == Brightness.dark) {
      return Colors.white;
    } else {
      switch (cargo.toLowerCase()) {
        case 'admin':
          return theme.colorScheme.onPrimaryContainer;
        case 'gerente':
          return theme.colorScheme.onTertiaryContainer;
        case 'operador':
          return theme.colorScheme.onSecondaryContainer;
        default:
          return theme.colorScheme.onSurfaceVariant;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUserInactive = !funcionario.ativo;

    final String cargoCapitalizado = (funcionario.cargo != null &&
            funcionario.cargo!.isNotEmpty)
        ? funcionario.cargo![0].toUpperCase() + funcionario.cargo!.substring(1)
        : 'Indefinido';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isUserInactive
          ? theme.colorScheme.surfaceVariant.withOpacity(0.6)
          : theme.cardColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isUserInactive
                  ? theme.colorScheme.outline
                  : theme.colorScheme.primary.withOpacity(0.1),
              backgroundImage: funcionario.fotoUrl != null
                  ? NetworkImage(funcionario.fotoUrl!)
                  : null,
              child: funcionario.fotoUrl == null
                  ? Text(
                      funcionario.nome.isNotEmpty
                          ? funcionario.nome[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: isUserInactive
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    funcionario.nome,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUserInactive
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      decoration:
                          isUserInactive ? TextDecoration.lineThrough : null,
                      decorationColor: isUserInactive
                          ? theme.colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    funcionario.email ?? 'Sem e-mail',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(
                      cargoCapitalizado,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUserInactive
                            ? Colors.white
                            : _getCargoChipTextColor(
                                funcionario.cargo ?? '', theme),
                      ),
                    ),
                    backgroundColor: isUserInactive
                        ? Colors.grey.shade400
                        : _getCargoChipColor(funcionario.cargo ?? '', theme),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'toggle_status') {
                  onStatusChange();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(LucideIcons.edit3,
                          size: 18, color: theme.colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text('Editar',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        funcionario.ativo
                            ? LucideIcons.userX
                            : LucideIcons.userCheck,
                        size: 18,
                        color: funcionario.ativo ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        funcionario.ativo ? 'Desativar' : 'Reativar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                funcionario.ativo ? Colors.red : Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

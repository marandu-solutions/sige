// lib/Pages/ConfiguracoesPage/Components/funcionario_card.dart
/*
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:siga/Model/funcionario.dart'; // Importando seu modelo Funcionario

class FuncionarioCard extends StatelessWidget {
  final Funcionario funcionario;
  final VoidCallback onEdit;
  final VoidCallback onStatusChange;

  const FuncionarioCard({
    super.key,
    required this.funcionario,
    required this.onEdit,
    required this.onStatusChange,
  });

  Color _getCargoChipColor(String cargo, ThemeData theme) {
    if (theme.brightness == Brightness.dark) { // Se for tema escuro
      switch (cargo.toLowerCase()) {
        case 'admin':
          // CORRIGIDO: Usando uma cor MaterialColor direta (azul forte)
          return Colors.blue.shade800; // Um azul mais escuro e forte
        case 'gerente':
          return Colors.orange.shade800; // Um laranja mais escuro e forte
        case 'operador':
          return Colors.green.shade800; // VERDE MAIS ESCURO E VIBRANTE PARA OPERADOR
        default:
          // CORRIGIDO: Usando uma cor MaterialColor direta (cinza escuro)
          return Colors.grey.shade700; // Cor padrão para outros/desconhecidos no tema escuro
      }
    } else { // Se for tema claro (manter como estava)
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

  // Função auxiliar para obter a cor do texto do Chip (já estava ok, mas para consistência)
  Color _getCargoChipTextColor(String cargo, ThemeData theme) {
    if (theme.brightness == Brightness.dark) { // Se for tema escuro
      // Para fundos escuros (como shade800), o texto deve ser branco para contraste
      return Colors.white; 
    } else { // Se for tema claro (manter como estava)
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

    final String cargoCapitalizado = funcionario.cargo.isNotEmpty
        ? funcionario.cargo[0].toUpperCase() + funcionario.cargo.substring(1)
        : 'Indefinido';

    return Card(
      elevation: 2, // Elevação sutil
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Bordas arredondadas
      // Efeito visual para funcionários inativos no card
      color: isUserInactive ? theme.colorScheme.surfaceVariant.withOpacity(0.6) : theme.cardColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Avatar do funcionário
            CircleAvatar(
              radius: 24,
              backgroundColor: isUserInactive
                  ? theme.colorScheme.outline
                  : theme.colorScheme.primary.withOpacity(0.1), // Cor mais suave
              child: Text(
                funcionario.nome.isNotEmpty
                    ? funcionario.nome[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isUserInactive
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.primary, // Cor do texto do avatar
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do funcionário com efeito para inativos
                  Text(
                    funcionario.nome,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isUserInactive ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                      decoration: isUserInactive ? TextDecoration.lineThrough : null,
                      decorationColor: isUserInactive ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Email do funcionário
                  Text(
                    funcionario.email,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8), // Espaço entre email e chip
                  // NOVO: Chip para o cargo
                  Chip(
                    label: Text(
                      cargoCapitalizado,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUserInactive ? Colors.white : _getCargoChipTextColor(funcionario.cargo, theme),
                      ),
                    ),
                    backgroundColor: isUserInactive
                        ? Colors.grey.shade400 // Cinza para inativo
                        : _getCargoChipColor(funcionario.cargo, theme),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduz área de toque
                  ),
                ],
              ),
            ),
            // PopupMenuButton para ações (Editar/Desativar/Reativar)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
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
                      Icon(LucideIcons.edit3, size: 18, color: theme.colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text('Editar', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle_status',
                  child: Row(
                    children: [
                      Icon(
                        funcionario.ativo ? LucideIcons.userX : LucideIcons.userCheck,
                        size: 18,
                        color: funcionario.ativo ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        funcionario.ativo ? 'Desativar' : 'Reativar',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: funcionario.ativo ? Colors.red : Colors.green),
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
}*/
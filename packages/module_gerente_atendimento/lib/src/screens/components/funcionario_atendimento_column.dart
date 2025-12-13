import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:core/core.dart';
import 'package:module_atendimento/module_atendimento.dart';

class FuncionarioAtendimentoColumn extends StatelessWidget {
  final FuncionarioModel funcionario;
  final List<AtendimentoCardModel> cards;
  final VoidCallback onExpand;

  const FuncionarioAtendimentoColumn({
    super.key,
    required this.funcionario,
    required this.cards,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 336,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
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
                            color: colorScheme.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    funcionario.nome,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.maximize2, size: 20),
                  tooltip: 'Abrir Kanban do Funcionário',
                  onPressed: onExpand,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Cards List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, cardIndex) {
                final card = cards[cardIndex];
                return AtendimentoCardWidget(
                  card: card,
                  color: colorScheme.surface, // Passando a cor exigida
                  onTap: () {
                    // Optional: Open card details
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

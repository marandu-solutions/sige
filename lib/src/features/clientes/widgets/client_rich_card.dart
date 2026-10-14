import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sige/src/core/theme/sige_colors.dart';
import '../models/client_model.dart';

/// Card Rico de Cliente para Visão em Grade (Sally UX)
/// Apresenta dados de B2B/B2C, vínculos corporativos, tags e ações rápidas.
class ClientRichCard extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onTapDetail;
  final VoidCallback onQuickContact;

  const ClientRichCard({
    super.key,
    required this.client,
    required this.onTapDetail,
    required this.onQuickContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    final cardBg = isDark ? SigeColors.darkSurface : Colors.white;
    final borderColor = isDark ? SigeColors.darkBorder : SigeColors.lightBorder;

    // Definição de cores e badges de tipo
    Color typeColor = theme.colorScheme.primary;
    String typeLabel = 'PESSOA FÍSICA';
    IconData typeIcon = Icons.person_rounded;

    if (client.isPj) {
      typeColor = SigeColors.info;
      typeLabel = 'EMPRESA (PJ)';
      typeIcon = Icons.corporate_fare_rounded;
    } else if (client.isContatoPj) {
      typeColor = Colors.purple;
      typeLabel = 'CONTATO B2B';
      typeIcon = Icons.badge_rounded;
    }

    return InkWell(
      onTap: onTapDetail,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Topo: Avatar + Tipo + Status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: typeColor.withValues(alpha: 0.12),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: typeColor,
                          ),
                        ),
                      ),
                      if (client.isContatoPj && client.empresaNome != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          client.empresaNome!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? SigeColors.darkTextSecondary
                                : SigeColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Badge de Status do Ciclo de Vida
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: client.statusCiclo == 'ATIVO'
                        ? SigeColors.success.withValues(alpha: 0.12)
                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    client.statusCiclo,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: client.statusCiclo == 'ATIVO'
                          ? SigeColors.success
                          : (isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nome do Cliente
            Text(
              client.nome,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (client.cargo != null && client.cargo!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                client.cargo!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 10),

            // Documento (CNPJ / CPF)
            Row(
              children: [
                Icon(
                  client.isPj ? Icons.business_rounded : Icons.badge_outlined,
                  size: 14,
                  color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  client.documentoFormatado,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: isDark ? SigeColors.darkTextSecondary : SigeColors.lightTextSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Telefone Principal
            Row(
              children: [
                const Icon(
                  Icons.phone_rounded,
                  size: 14,
                  color: SigeColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  client.telefoneFormatado,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? SigeColors.darkTextPrimary : SigeColors.lightTextPrimary,
                  ),
                ),
                if (client.telefones.length > 1) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '+${client.telefones.length - 1}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Tags
            if (client.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: client.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),

            const Spacer(),
            const Divider(height: 16),

            // Métricas (LTV e Atendimentos) + Botões de Ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LTV Total',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? SigeColors.darkTextMuted : SigeColors.lightTextMuted,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(client.ltvTotal),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                      tooltip: 'Conversar no WhatsApp',
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: onQuickContact,
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      tooltip: 'Abrir Ficha 360°',
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.all(8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: onTapDetail,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
